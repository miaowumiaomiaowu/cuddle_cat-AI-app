import os
import json
from typing import List, Dict, Optional
from fastapi import FastAPI, Body
from pydantic import BaseModel
import httpx
from dotenv import load_dotenv
from pathlib import Path

# Load .env from project root
_ENV_PATH = Path(__file__).resolve().parents[1] / '.env'
load_dotenv(dotenv_path=_ENV_PATH, override=False)

app = FastAPI(title="CuddleCat AI Backend", version="0.1.0")

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")
DEEPSEEK_API_ENDPOINT = os.getenv("DEEPSEEK_API_ENDPOINT", "https://api.deepseek.com/v1/chat/completions")
DEEPSEEK_MODEL = os.getenv("DEEPSEEK_MODEL", "deepseek-chat")
DEEPSEEK_TIMEOUT = int(os.getenv("DEEPSEEK_TIMEOUT", "8"))  # seconds; keep < client timeout (12s)

class RecommendRequest(BaseModel):
    recentMessages: List[str] = []
    moodRecords: List[Dict] = []
    stats: Dict = {}
    weather: Optional[Dict] = None

class Gift(BaseModel):
    title: str
    emoji: Optional[str] = "🎁"
    category: Optional[str] = "gift"
    description: Optional[str] = ""
    reason: Optional[str] = None
    estimatedMinutes: Optional[int] = None

class RecommendResponse(BaseModel):
    emotions: List[str] = []
    scores: Dict[str, float] = {}
    gifts: List[Gift] = []

@app.get("/health")
async def health():
    provider = None
    model = None
    version = os.getenv("SERVER_VERSION", "0.1.0")
    if DEEPSEEK_API_KEY:
        provider = "deepseek"
        model = DEEPSEEK_MODEL
    return {
        "ok": True,
        "provider": provider,
        "model": model,
        "version": version,
    }

# --- Simple rule-based fallback ---

def _rule_based(signals: RecommendRequest) -> RecommendResponse:
    gifts: List[Gift] = []
    emotions: List[str] = []
    scores: Dict[str, float] = {}

    # naive emotions from latest mood record
    if signals.moodRecords:
        latest = signals.moodRecords[0]
        mood: str = str(latest.get("mood", "neutral"))
        emotions.append(mood)
        scores[mood] = 0.7
        scores["calm"] = 0.3

    # build a few friendly gifts
    gifts.append(Gift(title="去楼下散步", emoji="🚶‍♀️", category="运动", description="轻松走10分钟，看看天空", estimatedMinutes=10, reason="放松身心"))
    gifts.append(Gift(title="热饮时间", emoji="☕", category="放松", description="冲一杯热饮，慢慢喝", estimatedMinutes=5, reason="舒缓情绪"))
    gifts.append(Gift(title="呼吸练习 4-7-8", emoji="🌬️", category="呼吸", description="吸4秒-憋7秒-呼8秒×3", estimatedMinutes=4, reason="减缓焦虑"))

    return RecommendResponse(emotions=emotions, scores=scores, gifts=gifts)

async def _deepseek_call(signals: RecommendRequest) -> Optional[RecommendResponse]:
    if not DEEPSEEK_API_KEY:
        return None

    system_prompt = (
        "You are an empathetic wellbeing assistant. Given user's recent messages, mood records, and stats, "
        "produce a concise JSON with keys: emotions (array of strings), scores (object of key->float), "
        "gifts (array of {title,emoji,category,description,reason,estimatedMinutes}). Respond ONLY valid JSON."
    )
    user_payload = {
        "recentMessages": signals.recentMessages[-10:],
        "moodRecords": signals.moodRecords[:10],
        "stats": signals.stats,
        "weather": signals.weather,
    }

    headers = {
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
        "Content-Type": "application/json",
    }
    body = {
        "model": DEEPSEEK_MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": json.dumps(user_payload, ensure_ascii=False)}
        ],
        "temperature": 0.3,
    }

    try:
        # keep provider call timeout shorter than client timeout (12s)
        async with httpx.AsyncClient(timeout=DEEPSEEK_TIMEOUT) as client:
            r = await client.post(DEEPSEEK_API_ENDPOINT, headers=headers, json=body)
            r.raise_for_status()
            data = r.json()
            content = data["choices"][0]["message"]["content"]
            # try parse as JSON
            content = content.strip()
            # remove code fences if any
            if content.startswith("```"):
                content = content.strip("`\n ")
                if content.lower().startswith("json"):
                    content = content[4:].strip()
            parsed = json.loads(content)
            # map to response
            resp = RecommendResponse(
                emotions=list(parsed.get("emotions", [])),
                scores={k: float(v) for k, v in parsed.get("scores", {}).items()},
                gifts=[Gift(**g) for g in parsed.get("gifts", [])],
            )
            return resp
    except Exception:
        return None

@app.post("/recommend/gifts", response_model=RecommendResponse)
async def recommend(signals: RecommendRequest = Body(...)):
    # try deepseek first
    resp = await _deepseek_call(signals)
    if resp is not None and len(resp.gifts) > 0:
        return resp
    # fallback
    return _rule_based(signals)

@app.post("/feedback")
async def feedback(payload: Dict = Body(...)):
    # accept and ignore for now
    return {"ok": True}

# Entry: uvicorn server
# uvicorn server.app:app --host 0.0.0.0 --port 8002 --reload

