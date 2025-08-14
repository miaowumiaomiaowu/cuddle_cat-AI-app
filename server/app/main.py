from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict, Optional

app = FastAPI(title="Cuddle Cat AI Analysis Service")

class MoodRecord(BaseModel):
    timestamp: str
    mood: str
    description: Optional[str] = None

class RecommendRequest(BaseModel):
    recentMessages: List[str] = []
    moodRecords: List[MoodRecord] = []
    stats: Dict[str, float] = {}

class Gift(BaseModel):
    title: str
    emoji: str = "🎁"
    category: str = "gift"
    description: str = ""
    estimatedMinutes: Optional[int] = None

class RecommendResponse(BaseModel):
    emotions: List[str] = []
    scores: Dict[str, float] = {}
    gifts: List[Gift] = []

@app.post("/recommend/gifts", response_model=RecommendResponse)
async def recommend_gifts(req: RecommendRequest):
    # Minimal rule-based draft; replace with model calls
    base = [
        Gift(title="去楼下散步", emoji="🚶‍♀️", category="运动", description="轻松走10分钟，看看天空", estimatedMinutes=10),
        Gift(title="给自己冲一杯热饮", emoji="☕", category="放松", description="慢慢喝，感受温度", estimatedMinutes=5),
        Gift(title="深呼吸小练习", emoji="🌬️", category="呼吸", description="2-4-6-4节奏×3组", estimatedMinutes=4),
    ]
    # Very naive mood-based tweak
    emotes = ["calm"]
    scores = {"calm": 0.7}
    if any("焦虑" in (m.description or "") for m in req.moodRecords):
        emotes = ["anxious"]
        scores = {"anxious": 0.8}
    return RecommendResponse(emotions=emotes, scores=scores, gifts=base)

@app.get("/")
async def root():
    return {"status": "ok"}

