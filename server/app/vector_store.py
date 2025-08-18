import os
import json
from typing import List, Dict, Any, Optional
import numpy as np
try:
    import hnswlib  # optional, used only in SQLite/local fallback
    HAS_HNSWLIB = True
except Exception:
    hnswlib = None
    HAS_HNSWLIB = False
from sentence_transformers import SentenceTransformer
from threading import Lock
from sqlalchemy import create_engine, text

_DATA_DIR = os.getenv('DATA_DIR', os.path.dirname(__file__))
_INDEX_PATH = os.path.join(_DATA_DIR, 'memory_hnsw.index')
_META_PATH = os.path.join(_DATA_DIR, 'memory_hnsw_meta.json')
_MODEL_NAME = os.getenv('EMBED_MODEL', 'moka-ai/m3e-small')

# Postgres / pgvector
_PG_DSN = os.getenv("POSTGRES_DSN")
_PG_HOST = os.getenv("POSTGRES_HOST")
_PG_PORT = os.getenv("POSTGRES_PORT", "5432")
_PG_DB = os.getenv("POSTGRES_DB")
_PG_USER = os.getenv("POSTGRES_USER")
_PG_PASSWORD = os.getenv("POSTGRES_PASSWORD")
_ENGINE = None


def _use_pg() -> bool:
    return bool(_PG_DSN or (_PG_HOST and _PG_DB and _PG_USER and _PG_PASSWORD))


def _get_engine():
    global _ENGINE
    if _ENGINE is not None:
        return _ENGINE
    if _PG_DSN:
        dsn = _PG_DSN
    else:
        dsn = f"postgresql+psycopg://{_PG_USER}:{_PG_PASSWORD}@{_PG_HOST}:{_PG_PORT}/{_PG_DB}"
    _ENGINE = create_engine(dsn, pool_pre_ping=True)
    return _ENGINE

_lock = Lock()
_model: Optional[SentenceTransformer] = None
_index: Optional["hnswlib.Index"] = None
_dim: Optional[int] = None
_next_id: int = 0
_id_to_meta: Dict[int, Dict[str, Any]] = {}


def _load_model():
    global _model, _dim
    if _model is None:
        _model = SentenceTransformer(_MODEL_NAME)
        _dim = _model.get_sentence_embedding_dimension()


def _ensure_index():
    global _index, _next_id, _id_to_meta
    if _index is not None:
        return
    _load_model()
    if _use_pg():
        # Ensure pgvector extension and table
        eng = _get_engine()
        with eng.begin() as conn:
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            # ensure model loaded to know dimension
            dim = int(_dim or 768)
            ddl = f"""
                CREATE TABLE IF NOT EXISTS memory_vectors (
                    id BIGSERIAL PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    type TEXT,
                    text TEXT,
                    timestamp TEXT,
                    embedding vector({dim})
                );
                CREATE INDEX IF NOT EXISTS idx_memory_vectors_user ON memory_vectors(user_id);
            """
            conn.execute(text(ddl))
            # Track next_id via max(id)
            res = conn.execute(text("SELECT COALESCE(MAX(id), 0) FROM memory_vectors"))
            _next_id = int(res.scalar() or 0)
        # No local HNSW index when using pgvector
        _index = None
        return
    # Fallback to local HNSW
    ef_construction = 200
    M = 48
    if not HAS_HNSWLIB:
        raise RuntimeError("hnswlib not available and Postgres not configured; please enable Postgres or install hnswlib")
    index = hnswlib.Index(space='cosine', dim=_dim)
    if os.path.exists(_INDEX_PATH) and os.path.exists(_META_PATH):
        index.load_index(_INDEX_PATH)
        with open(_META_PATH, 'r', encoding='utf-8') as f:
            meta = json.load(f)
            _next_id = meta.get('next_id', 0)
            _id_to_meta = {int(k): v for k, v in meta.get('id_to_meta', {}).items()}
    else:
        index.init_index(max_elements=200000, ef_construction=ef_construction, M=M)
        index.set_ef(64)
        _next_id = 0
        _id_to_meta = {}
    _index = index


def _persist():
    if _use_pg():
        return  # pgvector is persisted in DB
    _index.save_index(_INDEX_PATH)
    with open(_META_PATH, 'w', encoding='utf-8') as f:
        json.dump({'next_id': _next_id, 'id_to_meta': _id_to_meta}, f)


def add_texts(texts: List[str], metas: List[Dict[str, Any]]):
    """Add texts with metas to vector index (pgvector or local HNSW fallback)."""
    with _lock:
        _ensure_index()
        embs = _model.encode(texts, normalize_embeddings=True)
        global _next_id, _id_to_meta
        if _use_pg():
            eng = _get_engine()
            with eng.begin() as conn:
                for emb, meta in zip(embs, metas):
                    # meta 应包含 user_id, type, text, timestamp
                    # 将向量转换为 pgvector 文本字面量，避免适配器依赖
                    emb_str = "[" + ",".join(str(float(x)) for x in emb.tolist()) + "]"
                    conn.execute(text(
                        """
                        INSERT INTO memory_vectors(user_id, type, text, timestamp, embedding)
                        VALUES (:user_id, :type, :text, :timestamp, :embedding::vector)
                        """
                    ), {
                        "user_id": meta.get("user_id"),
                        "type": meta.get("type"),
                        "text": meta.get("text"),
                        "timestamp": meta.get("timestamp"),
                        "embedding": emb_str
                    })
            # 更新 next_id（可选）
            with eng.begin() as conn:
                res = conn.execute(text("SELECT COALESCE(MAX(id), 0) FROM memory_vectors"))
                _next_id = int(res.scalar() or 0)
            return
        # HNSW 本地索引路径
        ids = np.arange(_next_id, _next_id + len(texts))
        _index.add_items(embs, ids)
        for i, meta in zip(ids.tolist(), metas):
            _id_to_meta[int(i)] = meta
        _next_id += len(texts)
        _persist()


def query(text: str, top_k: int = 5, filters: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
    with _lock:
        _ensure_index()
        emb = _model.encode([text], normalize_embeddings=True)[0]
        if _use_pg():
            eng = _get_engine()
            where = []
            params: Dict[str, Any] = {"emb": list(map(float, emb.tolist())), "k": int(top_k)}
            if filters:
                if filters.get("user_id"):
                    where.append("user_id = :uid")
                    params["uid"] = filters["user_id"]
                # 可按需扩展更多过滤
            where_sql = ("WHERE " + " AND ".join(where)) if where else ""
            sql = (
                "SELECT user_id, type, text, timestamp, 1 - (embedding <=> (:emb::vector)) AS score "
                "FROM memory_vectors "
                f"{where_sql} "
                "ORDER BY embedding <=> (:emb::vector) ASC "
                "LIMIT :k"
            )
            with eng.begin() as conn:
                rows = conn.execute(text(sql), params).mappings().all()
            results: List[Dict[str, Any]] = []
            for r in rows:
                results.append({
                    "user_id": r["user_id"],
                    "type": r.get("type"),
                    "text": r.get("text"),
                    "timestamp": r.get("timestamp"),
                    "score": float(r.get("score") or 0.0),
                })
            return results
        # 本地 HNSW 检索
        labels, distances = _index.knn_query([emb], k=top_k)
        results: List[Dict[str, Any]] = []
        for lab, dist in zip(labels[0], distances[0]):
            meta = _id_to_meta.get(int(lab))
            if meta is None:
                continue
            if filters and any(meta.get(k) != v for k, v in filters.items()):
                continue
            results.append({**meta, 'score': float(1 - dist)})
        return results

