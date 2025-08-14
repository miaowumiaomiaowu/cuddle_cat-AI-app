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
    weather: Optional[Dict[str, any]] = None

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
    # Enhanced rule-based recommendations with weather and mood context
    gifts = []
    emotes = ["calm"]
    scores = {"calm": 0.7}

    # Weather-based recommendations
    weather_gifts = _get_weather_based_gifts(req.weather)
    gifts.extend(weather_gifts)

    # Mood-based analysis and gifts
    mood_analysis = _analyze_mood_patterns(req.moodRecords)
    mood_gifts = _get_mood_based_gifts(mood_analysis)
    gifts.extend(mood_gifts)

    # Message-based context gifts
    message_gifts = _get_message_based_gifts(req.recentMessages)
    gifts.extend(message_gifts)

    # Default base gifts if nothing specific found
    if not gifts:
        gifts = _get_default_gifts()

    # Deduplicate and limit to 8
    unique_gifts = _deduplicate_gifts(gifts)[:8]

    # Update emotions based on analysis
    if mood_analysis.get("dominant_mood") == "anxious":
        emotes = ["anxious"]
        scores = {"anxious": 0.8}
    elif mood_analysis.get("dominant_mood") == "happy":
        emotes = ["happy"]
        scores = {"happy": 0.9}

    return RecommendResponse(emotions=emotes, scores=scores, gifts=unique_gifts)

def _get_weather_based_gifts(weather: Optional[Dict]) -> List[Gift]:
    """Generate gifts based on weather conditions"""
    if not weather:
        return []

    gifts = []
    # Parse Open-Meteo weather data
    current = weather.get("current_weather", {})
    temp = current.get("temperature", 20)
    weather_code = current.get("weathercode", 0)

    # Weather code mapping (Open-Meteo codes)
    if weather_code in [61, 63, 65, 80, 81, 82]:  # Rain
        gifts.extend([
            Gift(title="在窗边听雨声", emoji="🌧️", category="放松", description="静静感受雨滴的节奏", estimatedMinutes=15),
            Gift(title="泡一壶温茶", emoji="🍵", category="温暖", description="让温暖从内心散发", estimatedMinutes=10),
            Gift(title="整理一个小角落", emoji="🏠", category="居家", description="为自己创造舒适空间", estimatedMinutes=20),
        ])
    elif weather_code in [0, 1]:  # Clear/Sunny
        gifts.extend([
            Gift(title="到阳台晒晒太阳", emoji="☀️", category="阳光", description="感受阳光的温暖拥抱", estimatedMinutes=10),
            Gift(title="去附近公园走走", emoji="🌳", category="户外", description="在自然中放松心情", estimatedMinutes=25),
            Gift(title="拍一张天空的照片", emoji="📸", category="记录", description="捕捉今天的美好瞬间", estimatedMinutes=5),
        ])
    elif temp < 5:  # Cold
        gifts.extend([
            Gift(title="做一些室内拉伸", emoji="🧘‍♀️", category="运动", description="温暖身体，舒展筋骨", estimatedMinutes=15),
            Gift(title="煮一碗热汤", emoji="🍲", category="温暖", description="用美食温暖自己", estimatedMinutes=30),
        ])
    elif temp > 30:  # Hot
        gifts.extend([
            Gift(title="制作一杯冰饮", emoji="🧊", category="清凉", description="为自己调制清爽饮品", estimatedMinutes=8),
            Gift(title="找个阴凉处休息", emoji="🌴", category="避暑", description="在舒适的环境中放松", estimatedMinutes=20),
        ])

    return gifts

def _analyze_mood_patterns(mood_records: List[MoodRecord]) -> Dict:
    """Analyze mood patterns from recent records"""
    if not mood_records:
        return {"dominant_mood": "neutral", "trend": "stable"}

    # Simple mood analysis
    mood_counts = {}
    for record in mood_records[-7:]:  # Last 7 records
        mood = record.mood.lower()
        mood_counts[mood] = mood_counts.get(mood, 0) + 1

    dominant_mood = max(mood_counts, key=mood_counts.get) if mood_counts else "neutral"

    # Detect anxiety/stress keywords
    anxiety_keywords = ["焦虑", "紧张", "压力", "担心", "不安"]
    happy_keywords = ["开心", "快乐", "兴奋", "满足", "愉快"]

    recent_descriptions = [r.description or "" for r in mood_records[-3:]]
    text = " ".join(recent_descriptions).lower()

    if any(keyword in text for keyword in anxiety_keywords):
        dominant_mood = "anxious"
    elif any(keyword in text for keyword in happy_keywords):
        dominant_mood = "happy"

    return {"dominant_mood": dominant_mood, "recent_text": text}

