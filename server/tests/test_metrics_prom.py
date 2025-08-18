import os, sys
CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)

def test_metrics_prom_text():
    r = client.get('/metrics_prom')
    assert r.status_code == 200
    body = r.text
    assert 'cuddle_uptime_seconds' in body

