# Cuddle Cat AI Analysis Service (FastAPI)

FastAPI backend for chat replies, wellness/gift recommendations, memories, feedback, analytics and metrics.

## Endpoints (current)
- GET /health
- POST /chat/reply
- POST /recommend/gifts
- POST /recommend/wellness-plan
- POST /memory/upsert
- POST /memory/query
- POST /feedback (JSON payload)
- GET  /feedback/stats/{user_id}
- GET  /analytics/stats
- POST /analytics/predict-mood
- POST /analytics/emotion-advanced
- GET  /metrics (requires X-API-Key if METRICS_API_KEY is set)
- GET  /metrics_prom (Prometheus format; requires X-API-Key if METRICS_API_KEY is set)

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

