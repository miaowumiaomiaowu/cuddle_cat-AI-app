import os
import sys
from datetime import datetime, timedelta

# Ensure server/ is on sys.path
CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)


def _iso_minute(dt):
    return dt.isoformat(timespec="minutes")


def test_memory_query_no_query_returns_recent():
    user_id = "test_user_mem_recent"
    now = datetime.now()
    events = [
        {
            "user_id": user_id,
            "type": "chat",
            "text": f"条目{i}",
            "metadata": {},
            "timestamp": _iso_minute(now - timedelta(minutes=15 * i)),
        }
        for i in range(3)
    ]
    r = client.post("/memory/upsert", json={"events": events})
    assert r.status_code == 200 and r.json().get("status") == "success"

    q = client.post("/memory/query", json={"user_id": user_id, "top_k": 2})
    assert q.status_code == 200
    data = q.json()
    assert data.get("status") == "success"
    assert isinstance(data.get("data"), list)


def test_memory_query_with_keyword_filters():
    user_id = "test_user_mem_kw"
    payload = {
        "events": [
            {"user_id": user_id, "type": "chat", "text": "今天想散步", "metadata": {}, "timestamp": _iso_minute(datetime.now())},
            {"user_id": user_id, "type": "chat", "text": "打算做饭", "metadata": {}, "timestamp": _iso_minute(datetime.now())},
        ]
    }
    r = client.post("/memory/upsert", json=payload)
    assert r.status_code == 200 and r.json().get("status") == "success"

    q = client.post("/memory/query", json={"user_id": user_id, "query": "散步", "top_k": 5})
    assert q.status_code == 200
    data = q.json()
    assert data.get("status") == "success"
    items = data.get("data", [])
    assert all(isinstance(it, dict) for it in items)
    if items:
        assert any("散步" in it.get("text", "") for it in items)


def test_memory_query_topk_boundary():
    user_id = "test_user_mem_topk"
    payload = {
        "events": [
            {"user_id": user_id, "type": "chat", "text": f"text {i}", "metadata": {}, "timestamp": _iso_minute(datetime.now())}
            for i in range(5)
        ]
    }
    r = client.post("/memory/upsert", json=payload)
    assert r.status_code == 200 and r.json().get("status") == "success"

    q = client.post("/memory/query", json={"user_id": user_id, "top_k": 1})
    assert q.status_code == 200
    data = q.json()
    assert data.get("status") == "success"
    items = data.get("data", [])
    assert isinstance(items, list)
    assert len(items) <= 1




def test_memory_query_unmatched_keyword_returns_empty():
    user_id = "test_user_mem_unmatched"
    payload = {
        "events": [
            {"user_id": user_id, "type": "chat", "text": "今天做饭", "metadata": {}, "timestamp": _iso_minute(datetime.now())},
            {"user_id": user_id, "type": "chat", "text": "准备看书", "metadata": {}, "timestamp": _iso_minute(datetime.now())},
        ]
    }
    r = client.post("/memory/upsert", json=payload)
    assert r.status_code == 200 and r.json().get("status") == "success"

    q = client.post("/memory/query", json={"user_id": user_id, "query": "散步", "top_k": 5})
    assert q.status_code == 200
    data = q.json()
    assert data.get("status") == "success"
    items = data.get("data", [])
    assert isinstance(items, list)
    assert len(items) == 0


def test_memory_query_invalid_user_returns_empty():
    user_id = "test_user_mem_nonexistent"
    q = client.post("/memory/query", json={"user_id": user_id, "query": "任意", "top_k": 3})
    assert q.status_code == 200
    data = q.json()
    assert data.get("status") == "success"
    assert data.get("data") == []