def _get_mood_based_gifts(analysis: Dict) -> List[Gift]:
    """Generate gifts based on mood analysis"""
    mood = analysis.get("dominant_mood", "neutral")
    gifts = []

    if mood == "anxious":
        gifts.extend([
            Gift(title="5分钟冥想练习", emoji="🧘", category="冥想", description="专注呼吸，让心平静下来", estimatedMinutes=5),
            Gift(title="写下三件感恩的事", emoji="📝", category="感恩", description="发现生活中的小美好", estimatedMinutes=10),
            Gift(title="听一首舒缓的音乐", emoji="🎵", category="音乐", description="让音乐带走焦虑", estimatedMinutes=8),
            Gift(title="拥抱一个柔软的物品", emoji="🧸", category="安抚", description="给自己一个温暖的拥抱", estimatedMinutes=3),
        ])
    elif mood == "happy":
        gifts.extend([
            Gift(title="分享今天的快乐", emoji="😊", category="分享", description="把快乐传递给身边的人", estimatedMinutes=10),
            Gift(title="为自己做点好吃的", emoji="🍰", category="奖励", description="用美食庆祝好心情", estimatedMinutes=25),
            Gift(title="学习一个新技能", emoji="📚", category="学习", description="趁着好心情充实自己", estimatedMinutes=30),
        ])
    elif mood in ["疲惫", "累"]:
        gifts.extend([
            Gift(title="泡个热水澡", emoji="🛁", category="放松", description="让温水洗去疲惫", estimatedMinutes=20),
            Gift(title="早点休息", emoji="😴", category="休息", description="给身体充足的休息时间", estimatedMinutes=60),
            Gift(title="做一些轻柔的拉伸", emoji="🤸‍♀️", category="舒缓", description="缓解身体的紧张", estimatedMinutes=10),
        ])

    return gifts

def _get_message_based_gifts(messages: List[str]) -> List[Gift]:
    """Generate gifts based on recent conversation context"""
    if not messages:
        return []

    text = " ".join(messages[-5:]).lower()  # Last 5 messages
    gifts = []

    # Detect conversation themes
    if any(word in text for word in ["工作", "加班", "忙碌", "压力"]):
        gifts.extend([
            Gift(title="离开工作区域5分钟", emoji="🚶", category="休息", description="给大脑一个短暂的假期", estimatedMinutes=5),
            Gift(title="做几个深呼吸", emoji="💨", category="呼吸", description="重新为身体注入活力", estimatedMinutes=3),
        ])

    if any(word in text for word in ["孤独", "寂寞", "一个人"]):
        gifts.extend([
            Gift(title="给朋友发个消息", emoji="💬", category="社交", description="主动联系一个重要的人", estimatedMinutes=5),
            Gift(title="看看宠物视频", emoji="🐱", category="陪伴", description="让可爱的小动物陪伴你", estimatedMinutes=10),
        ])

    if any(word in text for word in ["创作", "画画", "写作", "音乐"]):
        gifts.extend([
            Gift(title="创作5分钟", emoji="🎨", category="创作", description="让创意自由流淌", estimatedMinutes=15),
            Gift(title="记录一个灵感", emoji="💡", category="记录", description="捕捉脑海中的火花", estimatedMinutes=5),
        ])

    return gifts

def _get_default_gifts() -> List[Gift]:
    """Default gift recommendations"""
    return [
        Gift(title="去楼下散步", emoji="🚶‍♀️", category="运动", description="轻松走10分钟，看看天空", estimatedMinutes=10),
        Gift(title="给自己冲一杯热饮", emoji="☕", category="放松", description="慢慢喝，感受温度", estimatedMinutes=5),
        Gift(title="深呼吸小练习", emoji="🌬️", category="呼吸", description="2-4-6-4节奏×3组", estimatedMinutes=4),
        Gift(title="整理桌面", emoji="🗂️", category="整理", description="为自己创造清爽的空间", estimatedMinutes=8),
        Gift(title="给植物浇水", emoji="🌱", category="照料", description="和绿色朋友说说话", estimatedMinutes=5),
        Gift(title="拍一张自拍", emoji="🤳", category="记录", description="记录此刻的自己", estimatedMinutes=2),
    ]

def _deduplicate_gifts(gifts: List[Gift]) -> List[Gift]:
    """Remove duplicate gifts based on title"""
    seen = set()
    unique = []
    for gift in gifts:
        if gift.title not in seen:
            seen.add(gift.title)
            unique.append(gift)
    return unique

@app.get("/")
async def root():
    return {"status": "ok", "service": "Cuddle Cat AI Analysis"}

