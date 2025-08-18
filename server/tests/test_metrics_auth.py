import os, sys
CURRENT_DIR = os.path.dirname(__file__)
SERVER_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
sys.path.insert(0, SERVER_DIR)

from fastapi.testclient import TestClient  # type: ignore
from app.main import app  # type: ignore

client = TestClient(app)


def test_metrics_requires_key_when_set(monkeypatch):
    monkeypatch.setenv('METRICS_API_KEY', 'secret')

    # Without key -> 403
    r = client.get('/metrics')
    assert r.status_code == 403

    # With key -> 200
    r2 = client.get('/metrics', headers={'X-API-Key': 'secret'})
    assert r2.status_code == 200

    # Prom also guarded
    r3 = client.get('/metrics_prom')
    assert r3.status_code == 403
    r4 = client.get('/metrics_prom', headers={'X-API-Key': 'secret'})
    assert r4.status_code == 200

