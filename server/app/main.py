from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict, Optional, Any
from datetime import datetime
from .models import get_emotion_analyzer, get_embedding_recommender, get_cache_manager
from .advanced_analytics import behavior_analyzer, mood_predictor
from .online_learning import adaptive_engine

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Cuddle Cat AI Analysis Service")

# Enable CORS (development-friendly). Adjust origins as needed for production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class MoodRecord(BaseModel):
    timestamp: str
    mood: str
    description: Optional[str] = None

class RecommendRequest(BaseModel):
    recentMessages: List[str] = []
    moodRecords: List[MoodRecord] = []
    stats: Dict[str, float] = {}
    weather: Optional[Dict[str, Any]] = None

class Gift(BaseModel):
    title: str
    emoji: str = "🎁"
    category: str = "gift"
    description: str = ""
    reason: Optional[str] = None  # 新增：生成原因/鼓励
    estimatedMinutes: Optional[int] = None

class RecommendResponse(BaseModel):
    emotions: List[str] = []
    scores: Dict[str, float] = {}
    gifts: List[Gift] = []

@app.post("/recommend/gifts", response_model=RecommendResponse)
async def recommend_gifts(req: RecommendRequest):
    try:
        # 检查缓存
        cache_manager = get_cache_manager()
        cache_key = cache_manager.generate_key(req.dict())
        cached_result = cache_manager.get(cache_key)

        if cached_result:
            return RecommendResponse(**cached_result)

        # AI模型分析
        emotion_analyzer = get_emotion_analyzer()
        embedding_recommender = get_embedding_recommender()

        # 增强的情感分析
        all_text = " ".join(req.recentMessages + [r.description or "" for r in req.moodRecords])

        # 构建上下文信息
        weather_code = 0
        if req.weather and isinstance(req.weather, dict):
            current_weather = req.weather.get("current_weather", {})
            if isinstance(current_weather, dict):
                weather_code = current_weather.get("weathercode", 0)

        context = {
            "time_of_day": datetime.now().hour,
            "weather": weather_code,
            "recent_emotions": [r.mood for r in req.moodRecords[-5:]] if req.moodRecords else []
        }

        # 情感分析
        emotion_scores = {}
        if all_text.strip():
            try:
                emotion_result = emotion_analyzer.analyze_emotion(all_text, context)
                emotion_scores = emotion_result.get("emotions", {"neutral": 0.5})
            except Exception as e:
                print(f"Emotion analysis failed: {e}")
                emotion_scores = {"neutral": 0.5}
        else:
            emotion_scores = {"neutral": 0.5}

        # 使用自适应推荐引擎
        try:
            adaptive_result = adaptive_engine.get_adaptive_recommendations(
                user_context={
                    "recent_messages": req.recentMessages,
                    "mood_records": [r.dict() for r in req.moodRecords],
                    "stats": req.stats,
                    "weather": req.weather
                },
                emotion_scores=emotion_scores,
                context=context
            )

            if adaptive_result and adaptive_result.get("gifts"):
                recommended_gifts = adaptive_result["gifts"]
                emotion_scores.update(adaptive_result.get("emotion_scores", {}))
            else:
                # 降级到基础推荐
                recommended_gifts = _get_basic_recommendations(emotion_scores, context)

        except Exception as e:
            print(f"Adaptive recommendation failed: {e}")
            recommended_gifts = _get_basic_recommendations(emotion_scores, context)

        # 应用A/B测试风格
        from .analytics import ab_test_manager, apply_recommendation_style
        user_id = req.stats.get("user_id", "anonymous") if req.stats else "anonymous"
        style_variant = ab_test_manager.assign_variant(user_id, "recommendation_style")
        recommended_gifts = apply_recommendation_style(recommended_gifts, style_variant)

        # 去重和限制数量
        unique_gifts = _deduplicate_gifts(recommended_gifts)[:8]

        # 如果还是没有礼物，使用默认
        if not unique_gifts:
            unique_gifts = _get_default_gifts()[:8]

        # 构建响应
        dominant_emotion = max(emotion_scores, key=emotion_scores.get) if emotion_scores else "calm"
        result = {
            "emotions": [dominant_emotion],
            "scores": emotion_scores,
            "gifts": [gift.dict() if hasattr(gift, 'dict') else gift for gift in unique_gifts]
        }

        # 缓存结果
        cache_manager.set(cache_key, result, ttl=3600)  # 1小时缓存

        return RecommendResponse(**result)

    except Exception as e:
        # 返回默认推荐
        print(f"Error in recommend_gifts: {e}")
        import traceback
        traceback.print_exc()

        default_gifts = _get_default_gifts()[:3]
        return RecommendResponse(
            emotions=["calm"],
            scores={"calm": 0.7},
            gifts=[gift.dict() if hasattr(gift, 'dict') else gift for gift in default_gifts]
        )

