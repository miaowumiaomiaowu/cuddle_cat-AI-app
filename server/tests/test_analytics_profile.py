import os
import sys
from datetime import datetime

CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)


def _iso_minute(dt):
    return dt.isoformat(timespec="minutes")


def test_profile_basic_fields_present():
    user_id = "test_profile_user"
    # 写入一些基础事件
    events = {
        "events": [
            {"user_id": user_id, "type": "chat", "text": "今天很开心，想散步", "metadata": {}, "timestamp": _iso_minute(datetime.now())},
            {"user_id": user_id, "type": "task", "text": "完成打卡：喝水", "metadata": {}, "timestamp": _iso_minute(datetime.now())},
            {"user_id": user_id, "type": "chat", "text": "有点焦虑，想做深呼吸", "metadata": {}, "timestamp": _iso_minute(datetime.now())},
        ]
    }
    r = client.post("/memory/upsert", json=events)
    assert r.status_code == 200 and r.json().get("status") == "success"

    q = client.get(f"/analytics/profile/{user_id}")
    assert q.status_code == 200
    data = q.json()
    assert data.get("status") == "success"
    prof = data.get("data", {})
    assert prof.get("user_id") == user_id
    assert isinstance(prof.get("category_weights"), dict)
    assert isinstance(prof.get("time_preferences"), list) and len(prof.get("time_preferences")) == 24
    assert isinstance(prof.get("emotion_trend"), list)
    assert isinstance(prof.get("engagement"), int)
    assert isinstance(prof.get("completion_rate"), float)




def test_profile_contains_top_categories_and_active_hours():
    user_id = "test_profile_user2"
    # 制造不同类别与不同时段
    from datetime import timedelta
    now = datetime.now()
    events = {"events": []}
    # 三个类别：chat, task, mood
    for i in range(3):
        events["events"].append({"user_id": user_id, "type": "chat", "text": f"聊天{i}", "metadata": {}, "timestamp": _iso_minute(now - timedelta(hours=1))})
    for i in range(2):
        events["events"].append({"user_id": user_id, "type": "task", "text": f"任务{i}", "metadata": {}, "timestamp": _iso_minute(now - timedelta(hours=2))})
    events["events"].append({"user_id": user_id, "type": "mood", "text": "开心", "metadata": {}, "timestamp": _iso_minute(now - timedelta(hours=3))})

    r = client.post("/memory/upsert", json=events)
    assert r.status_code == 200 and r.json().get("status") == "success"

    q = client.get(f"/analytics/profile/{user_id}")
    assert q.status_code == 200
    data = q.json()
    assert data.get("status") == "success"
    prof = data.get("data", {})
    assert isinstance(prof.get("top_categories"), list) and len(prof.get("top_categories")) >= 1
    assert isinstance(prof.get("active_hours"), list) and len(prof.get("active_hours")) >= 1
