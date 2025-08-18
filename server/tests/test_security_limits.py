import os, sys
from datetime import datetime
CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)


def test_chat_message_length_limit():
    user_id = 'lim_user'
    too_long = 'a' * 2100
    r = client.post('/chat/reply', json={
        'user_id': user_id,
        'messages': [{"role": "user", "content": too_long}],
        'top_k_memories': 1
    })
    assert r.status_code == 422  # validation error


def test_memory_text_length_limit():
    long_text = 'b' * 2100
    r = client.post('/memory/upsert', json={
        'events': [{
            'user_id': 'muser',
            'type': 'chat',
            'text': long_text,
            'metadata': {},
            'timestamp': datetime.now().isoformat(timespec='minutes')
        }]
    })
    # Either 422 pydantic error or 200 from fallback; prefer validation 422
    assert r.status_code == 422


def test_feedback_validation():
    # invalid type
    r1 = client.post('/feedback', json={'user_id': 'u', 'feedback_type': 'bad_type'})
    assert r1.status_code == 422
    # long comment
    r2 = client.post('/feedback', json={'user_id': 'u', 'feedback_type': 'like', 'comment': 'x'*600})
    assert r2.status_code == 422
    # score out of range
    r3 = client.post('/feedback', json={'user_id': 'u', 'feedback_type': 'like', 'score': 2.0})
    assert r3.status_code == 422

