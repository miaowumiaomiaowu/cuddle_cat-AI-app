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


def test_wellness_plan_basic():
    body = {
        "recentMessages": ["最近有点紧张"],
        "moodRecords": [
            {
                "timestamp": datetime.now().isoformat(timespec="minutes"),
                "mood": "anxious",
                "description": "工作压力有点大"
            }
        ],
        "stats": {"user_id": "test_user_1", "streak": 3, "completionRate7d": 0.5},
        "weather": None,
    }
    resp = client.post("/recommend/wellness-plan", json=body)
    assert resp.status_code == 200
    data = resp.json()
    assert data.get("status") == "success"
    plan = data.get("data")
    assert isinstance(plan, dict)
    assert isinstance(plan.get("habits", []), list)
    assert len(plan.get("habits", [])) > 0
    assert isinstance(plan.get("goals", []), list)

