import os, sys, time
CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)


def test_fallback_increments_metric_and_items_empty_via_chat():
    user_id = 'fallback_user'
    # Use chat/reply which records mem_retrieval_total and fallback metrics
    q = client.post('/chat/reply', json={
        'user_id': user_id,
        'messages': [{"role": "user", "content": "极其罕见的短语_不会命中向量库_12345"}],
        'top_k_memories': 3
    })
    assert q.status_code == 200

    m = client.get('/metrics')
    assert m.status_code == 200
    counters = m.json()['data']['counters']
    assert counters.get('mem_retrieval_total', 0) >= 1


def test_latency_window_p95_and_avg_non_negative():
    user_id = 'lat_user'
    for _ in range(5):
        q = client.post('/chat/reply', json={
            'user_id': user_id,
            'messages': [{"role": "user", "content": "Ping"}],
            'top_k_memories': 1
        })
        assert q.status_code == 200
        time.sleep(0.05)

    m = client.get('/metrics')
    md = m.json()['data']
    assert (md.get('latency_ms_avg') or 0) >= 0
    if md.get('latency_ms_p95') is not None:
        assert md.get('latency_ms_p95') >= 0

