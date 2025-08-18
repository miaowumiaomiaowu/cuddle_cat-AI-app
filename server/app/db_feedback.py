import os
import sqlite3
from typing import Dict, Any, List
from threading import Lock
from sqlalchemy import create_engine, text

_DB_LOCK = Lock()
_DATA_DIR = os.getenv("DATA_DIR", os.path.dirname(__file__))
_DB_PATH = os.path.join(_DATA_DIR, 'memory.db')

# Postgres support (reuse same env as db.py)
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
        raise RuntimeError("_connect() should not be used when Postgres is enabled")
    conn = sqlite3.connect(_DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def ensure_feedback_table():
    with _DB_LOCK:
        if _use_pg():
            eng = _get_engine()
            with eng.begin() as conn:
                conn.execute(text(
                    """
                    CREATE TABLE IF NOT EXISTS user_feedback (
                        id SERIAL PRIMARY KEY,
                        user_id TEXT NOT NULL,
                        target_type TEXT,
                        target_id TEXT,
                        feedback_type TEXT NOT NULL,
                        score DOUBLE PRECISION,
                        comment TEXT,
                        timestamp TEXT
                    );
                    CREATE INDEX IF NOT EXISTS idx_feedback_user ON user_feedback(user_id);
                    """
                ))
            return
        conn = _connect()
        try:
            cur = conn.cursor()
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS user_feedback (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    target_type TEXT,
                    target_id TEXT,
                    feedback_type TEXT NOT NULL,
                    score REAL,
                    comment TEXT,
                    timestamp TEXT
                )
                """
            )
            cur.execute("CREATE INDEX IF NOT EXISTS idx_feedback_user ON user_feedback(user_id)")
            conn.commit()
        finally:
            conn.close()


def insert_feedback(ev: Dict[str, Any]) -> int:
    with _DB_LOCK:
        if _use_pg():
            eng = _get_engine()
            with eng.begin() as conn:
                res = conn.execute(text(
                    """
                    INSERT INTO user_feedback(user_id, target_type, target_id, feedback_type, score, comment, timestamp)
                    VALUES (:user_id, :target_type, :target_id, :feedback_type, :score, :comment, :timestamp)
                    """
                ), ev)
                return res.rowcount or 0
        conn = _connect()
        try:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO user_feedback(user_id, target_type, target_id, feedback_type, score, comment, timestamp) VALUES(?,?,?,?,?,?,?)",
                (
                    ev.get('user_id'),
                    ev.get('target_type'),
                    ev.get('target_id'),
                    ev.get('feedback_type'),
                    ev.get('score'),
                    ev.get('comment'),
                    ev.get('timestamp'),
                )
            )
            conn.commit()
            return cur.rowcount or 0
        finally:
            conn.close()


def fetch_feedback_stats(user_id: str) -> Dict[str, Any]:
    with _DB_LOCK:
        if _use_pg():
            eng = _get_engine()
            with eng.begin() as conn:
                rows = conn.execute(text(
                    "SELECT feedback_type, COUNT(1) as cnt FROM user_feedback WHERE user_id=:uid GROUP BY feedback_type"
                ), {"uid": user_id}).all()
            counts = {row[0]: int(row[1]) for row in rows}
            return {"counts": counts}
        conn = _connect()
        try:
            cur = conn.cursor()
            cur.execute(
                "SELECT feedback_type, COUNT(1) as cnt FROM user_feedback WHERE user_id=? GROUP BY feedback_type",
                (user_id,)
            )
            rows = cur.fetchall()
            counts = {row[0]: int(row[1]) for row in rows}
            return {"counts": counts}
        finally:
            conn.close()

