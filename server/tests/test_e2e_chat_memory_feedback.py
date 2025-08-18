import os, sys
from datetime import datetime
CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)


def test_e2e_chat_memory_feedback_metrics():
    user_id = 'e2e_user_1'

    # Upsert memory
    r = client.post('/memory/upsert', json={
        'events': [
            {"user_id": user_id, "type": "chat", "text": "最爱周末早晨喝咖啡散步", "metadata": {}, "timestamp": datetime.now().isoformat(timespec='minutes')}
        ]
    })
    assert r.status_code == 200

    # Chat
    req = {
        'user_id': user_id,
        'messages': [{"role": "user", "content": "这个周末想安排下放松时间"}],
        'top_k_memories': 3
    }
    q = client.post('/chat/reply', json=req)
    assert q.status_code == 200
    data = q.json()
    assert data.get('status') == 'success'

    # Feedback
    fb = client.post('/feedback', json={
        'user_id': user_id,
        'feedback_type': 'like',
        'target_type': 'chat',
        'target_id': 'dummy',
        'score': 1.0,
        'comment': '不错，挺放松'
    })
    assert fb.status_code == 200

    # Metrics
    m = client.get('/metrics')
    assert m.status_code == 200
    md = m.json()['data']
    cnt = md['counters']
    assert cnt.get('chat_reply_requests', 0) >= 1
    assert cnt.get('feedback_total', 0) >= 1
    # latency sanity
    avg = md.get('latency_ms_avg')
    p95 = md.get('latency_ms_p95')
    assert avg is None or avg >= 0
    assert p95 is None or p95 >= 0

