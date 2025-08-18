import os, sys
CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)

def test_feedback_metrics_increment():
    user = 'metrics_fb_user'
    payload = {"user_id": user, "feedback_type": "like"}
    r = client.post('/feedback', json=payload)
    assert r.status_code == 200

    m = client.get('/metrics')
    assert m.status_code == 200
    counters = m.json()['data']['counters']
    assert counters.get('feedback_total', 0) >= 1
    assert counters.get('feedback_type_like', 0) >= 1