def _get_basic_recommendations(emotion_scores: Dict[str, float], context: Dict) -> List[Dict]:
    """基础推荐算法"""
    try:
        # 获取默认礼物库
        all_gifts = _get_default_gifts()

        # 根据情感分数和上下文筛选
        scored_gifts = []
        for gift in all_gifts:
            score = _calculate_gift_score(gift, emotion_scores, context)
            scored_gifts.append((gift, score))

        # 按分数排序
        scored_gifts.sort(key=lambda x: x[1], reverse=True)

        # 返回前8个推荐
        return [gift for gift, score in scored_gifts[:8]]

    except Exception as e:
        print(f"Basic recommendation failed: {e}")
        return _get_default_gifts()[:8]

def _calculate_gift_score(gift: Dict, emotion_scores: Dict[str, float], context: Dict) -> float:
    """计算礼物匹配分数"""
    base_score = 0.5

    # 根据情感匹配
    gift_emotions = gift.get("suitable_emotions", ["neutral"])
    for emotion, score in emotion_scores.items():
        if emotion in gift_emotions:
            base_score += score * 0.3

    # 根据时间调整
    hour = context.get("time_of_day", 12)
    if gift.get("category") == "relaxation" and (hour >= 20 or hour <= 6):
        base_score += 0.2
    elif gift.get("category") == "exercise" and 6 <= hour <= 18:
        base_score += 0.2

    # 根据天气调整
    weather = context.get("weather", 0)
    if weather > 50 and gift.get("category") == "indoor":  # 恶劣天气
        base_score += 0.1
    elif weather <= 20 and gift.get("category") == "outdoor":  # 好天气
        base_score += 0.1

    return min(base_score, 1.0)

def _deduplicate_gifts(gifts: List[Dict]) -> List[Dict]:
    """Remove duplicate gifts based on title"""
    seen = set()
    unique = []
    for gift in gifts:
        title = gift.get("title", "")
        if title not in seen:
            seen.add(title)
            unique.append(gift)
    return unique

def _get_weather_score(weather_data: Optional[Dict]) -> float:
    """从天气数据计算分数"""
    if not weather_data:
        return 0.5

    current_weather = weather_data.get("current_weather", {})
    if not current_weather:
        return 0.5

    # 天气代码转换为分数 (0-100)
    weather_code = current_weather.get("weathercode", 50)
    return min(max(weather_code / 100.0, 0.0), 1.0)

def _get_current_mood_score(mood_records: List) -> float:
    """从心情记录计算当前心情分数"""
    if not mood_records:
        return 3.0

    # 获取最近的心情记录
    latest_mood = mood_records[-1] if mood_records else None
    if not latest_mood:
        return 3.0

    mood_mapping = {
        "happy": 5.0,
        "neutral": 3.0,
        "sad": 2.0,
        "angry": 1.5,
        "excited": 4.5,
        "calm": 4.0,
        "anxious": 2.0,
        "stressed": 1.8
    }

    mood_str = getattr(latest_mood, 'mood', 'neutral')
    return mood_mapping.get(mood_str, 3.0)

def _analyze_feedback_sentiment(comment: str) -> float:
    """分析反馈情感倾向"""
    if not comment:
        return 0.0

    try:
        # 使用情感分析器
        emotion_scores = emotion_analyzer.analyze_emotion_advanced(comment, {})

        # 计算整体情感分数 (-1 到 1)
        positive_emotions = ["happy", "excited", "calm", "grateful"]
        negative_emotions = ["sad", "angry", "frustrated", "disappointed"]

        positive_score = sum(emotion_scores.get(emotion, 0) for emotion in positive_emotions)
        negative_score = sum(emotion_scores.get(emotion, 0) for emotion in negative_emotions)

        return positive_score - negative_score
    except Exception:
        return 0.0

