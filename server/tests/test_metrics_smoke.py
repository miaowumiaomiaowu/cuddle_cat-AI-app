import os, sys
CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)

def test_metrics_increments():
    # call chat reply once
    r1 = client.post('/chat/reply', json={
        'user_id': 'metrics_user',
        'messages': [{'role':'user','content':'hello metrics'}],
        'top_k_memories': 1
    })
    assert r1.status_code == 200

    m = client.get('/metrics')
    assert m.status_code == 200
    data = m.json().get('data', {})
    counters = data.get('counters', {})
    assert counters.get('chat_reply_requests', 0) >= 1
    # total retrieval should be counted at least once
    assert counters.get('mem_retrieval_total', 0) >= 1

