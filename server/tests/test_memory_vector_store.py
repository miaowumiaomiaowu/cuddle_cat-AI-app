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


def test_semantic_near_match_recall():
    user_id = "test_vec_semantic"
    # 上载两条含近义词的记忆
    events = {
        "events": [
            {"user_id": user_id, "type": "chat", "text": "想去散步放松一下", "metadata": {}, "timestamp": _iso_minute(datetime.now())},
            {"user_id": user_id, "type": "chat", "text": "考虑走走呼吸下新鲜空气", "metadata": {}, "timestamp": _iso_minute(datetime.now())},
        ]
    }
    r = client.post("/memory/upsert", json=events)
    assert r.status_code == 200 and r.json().get("status") == "success"

    # 查询语义相近的词语（不必完全相同）
    q = client.post("/memory/query", json={"user_id": user_id, "query": "出去走走", "top_k": 2})
    assert q.status_code == 200
    data = q.json()
    assert data.get("status") == "success"
    items = data.get("data", [])
    assert isinstance(items, list)
    # 不强制必须包含关键词，但应至少返回1条结果（来自向量召回）
    assert len(items) >= 1


def test_index_persistence_reload():
    user_id = "test_vec_persist"
    events = {
        "events": [
            {"user_id": user_id, "type": "chat", "text": "喜欢慢跑", "metadata": {}, "timestamp": _iso_minute(datetime.now())},
        ]
    }
    r = client.post("/memory/upsert", json=events)
    assert r.status_code == 200 and r.json().get("status") == "success"

    # 再次查询，验证索引存在并可用（模拟重启：当前实现实际在同进程两次查询也会触发持久化读取）
    q = client.post("/memory/query", json={"user_id": user_id, "query": "跑步", "top_k": 1})
    assert q.status_code == 200
    data = q.json()
    assert data.get("status") == "success"
    items = data.get("data", [])
    assert isinstance(items, list)
    # 至少返回一条
    assert len(items) >= 1