def _extract_context_features(context: Dict) -> List[float]:
    """从上下文中提取特征"""
    features = []

    # 时间特征
    hour = datetime.now().hour
    features.append(hour / 24.0)  # 标准化到0-1

    # 天气特征
    weather_score = context.get("weather_score", 0.5)
    features.append(weather_score)

    # 心情特征
    mood_score = context.get("mood_score", 3.0)
    features.append(mood_score / 5.0)  # 标准化到0-1

    # 使用频率特征
    usage_frequency = context.get("usage_frequency", 1)
    features.append(min(usage_frequency / 10.0, 1.0))  # 标准化

    return features

def _extract_feedback_features(feedback: Dict, context: Dict) -> List[float]:
    """提取反馈特征用于机器学习"""
    features = []

    # 基础特征
    features.append(feedback.get("rating", 3) / 5.0)  # 评分
    features.append(len(feedback.get("comment", "")) / 100.0)  # 评论长度
    features.append(feedback.get("sentiment_score", 0.0))  # 情感分数

    # 上下文特征
    features.extend(_extract_context_features(context))

    # 用户行为特征
    features.append(1.0 if feedback.get("completed", False) else 0.0)  # 是否完成
    features.append(feedback.get("time_spent", 0) / 60.0)  # 花费时间（分钟）

    return features

def _update_recommendation_weights(user_id: str, feedback: Dict):
    """根据反馈更新推荐权重"""
    try:
        rating = feedback.get("rating", 3)
        gift_category = feedback.get("gift_category", "")

        # 如果评分很高，增加该类别的权重
        if rating >= 4 and gift_category:
            current_weights = adaptive_engine.strategy_weights.copy()

            # 简单的权重调整逻辑
            if gift_category in ["relaxation", "mindfulness"]:
                current_weights["mood_based"] = min(current_weights["mood_based"] + 0.05, 0.5)
            elif gift_category in ["exercise", "outdoor"]:
                current_weights["engagement_based"] = min(current_weights["engagement_based"] + 0.05, 0.5)

            # 重新标准化权重
            total_weight = sum(current_weights.values())
            if total_weight > 0:
                for key in current_weights:
                    current_weights[key] /= total_weight

                adaptive_engine.strategy_weights.update(current_weights)

    except Exception as e:
        print(f"权重更新失败: {e}")

def _get_weather_score_old(weather_data: Optional[Dict]) -> float:
    """从天气数据计算分数"""
    if not weather_data:
        return 3.0

    current_weather = weather_data.get("current_weather", {})
    weather_code = current_weather.get("weathercode", 0)

    # 简化的天气分数映射
    if weather_code in [0, 1, 2]:  # 晴天
        return 4.5
    elif weather_code in [3, 45, 48]:  # 多云
        return 3.5
    elif weather_code in [51, 53, 55, 61, 63, 65]:  # 雨天
        return 2.5
    else:
        return 3.0

