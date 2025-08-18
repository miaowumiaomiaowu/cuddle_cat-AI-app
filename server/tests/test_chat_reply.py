import os
import sys
from datetime import datetime

CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)


def test_chat_reply_minimum_flow():
    user_id = "test_chat_reply"
    # 先写入一条记忆
    r = client.post("/memory/upsert", json={
        "events": [
            {"user_id": user_id, "type": "chat", "text": "我喜欢晚饭后散步", "metadata": {}, "timestamp": datetime.now().isoformat(timespec='minutes')}
        ]
    })
    assert r.status_code == 200 and r.json().get("status") == "success"

    # 发起聊天
    req = {
        "user_id": user_id,
        "messages": [
            {"role": "user", "content": "今天晚饭后有点累，想放松一下"}
        ],
        "top_k_memories": 3
    }
    q = client.post("/chat/reply", json=req)
    assert q.status_code == 200
    data = q.json()
    assert data.get("status") == "success"
    d = data.get("data", {})
    assert isinstance(d.get("text"), str) and len(d.get("text")) > 0
    # used_memories 可能为空（取决于阈值），但一般应返回列表
    assert isinstance(d.get("used_memories"), list)
    assert isinstance(d.get("profile"), dict)

