import os
import sys
from datetime import datetime

CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)


def test_feedback_post_and_stats():
    user_id = "test_feedback_user"
    now = datetime.now().isoformat(timespec='minutes')
    payloads = [
        {"user_id": user_id, "feedback_type": "like", "target_type": "chat", "target_id": "r1", "score": 1.0, "comment": "不错", "timestamp": now},
        {"user_id": user_id, "feedback_type": "useful", "target_type": "chat", "target_id": "r2", "score": 0.8, "comment": "有帮助", "timestamp": now},
        {"user_id": user_id, "feedback_type": "complete", "target_type": "habit", "target_id": "h1", "score": 1.0, "comment": "已完成", "timestamp": now},
    ]

    for p in payloads:
        r = client.post("/feedback", json=p)
        assert r.status_code == 200
        assert r.json().get("status") == "success"

    s = client.get(f"/feedback/stats/{user_id}")
    assert s.status_code == 200
    j = s.json()
    assert j.get("status") == "success"
    counts = j.get("data", {}).get("counts", {})
    assert counts.get("like", 0) >= 1
    assert counts.get("useful", 0) >= 1
    assert counts.get("complete", 0) >= 1