def _get_current_mood_score(mood_records: List) -> float:
    """从心情记录计算当前心情分数"""
    if not mood_records:
        return 3.0

    # 获取最近的心情记录
    latest_mood = mood_records[-1] if mood_records else None
    if not latest_mood:
        return 3.0

    mood_mapping = {
        "happy": 5.0,
        "neutral": 3.0,
        "sad": 2.0,
        "angry": 1.5
    }

    mood_str = getattr(latest_mood, 'mood', 'neutral')
    return mood_mapping.get(mood_str, 3.0)

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
            Gift(title="5分钟冥想练习", emoji="🧘", category="冥想", description="专注呼吸，让心平静下来", reason="你最近有点焦虑，先把注意力带回呼吸上，让神经系统稳定下来~", estimatedMinutes=5),
            Gift(title="写下三件感恩的事", emoji="📝", category="感恩", description="发现生活中的小美好", reason="把注意力放到正向事件上，可以缓和紧绷感~", estimatedMinutes=10),
            Gift(title="听一首舒缓的音乐", emoji="🎵", category="音乐", description="让音乐带走焦虑", reason="音乐能帮助大脑“换频道”，心也会慢慢松开~", estimatedMinutes=8),
            Gift(title="拥抱一个柔软的物品", emoji="🧸", category="安抚", description="给自己一个温暖的拥抱", reason="由外而内的安抚触感，会给大脑安全感~", estimatedMinutes=3),
        ])
    elif mood == "happy":
        gifts.extend([
            Gift(title="分享今天的快乐", emoji="😊", category="分享", description="把快乐传递给身边的人", reason="把好心情分享出去，快乐会加倍~", estimatedMinutes=10),
            Gift(title="为自己做点好吃的", emoji="🍰", category="奖励", description="用美食庆祝好心情", reason="给自己一个小奖励，巩固积极体验~", estimatedMinutes=25),
            Gift(title="学习一个新技能", emoji="📚", category="学习", description="趁着好心情充实自己", reason="情绪充足的时候，学习效果更棒！", estimatedMinutes=30),
        ])
    elif mood in ["疲惫", "累"]:
        gifts.extend([
            Gift(title="泡个热水澡", emoji="🛁", category="放松", description="让温水洗去疲惫", reason="温热能促进放松与入睡，今晚会更好眠~", estimatedMinutes=20),
            Gift(title="早点休息", emoji="😴", category="休息", description="给身体充足的休息时间", reason="你真的辛苦了，休息也是在向前走~", estimatedMinutes=60),
            Gift(title="做一些轻柔的拉伸", emoji="🤸‍♀️", category="舒缓", description="缓解身体的紧张", reason="把肩颈放松一点点，心也就松一点点~", estimatedMinutes=10),
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

def _get_default_gifts() -> List[Dict]:
    """Default gift recommendations with emotion matching"""
    gifts = [
        {
            "id": "walk_1",
            "title": "去楼下散步",
            "description": "轻松走10分钟，看看天空",
            "reason": "你最近状态有些紧绷，出去走走能帮助大脑换个场景，放松一下哦~",
            "category": "exercise",
            "difficulty": "easy",
            "duration": 10,
            "icon": "🚶‍♀️",
            "suitable_emotions": ["sad", "anxious", "neutral", "stressed"]
        },
        {
            "id": "hot_drink_1",
            "title": "给自己冲一杯热饮",
            "description": "慢慢喝，感受温度",
            "reason": "天气有点凉+情绪略低时，一点点热饮的甜会让多巴胺微微上线~",
            "category": "relaxation",
            "difficulty": "easy",
            "duration": 5,
            "icon": "☕",
            "suitable_emotions": ["calm", "neutral", "tired", "cold"]
        },
        {
            "id": "breathing_1",
            "title": "深呼吸小练习",
            "description": "2-4-6-4节奏×3组",
            "reason": "焦虑时调节呼吸能帮助神经系统稳定下来，3分钟就见效~",
            "category": "mindfulness",
            "difficulty": "easy",
            "duration": 4,
            "icon": "🌬️",
            "suitable_emotions": ["anxious", "stressed", "angry", "overwhelmed"]
        },
        {
            "id": "organize_1",
            "title": "整理桌面",
            "description": "为自己创造清爽的空间",
            "reason": "把可见的小范围收拾一下，会带来“我能掌控一点点”的积极感受~",
            "category": "productivity",
            "difficulty": "easy",
            "duration": 8,
            "icon": "🗂️",
            "suitable_emotions": ["frustrated", "overwhelmed", "neutral"]
        },
        {
            "id": "plant_care_1",
            "title": "给植物浇水",
            "description": "和绿色朋友说说话",
            "reason": "与绿色互动能轻微降低压力荷尔蒙，让心慢慢沉静下来~",
            "category": "nurturing",
            "difficulty": "easy",
            "duration": 5,
            "icon": "🌱",
            "suitable_emotions": ["calm", "peaceful", "loving", "nurturing"]
        },
        {
            "id": "selfie_1",
            "title": "拍一张自拍",
            "description": "记录此刻的自己",
            "reason": "给今天打个卡，肯定一下走过的小步子~",
            "category": "self_expression",
            "difficulty": "easy",
            "duration": 2,
            "icon": "🤳",
            "suitable_emotions": ["happy", "confident", "excited", "playful"]
        },
        {
            "id": "music_1",
            "title": "听一首喜欢的歌",
            "description": "让音乐带走烦恼",
            "reason": "音乐对情绪的调频很有效，选一首熟悉的旋律轻轻放~",
            "category": "entertainment",
            "difficulty": "easy",
            "duration": 4,
            "icon": "🎵",
            "suitable_emotions": ["sad", "happy", "nostalgic", "energetic"]
        },
        {
            "id": "stretch_1",
            "title": "简单拉伸运动",
            "description": "舒展身体，释放紧张",
            "reason": "身体的松弛会带动心的松弛，6分钟就够~",
            "category": "exercise",
            "difficulty": "easy",
            "duration": 6,
            "icon": "🤸‍♀️",
            "suitable_emotions": ["tired", "tense", "stiff", "restless"]
        }
    ]
    return gifts

def _deduplicate_gifts(gifts: List[Dict]) -> List[Dict]:
    """Remove duplicate gifts based on title"""
    seen = set()
    unique = []
    for gift in gifts:
        title = gift.get("title", "")
        if title not in seen:
            seen.add(title)
            unique.append(gift)
    return unique

@app.post("/feedback")
async def submit_feedback(feedback_data: dict):
    """接收用户反馈并触发智能学习"""
    from .analytics import analytics

    try:
        user_id = feedback_data.get("user_id", "anonymous")
        feedback = feedback_data.get("feedback", {})
        recommendation_id = feedback.get("giftId", "")
        rating = feedback.get("rating", 3)
        context = feedback_data.get("context", {})

        # 增强的反馈处理
        enhanced_feedback = {
            **feedback,
            "timestamp": datetime.now().isoformat(),
            "processed": False,
            "sentiment_score": _analyze_feedback_sentiment(feedback.get("comment", "")),
            "context_features": _extract_context_features(context)
        }

        # 记录反馈到分析系统
        analytics.log_user_feedback(
            user_id=user_id,
            recommendation_id=recommendation_id,
            feedback=enhanced_feedback
        )

        # 智能特征提取和在线学习
        if rating and recommendation_id:
            features = _extract_feedback_features(enhanced_feedback, context)

            # 根据反馈类型选择合适的模型
            feedback_type = feedback.get("type", "satisfaction")
            if feedback_type == "mood":
                adaptive_engine.mood_predictor.add_training_sample(features, rating, user_id)
            elif feedback_type == "engagement":
                adaptive_engine.engagement_predictor.add_training_sample(features, rating, user_id)
            else:
                adaptive_engine.satisfaction_predictor.add_training_sample(features, rating, user_id)

        # 触发自适应学习
        try:
            adaptive_engine.update_user_feedback(
                user_id=user_id,
                recommendation_id=recommendation_id,
                feedback=enhanced_feedback
            )
        except Exception as e:
            print(f"Adaptive learning update failed: {e}")

        # 实时推荐优化
        _update_recommendation_weights(user_id, enhanced_feedback)

        return {
            "status": "success",
            "message": "Feedback recorded and processed intelligently",
            "feedback_id": f"{user_id}_{recommendation_id}_{datetime.now().timestamp()}"
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/analytics/stats")
async def get_analytics_stats(days: int = 7):
    """获取分析统计"""
    from .analytics import analytics

    stats = analytics.get_recommendation_stats(days=days)
    return stats

@app.post("/analytics/user-clusters")
async def analyze_user_clusters(user_data: List[Dict]):
    """用户聚类分析"""
    try:
        result = behavior_analyzer.analyze_user_clusters(user_data)
        return {"status": "success", "data": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/analytics/train-mood-predictor")
async def train_mood_predictor(training_data: List[Dict]):
    """训练心情预测模型"""
    try:
        result = mood_predictor.train(training_data)
        return {"status": "success", "data": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/analytics/predict-mood")
async def predict_mood(user_context: Dict):
    """预测用户心情"""
    try:
        result = mood_predictor.predict_mood(user_context)
        return {"status": "success", "data": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/analytics/emotion-advanced")
async def analyze_emotion_advanced(request: Dict):
    """高级情感分析"""
    try:
        emotion_analyzer = get_emotion_analyzer()
        text = request.get("text", "")
        context = request.get("context", {})

        result = emotion_analyzer.analyze_emotion_advanced(text, context)
        return {"status": "success", "emotions": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/learning/system-stats")
async def get_learning_system_stats():
    """获取在线学习系统统计"""
    try:
        stats = adaptive_engine.get_system_stats()
        return {"status": "success", "data": stats}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/learning/update-strategy-weights")
async def update_strategy_weights(weights: Dict[str, float]):
    """更新推荐策略权重"""
    try:
        # 验证权重总和为1
        total_weight = sum(weights.values())
        if abs(total_weight - 1.0) > 0.01:
            return {"status": "error", "message": "Weights must sum to 1.0"}

        adaptive_engine.strategy_weights.update(weights)
        return {"status": "success", "message": "Strategy weights updated"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/learning/train-models")
async def train_models():
    """手动触发模型训练"""
    try:
        results = {}

        # 训练心情预测模型
        mood_engine = adaptive_engine.mood_predictor
        if not mood_engine.is_initialized:
            mood_engine._initialize_with_synthetic_data()
            results["mood_predictor"] = "initialized with synthetic data"
        else:
            results["mood_predictor"] = "already initialized"

        # 训练参与度预测模型
        engagement_engine = adaptive_engine.engagement_predictor
        if not engagement_engine.is_initialized:
            engagement_engine._initialize_with_synthetic_data()
            results["engagement_predictor"] = "initialized with synthetic data"
        else:
            results["engagement_predictor"] = "already initialized"

        # 训练满意度预测模型
        satisfaction_engine = adaptive_engine.satisfaction_predictor
        if not satisfaction_engine.is_initialized:
            satisfaction_engine._initialize_with_synthetic_data()
            results["satisfaction_predictor"] = "initialized with synthetic data"
        else:
            results["satisfaction_predictor"] = "already initialized"

        return {
            "status": "success",
            "results": results,
            "message": "Model training completed"
        }

    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }

@app.post("/learning/add-training-data")
async def add_training_data(data: Dict):
    """添加训练数据"""
    try:
        model_type = data.get("model_type", "mood")
        features = data.get("features", [])
        target = data.get("target", 0)
        user_id = data.get("user_id", "anonymous")
        weight = data.get("weight", 1.0)

        if not features:
            return {"status": "error", "message": "Features are required"}

        # 选择对应的模型
        if model_type == "mood":
            engine = adaptive_engine.mood_predictor
        elif model_type == "engagement":
            engine = adaptive_engine.engagement_predictor
        elif model_type == "satisfaction":
            engine = adaptive_engine.satisfaction_predictor
        else:
            return {"status": "error", "message": "Invalid model type"}

        # 添加训练样本
        engine.add_training_sample(features, target, user_id, weight)

        return {
            "status": "success",
            "message": f"Training sample added to {model_type} model",
            "buffer_size": len(engine.learning_buffer)
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/")
async def root():
    return {"status": "ok", "service": "Cuddle Cat AI Analysis"}

@app.get("/health")
async def health_check():
    """健康检查端点"""
    try:
        from .models import get_cache_manager
        cache_manager = get_cache_manager()

        # 检查缓存系统
        cache_status = "ok"
        try:
            cache_manager.set("health_check", {"test": True}, ttl=60)
            cache_result = cache_manager.get("health_check")
            if not cache_result:
                cache_status = "degraded"
        except Exception:
            cache_status = "error"

        # 检查AI模型状态
        model_status = "ok"
        try:
            if not adaptive_engine.mood_predictor.is_initialized:
                model_status = "initializing"
        except Exception:
            model_status = "error"

        # 获取缓存统计
        cache_stats = cache_manager.get_cache_stats()

        return {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "services": {
                "cache": cache_status,
                "ai_models": model_status,
            },
            "cache_stats": cache_stats,
            "version": "1.0.0"
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

@app.get("/metrics")
async def get_metrics():
    """获取系统指标"""
    try:
        from .models import get_cache_manager
        cache_manager = get_cache_manager()

        # 缓存统计
        cache_stats = cache_manager.get_cache_stats()

        # AI模型统计
        model_stats = adaptive_engine.get_system_stats()

        # 系统统计
        import psutil
        system_stats = {
            "cpu_percent": psutil.cpu_percent(),
            "memory_percent": psutil.virtual_memory().percent,
            "disk_usage": psutil.disk_usage('/').percent if hasattr(psutil, 'disk_usage') else 0
        }

        return {
            "cache": cache_stats,
            "models": model_stats,
            "system": system_stats,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {"error": str(e)}

