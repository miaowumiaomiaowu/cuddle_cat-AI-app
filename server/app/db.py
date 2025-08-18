import os
import json
import sqlite3
from typing import List, Optional, Dict, Any
from threading import Lock
from datetime import datetime, timedelta
from sqlalchemy import create_engine, text
import time

_DB_LOCK = Lock()
_DATA_DIR = os.getenv("DATA_DIR", os.path.dirname(__file__))
_DB_PATH = os.path.join(_DATA_DIR, 'memory.db')

# Postgres support
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


def _connect():
    if _use_pg():
        # SQLAlchemy engine will be used elsewhere; keep this for SQLite fallback
        raise RuntimeError("_connect() should not be used when Postgres is enabled")
    conn = sqlite3.connect(_DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    with _DB_LOCK:
        if _use_pg():
            eng = _get_engine()
            with eng.begin() as conn:
                conn.execute(text(
                    """
                    CREATE TABLE IF NOT EXISTS memory_events (
                        id SERIAL PRIMARY KEY,
                        user_id TEXT NOT NULL,
                        type TEXT,
                        text TEXT,
                        metadata TEXT,
                        timestamp TEXT
                    );
                    CREATE INDEX IF NOT EXISTS idx_memory_user_ts ON memory_events(user_id, timestamp DESC);
                    """
                ))
            return
        # SQLite fallback
        conn = _connect()
        try:
            cur = conn.cursor()
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS memory_events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    type TEXT,
                    text TEXT,
                    metadata TEXT,
                    timestamp TEXT
                )
                """
            )
            cur.execute("CREATE INDEX IF NOT EXISTS idx_memory_user_ts ON memory_events(user_id, timestamp DESC)")
            conn.commit()
        finally:
            conn.close()


def upsert_events(events: List[Dict[str, Any]]) -> int:
    if not events:
        return 0
    with _DB_LOCK:
        if _use_pg():
            eng = _get_engine()
            total = 0
            with eng.begin() as conn:
                for ev in events:
                    user_id = ev.get("user_id")
                    if not user_id:
                        continue
                    res = conn.execute(text(
                        """
                        INSERT INTO memory_events(user_id, type, text, metadata, timestamp)
                        VALUES (:user_id, :type, :text, :metadata, :timestamp)
                        """
                    ), {
                        "user_id": user_id,
                        "type": ev.get("type"),
                        "text": ev.get("text"),
                        "metadata": json.dumps(ev.get("metadata") or {}),
                        "timestamp": ev.get("timestamp"),
                    })
                    total += res.rowcount or 0
            return total
        # SQLite fallback
        conn = _connect()
        try:
            cur = conn.cursor()
            for ev in events:
                user_id = ev.get("user_id")
                if not user_id:
                    continue
                cur.execute(
                    "INSERT INTO memory_events(user_id, type, text, metadata, timestamp) VALUES(?,?,?,?,?)",
                    (
                        user_id,
                        ev.get("type"),
                        ev.get("text"),
                        json.dumps(ev.get("metadata") or {}),
                        ev.get("timestamp"),
                    ),
                )
            conn.commit()
            return cur.rowcount or 0
        finally:
            conn.close()


def query_events(user_id: str, query: Optional[str], top_k: int) -> List[Dict[str, Any]]:
    if not user_id:
        return []
    with _DB_LOCK:
        if _use_pg():
            eng = _get_engine()
            sql = (
                "SELECT user_id, type, text, metadata, timestamp FROM memory_events WHERE user_id=:uid "
                + ("AND text ILIKE :q " if (query and query.strip()) else "")
                + "ORDER BY timestamp DESC LIMIT :limit"
            )
            params = {"uid": user_id, "limit": int(top_k)}
            if query and query.strip():
                params["q"] = f"%{query}%"
            with eng.begin() as conn:
                rows = conn.execute(text(sql), params).mappings().all()
            result: List[Dict[str, Any]] = []
            for r in rows:
                md = {}
                try:
                    if r.get("metadata"):
                        md = json.loads(r["metadata"]) or {}
                except Exception:
                    md = {}
                result.append({
                    "user_id": r["user_id"],
                    "type": r["type"],
                    "text": r["text"],
                    "metadata": md,
                    "timestamp": r["timestamp"],
                })
            return result
        # SQLite fallback
        conn = _connect()
        try:
            cur = conn.cursor()
            if query and query.strip():
                cur.execute(
                    "SELECT user_id, type, text, metadata, timestamp FROM memory_events WHERE user_id=? AND text LIKE ? ORDER BY timestamp DESC LIMIT ?",
                    (user_id, f"%{query}%", int(top_k)),
                )
            else:
                cur.execute(
                    "SELECT user_id, type, text, metadata, timestamp FROM memory_events WHERE user_id=? ORDER BY timestamp DESC LIMIT ?",
                    (user_id, int(top_k)),
                )
            rows = cur.fetchall()
            result: List[Dict[str, Any]] = []
            for r in rows:
                md = {}
                try:
                    if r["metadata"]:
                        md = json.loads(r["metadata"]) or {}
                except Exception:
                    md = {}
                result.append({
                    "user_id": r["user_id"],
                    "type": r["type"],
                    "text": r["text"],
                    "metadata": md,
                    "timestamp": r["timestamp"],
                })
            return result
        finally:
            conn.close()


def fetch_user_events(user_id: str, since_days: Optional[int] = None, limit: Optional[int] = None) -> List[Dict[str, Any]]:
    if not user_id:
        return []
    with _DB_LOCK:
        if _use_pg():
            eng = _get_engine()
            where = ["user_id = :uid"]
            params: Dict[str, Any] = {"uid": user_id}
            if since_days:
                cutoff = (datetime.now() - timedelta(days=since_days)).isoformat(timespec='minutes')
                where.append("timestamp >= :cutoff")
                params["cutoff"] = cutoff
            sql = "SELECT user_id, type, text, metadata, timestamp FROM memory_events WHERE " + " AND ".join(where) + " ORDER BY timestamp DESC"
            if limit:
                sql += " LIMIT :limit"
                params["limit"] = int(limit)
            with eng.begin() as conn:
                rows = conn.execute(text(sql), params).mappings().all()
            result: List[Dict[str, Any]] = []
            for r in rows:
                md = {}
                try:
                    if r.get("metadata"):
                        md = json.loads(r["metadata"]) or {}
                except Exception:
                    md = {}
                result.append({
                    "user_id": r["user_id"],
                    "type": r["type"],
                    "text": r["text"],
                    "metadata": md,
                    "timestamp": r["timestamp"],
                })
            return result
        # SQLite fallback
        conn = _connect()
        try:
            cur = conn.cursor()
            params: List[Any] = [user_id]
            where = "user_id=?"
            if since_days:
                cutoff = (datetime.now() - timedelta(days=since_days)).isoformat(timespec='minutes')
                where += " AND timestamp>=?"
                params.append(cutoff)
            sql = f"SELECT user_id, type, text, metadata, timestamp FROM memory_events WHERE {where} ORDER BY timestamp DESC"
            if limit:
                sql += " LIMIT ?"
                params.append(int(limit))
            cur.execute(sql, tuple(params))
            rows = cur.fetchall()
            result: List[Dict[str, Any]] = []
            for r in rows:
                md = {}
                try:
                    if r["metadata"]:
                        md = json.loads(r["metadata"]) or {}
                except Exception:
                    md = {}
                result.append({
                    "user_id": r["user_id"],
                    "type": r["type"],
                    "text": r["text"],
                    "metadata": md,
                    "timestamp": r["timestamp"],
                })
            return result
        finally:
            conn.close()

