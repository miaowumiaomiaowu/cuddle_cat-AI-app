# Cuddle Cat AI Analysis Service (FastAPI)

Minimal FastAPI skeleton for emotion/behavior analysis and gift recommendations.

## Endpoints
- POST /recommend/gifts
- (future) POST /analyze/emotion
- (future) POST /analyze/behavior

## Quickstart
```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

## Docker
```bash
docker build -t cuddlecat-ai-service .
docker run -p 8000:8000 cuddlecat-ai-service
```

