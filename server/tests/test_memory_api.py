import os
import sys
from datetime import datetime

# Ensure server/ is on sys.path
CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)


def test_memory_upsert_and_query_minimal():
    user_id = "mem_user_1"
    events = [
        {
            "user_id": user_id,
            "type": "chat",
            "text": "今天心情一般，走了10分钟",
            "metadata": {"mood": 3},
            "timestamp": datetime.now().isoformat(timespec="minutes"),
        }
    ]

    up = client.post("/memory/upsert", json={"events": events})
    assert up.status_code == 200
    assert up.json().get("status") == "success"

    q = client.post("/memory/query", json={"user_id": user_id, "query": "心情", "top_k": 5})
    assert q.status_code == 200
    data = q.json()
    assert data.get("status") == "success"
    assert isinstance(data.get("data", []), list)

