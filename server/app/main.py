import os
from fastapi import FastAPI, Response, HTTPException, Depends, Header
from pydantic import BaseModel, field_validator, model_validator
from typing import List, Dict, Optional, Any
from datetime import datetime
from .models import get_emotion_analyzer, get_embedding_recommender, get_cache_manager
from .advanced_analytics import behavior_analyzer, mood_predictor
from .online_learning import adaptive_engine
from .db import init_db, upsert_events, query_events

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Cuddle Cat AI Analysis Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

init_db()

from .metrics import inc as metrics_inc, get_counters as metrics_get, uptime_seconds as metrics_uptime, add_latency_sample as metrics_add_latency, get_latency_p95 as metrics_p95

from .db_feedback import ensure_feedback_table, insert_feedback, fetch_feedback_stats
ensure_feedback_table()

def require_metrics_key(x_api_key: str | None = Header(default=None, alias='X-API-Key')):
    required = os.getenv('METRICS_API_KEY') or os.getenv('AI_SERVICE_INTERNAL_KEY')
    if required:
        if not x_api_key or x_api_key != required:
            raise HTTPException(status_code=403, detail='Forbidden')
    return True



class MoodRecord(BaseModel):
    timestamp: str
    mood: str
    description: Optional[str] = None

class RecommendRequest(BaseModel):
    recentMessages: List[str] = []
    moodRecords: List[MoodRecord] = []
    stats: Dict[str, Any] = {}
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


class PlanGoal(BaseModel):
    title: str
    rationale: Optional[str] = None
    horizon: str = "weekly"  # 'weekly' | 'monthly'

class PlanHabit(BaseModel):
    title: str
    category: str
    frequency: str  # e.g., '3x/week', 'daily'
    estimatedMinutes: Optional[int] = None
    reason: Optional[str] = None

class PlanCheckpoint(BaseModel):
    week: int
    focus: str
    metricHint: Optional[str] = None

class WellnessPlan(BaseModel):
    goals: List[PlanGoal] = []
    habits: List[PlanHabit] = []
    checkpoints: List[PlanCheckpoint] = []
    tips: List[str] = []

class WellnessPlanResponse(BaseModel):
    status: str = "success"
    data: WellnessPlan


class MemoryEvent(BaseModel):
    user_id: str
    type: str
    @field_validator('type')
    @classmethod
    def _check_type(cls, v: str):
        if not isinstance(v, str):
            raise ValueError('type must be string')
        if len(v) > _MAX_MEMORY_TYPE_LEN:
            raise ValueError(f'type too long (max={_MAX_MEMORY_TYPE_LEN})')
        return v
    @field_validator('text')
    @classmethod
    def _check_text(cls, v: Optional[str]):
        if v is None:
            return v
        if len(v) > _MAX_MEMORY_TEXT_LEN:
            raise ValueError(f'text too long (max={_MAX_MEMORY_TEXT_LEN})')
        return v

    text: Optional[str] = None
    metadata: Dict[str, Any] = {}
    @field_validator('metadata')
    @classmethod
    def _check_meta(cls, v: Dict[str, Any]):
        # constrain key/value sizes to avoid abuse
        max_key = 64; max_val = 256
        out = {}
        for k, val in (v or {}).items():
            if not isinstance(k, str) or len(k) > max_key:
                raise ValueError('metadata key too long or not string')
            if isinstance(val, str) and len(val) > max_val:
                raise ValueError('metadata string value too long')
            out[k] = val
        return out
    timestamp: Optional[str] = None

class MemoryUpsertRequest(BaseModel):
    events: List[MemoryEvent]

class MemoryQueryRequest(BaseModel):
    user_id: str
    query: Optional[str] = None
    top_k: int = 10

from .vector_store import add_texts as vs_add_texts, query as vs_query

class MemoryQueryResponse(BaseModel):
    status: str = "success"
    data: List[Dict[str, Any]]


# Chat reply models
# Security limits (can be configured via env later if needed)
_MAX_MESSAGE_LEN = 2000
_MAX_MEMORY_TEXT_LEN = 2000
_MAX_MEMORY_TYPE_LEN = 32
_MAX_FEEDBACK_COMMENT_LEN = 500
_ALLOWED_FEEDBACK_TYPES = {"like","dislike","complete","skip","useful"}

class ChatMessage(BaseModel):
    role: str  # 'user' | 'assistant' | 'system'
    content: str
    @field_validator('content')
    @classmethod
    def _check_content(cls, v: str):
        if not isinstance(v, str):
            raise ValueError('content must be string')
        if len(v) > _MAX_MESSAGE_LEN:
            raise ValueError(f'message too long (max={_MAX_MESSAGE_LEN})')
        return v


class ChatReplyRequest(BaseModel):
    user_id: str
    messages: List[ChatMessage]
    top_k_memories: int = 3

class GoalMemory(BaseModel):
    user_id: str
    goal_type: str  # e.g., 'personal_goal'
    content: str
    extracted_at: str

class ReminderSuggestion(BaseModel):
    text: str
    tone: str = "warm"

class ChatReplyData(BaseModel):
    text: str
    used_memories: List[Dict[str, Any]] = []
    profile: Dict[str, Any] = {}
    references: List[str] = []
    extracted_goals: List[GoalMemory] = []

class ChatReplyResponse(BaseModel):
    status: str = "success"
    data: ChatReplyData



@app.post("/recommend/gifts", response_model=RecommendResponse)
async def recommend_gifts(req: RecommendRequest):
    try:
        # 检查缓存
        cache_manager = get_cache_manager()
        cache_key = cache_manager.generate_key(req.dict())
        cached_result = cache_manager.get(cache_key)

        if cached_result:
            return RecommendResponse(**cached_result)

        # 后续逻辑继续在本函数内执行




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
            # 应用A/B测试风格并去重、限制数量
            from .analytics import ab_test_manager, apply_recommendation_style
            user_id = req.stats.get("user_id", "anonymous") if req.stats else "anonymous"
            style_variant = ab_test_manager.assign_variant(user_id, "recommendation_style")
            recommended_gifts = apply_recommendation_style(recommended_gifts, style_variant)

            recommended_gifts = _deduplicate_gifts(recommended_gifts)[:8]

            # 写入缓存
            result = {
                "emotions": list(emotion_scores.keys()),
                "scores": {k: float(v) for k, v in emotion_scores.items()},
                "gifts": recommended_gifts,
            }
            cache_manager.set(cache_key, result, ttl=600)
            return RecommendResponse(**result)
        except Exception as e:
            # 返回默认推荐
            print(f"Error in recommend_gifts: {e}")
            import traceback
            traceback.print_exc()
            default_gifts = _get_default_gifts()[:3]
            return RecommendResponse(
                emotions=["calm"],
                scores={"calm": 0.5},
                gifts=default_gifts,
            )

    except Exception as e:
        # 外层降级：确保函数总能返回
        print(f"Error in recommend_gifts (outer): {e}")
        import traceback
        traceback.print_exc()
        default_gifts = _get_default_gifts()[:3]
        return RecommendResponse(
            emotions=["calm"],
            scores={"calm": 0.5},
            gifts=default_gifts,
        )


@app.post("/recommend/wellness-plan", response_model=WellnessPlanResponse)
async def recommend_wellness_plan(req: RecommendRequest):
    """生成个性化幸福/健康计划（独立于 gifts）"""
    try:
        user_id = req.stats.get("user_id", "anonymous") if req.stats else "anonymous"
        hour = datetime.now().hour
        # 从自适应引擎读取用户偏好
        prefs = adaptive_engine.user_preferences.get(user_id, {
            'category_weights': {},
            'time_preferences': {},
            'difficulty_preference': 0.5,
            'social_preference': 0.5,
        })

        # 简易情感倾向
        recent_moods = [r.mood for r in req.moodRecords[-5:]] if req.moodRecords else []
        dominant_mood = recent_moods[-1] if recent_moods else 'neutral'

        # 目标
        goals = [
            PlanGoal(title="稳定情绪波动", rationale="结合最近心情记录，优先安排稳定情绪的小习惯"),
            PlanGoal(title="提升完成率", rationale="根据近期完成率，为你安排可完成的小步任务"),
        ]
        cw = prefs.get('category_weights', {})
        top_cat = max(cw, key=cw.get) if cw else None
        if top_cat:
            goals.append(PlanGoal(title=f"多做你喜欢的『{top_cat}』", rationale="利用正向偏好提升动力"))

        # 习惯
        habits: List[PlanHabit] = []
        def add_habit(title, category, freq, minutes, reason):
            habits.append(PlanHabit(title=title, category=category, frequency=freq, estimatedMinutes=minutes, reason=reason))

        add_habit("步行10分钟", "运动", "3x/week", 10, "轻量运动可改善情绪与睡眠质量")
        add_habit("睡前放松呼吸", "放松", "daily", 5, "帮助入睡，缓解紧张")
        add_habit("记录3件小确幸", "感恩", "3x/week", 6, "提升积极关注，减缓压力")
        if dominant_mood in ("anxious", "sad"):
            add_habit("午后阳光10分钟", "自然", "3x/week", 10, "自然光照有助于改善低落与焦虑感")
        if top_cat == '创作':
            add_habit("随手涂鸦/写一句话", "创作", "3x/week", 8, "让创意以低门槛释放")

        tp = prefs.get('time_preferences', {})
        evening_pref = tp.get(hour, 0.5) > 0.6
        if evening_pref:
            habits = sorted(habits, key=lambda h: 0 if h.category in ("放松", "自然") else 1)

        checkpoints = [
            PlanCheckpoint(week=1, focus="先建立节奏（频率优先）", metricHint="完成频次 ≥ 60%"),
            PlanCheckpoint(week=2, focus="巩固并微调（增加你喜欢的类别）", metricHint="主观满意度 ≥ 3/5"),
            PlanCheckpoint(week=3, focus="提升难度或时长（小幅度）", metricHint="连续完成天数 ≥ 3"),
            PlanCheckpoint(week=4, focus="复盘与定制下一周期", metricHint="选择保留的2-3个习惯"),
        ]

        tips = [
            "优先完成最容易的一项，建立连胜感",
            "做不到也没关系，明天继续，小步快走",
            "把目标放在看到的地方（手机便签/日历）",
        ]

        plan = WellnessPlan(goals=goals, habits=habits, checkpoints=checkpoints, tips=tips)
        return WellnessPlanResponse(status="success", data=plan)
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/analytics/profile/{user_id}")
async def analytics_profile(user_id: str):
    try:
        from .db import fetch_user_events
        events = fetch_user_events(user_id, since_days=60, limit=500)
        category_weights: Dict[str, int] = {}
        hour_pref = [0]*24
        emotion_trend: List[Dict[str, Any]] = []
        engagement = 0
        for ev in events:
            t = (ev.get('type') or 'generic')
            category_weights[t] = category_weights.get(t, 0) + 1
            ts = (ev.get('timestamp') or '')
            if len(ts) >= 13 and ts[11:13].isdigit():
                hour = int(ts[11:13])
                if 0 <= hour <= 23:
                    hour_pref[hour] += 1
            txt = (ev.get('text') or '')
            if txt:
                lower = txt.lower()
                emo = 'neutral'
                if any(k in lower for k in ['开心','高兴','快乐','愉快','兴奋','满意']):
                    emo = 'happy'
                elif any(k in lower for k in ['伤心','难过','悲伤','失落','沮丧']):
                    emo = 'sad'
                elif any(k in lower for k in ['生气','愤怒','火大','怒']):
                    emo = 'angry'
                elif any(k in lower for k in ['焦虑','担心','紧张']):
                    emo = 'anxious'
                emotion_trend.append({'timestamp': ts, 'emotion': emo})
            engagement += 1
        tasks_total = category_weights.get('task', 0)
        completion_rate = 0.0
        if tasks_total:
            completion_rate = min(1.0, (tasks_total * 0.33) / max(1, tasks_total))
        # 计算 top_categories 与 active_hours（Top3）
        top_categories = [k for k, _ in sorted(category_weights.items(), key=lambda kv: kv[1], reverse=True)[:3]]
        active_hours = [i for i, _ in sorted(list(enumerate(hour_pref)), key=lambda kv: kv[1], reverse=True)[:3]]
        profile = {
            'user_id': user_id,
            'category_weights': category_weights,
            'time_preferences': hour_pref,
            'emotion_trend': emotion_trend[-50:],
            'engagement': engagement,
            'completion_rate': completion_rate,
            'top_categories': top_categories,
            'active_hours': active_hours,
        }
        return {'status': 'success', 'data': profile}
    except Exception as e:
        return {'status': 'error', 'message': str(e), 'data': {}}



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
    """分析反馈情感倾向（极简启发式）"""
    if not comment:
        return 0.0
    try:
        lower = comment.lower()
        positive_keys = ['great', 'love', '喜欢', '满意', '不错', '开心', '放松']
        negative_keys = ['差', '不喜欢', '讨厌', '生气', '糟糕', '压力', '焦虑']
        if any(k in lower for k in positive_keys):
            return 0.8
        if any(k in lower for k in negative_keys):
            return 0.2
        return 0.5
    except Exception:
        return 0.5

@app.post("/chat/reply", response_model=ChatReplyResponse)
async def chat_reply(req: ChatReplyRequest):
    try:
        metrics_inc('chat_reply_requests', 1)
        start_time = datetime.now()
        # 取最后一条用户消息
        last_user = next((m for m in reversed(req.messages) if m.role == 'user'), None)
        query_text = last_user.content if last_user else None

        # 检索记忆（向量优先、回退DB）
        used_memories: List[Dict[str, Any]] = []
        retrieval_had_vector = False
        retrieval_fallback = False
        if query_text:
            try:
                vs_items = vs_query(query_text, top_k=req.top_k_memories, filters={"user_id": req.user_id})
                threshold = float(os.getenv('MEMORY_VECTOR_SCORE_THRESHOLD', '0.6'))
                # vector scores avg (before filter)
                try:
                    scores = [float(it.get('score', 0.0)) for it in vs_items]
                    if scores:
                        metrics_inc('mem_vector_score_sum', int(sum(scores) * 1000))
                        metrics_inc('mem_vector_score_count', len(scores))
                except Exception:
                    pass
                filtered = [it for it in vs_items if float(it.get('score', 0.0)) >= threshold]
                used_memories = [
                    {"text": it.get("text"), "type": it.get("type"), "timestamp": it.get("timestamp")}
                    for it in filtered
                ]
                retrieval_had_vector = True
                if used_memories:
                    metrics_inc('mem_retrieval_hits', 1)
            except Exception:
                used_memories = []
        if not used_memories:
            used_memories = query_events(req.user_id, query_text, req.top_k_memories)
            retrieval_fallback = True
        # metrics: retrieval counters
        try:
            metrics_inc('mem_retrieval_total', 1)
            if retrieval_had_vector and retrieval_fallback:
                metrics_inc('mem_retrieval_fallback', 1)
        except Exception:
            pass

        # 用户画像
        from .db import fetch_user_events
        events = fetch_user_events(req.user_id, since_days=60, limit=500)
        # 简易画像（复用 analytics_profile 的逻辑片段）
        category_weights: Dict[str, int] = {}
        for ev in events:
            t = (ev.get('type') or 'generic')
            category_weights[t] = category_weights.get(t, 0) + 1
        top_categories = [k for k, _ in sorted(category_weights.items(), key=lambda kv: kv[1], reverse=True)[:3]]
        # latency metric
        try:
            from datetime import datetime as _dt
            dur = int((_dt.now() - start_time).total_seconds() * 1000)
            metrics_inc('chat_reply_latency_ms_sum', dur)
            metrics_inc('chat_reply_latency_ms_count', 1)
            metrics_add_latency(dur)
        except Exception:
            # best-effort metrics; ignore failures
            pass

        # 构造系统提示（去动作/姿态，允许 emoji）
        system_rules = (
            "你是温柔、务实的陪伴型助理。避免舞台指令或姿态描述，不要写出‘微笑着’‘拥抱’等。"
            "可以使用少量 emoji 进行情感增强但避免过多。"
        )
        memory_block = "\n".join([f"- {m.get('text','')}" for m in used_memories if m.get('text')])
        profile_block = f"偏好类别Top: {', '.join(top_categories)}" if top_categories else ""

        # 目标提取（启发式+关键词；后续可接LLM）
        extracted_goals: List[GoalMemory] = []
        try:
            text_to_scan = (query_text or "").strip()
            goal_keywords = [
                "我希望", "我想要", "我打算", "我计划", "希望我能", "想要克服", "我要改进"
            ]
            if any(k in text_to_scan for k in goal_keywords) and 3 <= len(text_to_scan) <= _MAX_MESSAGE_LEN:
                # 简易抽取：去掉引导词，截取核心内容
                normalized = text_to_scan
                for k in goal_keywords:
                    normalized = normalized.replace(k, "")
                content = normalized.strip().strip('。.!?')
                if content:
                    extracted_goals.append(GoalMemory(
                        user_id=req.user_id,
                        goal_type='personal_goal',
                        content=content,
                        extracted_at=datetime.now().isoformat(timespec='minutes')
                    ))
        except Exception:
            pass

        # 若提取到目标，落库到 memory_events 并写向量索引
        if extracted_goals:
            try:
                from .db import upsert_events
                events = []
                texts, metas = [], []
                for g in extracted_goals:
                    payload = {
                        "user_id": g.user_id,
                        "type": "goal",
                        "text": g.content,
                        "metadata": {"goal_type": g.goal_type, "extracted_at": g.extracted_at},
                        "timestamp": g.extracted_at,
                    }
                    events.append(payload)
                    texts.append(g.content)
                    metas.append({"user_id": g.user_id, "type": "goal", "text": g.content, "timestamp": g.extracted_at})
                upsert_events(events)
                try:
                    vs_add_texts(texts, metas)
                except Exception:
                    pass
            except Exception:
                pass

        # 参考信息
        references: List[str] = []
        if used_memories:
            references.append(f"used_memories:{len(used_memories)}")
        if top_categories:
            references.append(f"top_categories:{','.join(top_categories)}")
        if extracted_goals:
            references.append(f"extracted_goals:{len(extracted_goals)}")

        # 最小回复生成（规则+拼接；后续阶段可接LLM）
        user_text = query_text or ""
        reply = f"{system_rules}\n\n结合你的历史偏好与记忆：\n{memory_block}\n\n我的建议：针对你刚才说的‘{user_text}’，考虑从你常见的{profile_block}中选一项先开始吧。"
        return ChatReplyResponse(status="success", data=ChatReplyData(text=reply, used_memories=used_memories, profile={"top_categories": top_categories}, references=references, extracted_goals=extracted_goals))
    except Exception as e:
        metrics_inc('chat_reply_errors', 1)

        # 降级：仅回显用户消息
        fallback = next((m.content for m in reversed(req.messages) if m.role == 'user'), "" )
        return ChatReplyResponse(status="success", data=ChatReplyData(text=fallback, used_memories=[], profile={}))

@app.get("/metrics")
async def get_metrics(_: bool = Depends(require_metrics_key)):
    p95 = metrics_p95()
    counters = metrics_get()
    lat_sum = float(counters.get('chat_reply_latency_ms_sum', 0))
    lat_cnt = float(counters.get('chat_reply_latency_ms_count', 0))
    lat_avg = (lat_sum / lat_cnt) if lat_cnt > 0 else None
    vec_sum = float(counters.get('mem_vector_score_sum', 0)) / 1000.0
    vec_cnt = float(counters.get('mem_vector_score_count', 0))
    vec_avg = (vec_sum / vec_cnt) if vec_cnt > 0 else None
    return {
        "status": "success",
        "data": {
            "counters": counters,
            "uptime_seconds": metrics_uptime(),
            "latency_ms_p95": p95,
            "latency_ms_avg": lat_avg,
            "mem_vector_score_avg": vec_avg,
        }
    }

@app.get("/metrics_prom")
async def get_metrics_prom(_: bool = Depends(require_metrics_key)):
    counters = metrics_get()
    p95 = metrics_p95()
    lat_sum = float(counters.get('chat_reply_latency_ms_sum', 0))
    lat_cnt = float(counters.get('chat_reply_latency_ms_count', 0))
    lat_avg = (lat_sum / lat_cnt) if lat_cnt > 0 else None
    vec_sum = float(counters.get('mem_vector_score_sum', 0)) / 1000.0
    vec_cnt = float(counters.get('mem_vector_score_count', 0))
    vec_avg = (vec_sum / vec_cnt) if vec_cnt > 0 else None

    lines = []
    # HELP/TYPE headers
    lines.append("# HELP cuddle_uptime_seconds Process uptime in seconds")
    lines.append("# TYPE cuddle_uptime_seconds gauge")
    lines.append("# HELP cuddle_latency_ms_p95 Rolling p95 of chat reply latency (ms)")
    lines.append("# TYPE cuddle_latency_ms_p95 gauge")
    lines.append("# HELP cuddle_latency_ms_avg Average chat reply latency (ms)")
    lines.append("# TYPE cuddle_latency_ms_avg gauge")
    lines.append("# HELP cuddle_mem_vector_score_avg Average similarity score from vector search")
    lines.append("# TYPE cuddle_mem_vector_score_avg gauge")

    def g(k, v):
        if v is None:
            return
        lines.append(f"{k} {v}")

    # counters as gauge for simplicity (with specific HELP when known)
    help_map = {
        'chat_reply_requests': 'Total number of /chat/reply requests',
        'chat_reply_errors': 'Total number of /chat/reply errors',
        'mem_retrieval_total': 'Total number of memory retrieval attempts per chat',
        'mem_retrieval_hits': 'Times when vector memory retrieval returned any usable items',
        'mem_retrieval_fallback': 'Times when memory retrieval fell back due to empty/low-score results',
        'feedback_total': 'Total number of feedback posts',
    }
    for k, v in counters.items():
        lines.append(f"# HELP cuddle_{k} {help_map.get(k, 'Counter ' + k)}")
        lines.append(f"# TYPE cuddle_{k} counter")
        g(f"cuddle_{k}", v)

    g("cuddle_uptime_seconds", metrics_uptime())
    g("cuddle_latency_ms_p95", int(p95) if p95 is not None else None)
    g("cuddle_latency_ms_avg", float(f"{lat_avg:.3f}") if lat_avg is not None else None)
    g("cuddle_mem_vector_score_avg", float(f"{vec_avg:.6f}") if vec_avg is not None else None)

    body = "\n".join(lines) + "\n"
    return Response(content=body, media_type="text/plain")


class FeedbackEvent(BaseModel):
    user_id: str
    feedback_type: str  # like|dislike|complete|skip|useful
    @model_validator(mode='after')
    def _check_after(self):
        if self.feedback_type not in _ALLOWED_FEEDBACK_TYPES:
            raise ValueError("invalid feedback_type")
        if self.score is not None and not (0.0 <= float(self.score) <= 1.0):
            raise ValueError("score out of range [0,1]")
        if self.comment is not None and len(self.comment) > _MAX_FEEDBACK_COMMENT_LEN:
            raise ValueError("comment too long")
        return self

    target_type: Optional[str] = None  # chat|plan|habit
    target_id: Optional[str] = None
    score: Optional[float] = None
    comment: Optional[str] = None
    timestamp: Optional[str] = None

    @classmethod
    def model_validate(cls, v):  # pydantic v2 path
        if v.feedback_type not in _ALLOWED_FEEDBACK_TYPES:
            raise ValueError("invalid feedback_type")
        if v.score is not None and not (0.0 <= float(v.score) <= 1.0):
            raise ValueError("score out of range [0,1]")
        if v.comment is not None and len(v.comment) > _MAX_FEEDBACK_COMMENT_LEN:
            raise ValueError("comment too long")
        return v


class FeedbackResponse(BaseModel):
    status: str = "success"
    data: Dict[str, Any] = {}

@app.post("/feedback", response_model=FeedbackResponse)
async def post_feedback(ev: FeedbackEvent):
    try:
        payload = ev.dict()
        if payload.get('timestamp') is None:
            payload['timestamp'] = datetime.now().isoformat(timespec='minutes')
        # metrics: feedback counters
        try:
            ft = payload.get('feedback_type') or 'unknown'
            metrics_inc('feedback_total', 1)
            metrics_inc(f'feedback_type_{ft}', 1)
        except Exception:
            pass

        insert_feedback(payload)
        return FeedbackResponse(status="success", data={"ok": True})
    except Exception as e:
        return FeedbackResponse(status="error", data={"ok": False, "message": str(e)})

@app.get("/feedback/stats/{user_id}", response_model=FeedbackResponse)
async def get_feedback_stats(user_id: str):
    try:
        stats = fetch_feedback_stats(user_id)
        return FeedbackResponse(status="success", data=stats)
    except Exception as e:
        return FeedbackResponse(status="error", data={"ok": False, "message": str(e)})


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
    """根据反馈更新推荐权重（占位，待完善）"""
    try:
        # 这里只做安全占位，避免未完成代码导致语法错误
        return
    except Exception:
        return
@app.post("/memory/upsert")
async def memory_upsert(req: MemoryUpsertRequest):
    """将事件批量写入SQLite与向量索引；失败时回退到缓存。"""
    try:
        # 先写入DB
        events = []
        texts: List[str] = []
        metas: List[Dict[str, Any]] = []
        for ev in req.events:
            ts = ev.timestamp or datetime.now().isoformat(timespec='minutes')
            payload = {
                "user_id": ev.user_id,
                "type": ev.type,
                "text": ev.text,
                "metadata": ev.metadata,
                "timestamp": ts,
            }
            events.append(payload)
            if ev.text:
                texts.append(ev.text)
                metas.append({"user_id": ev.user_id, "type": ev.type, "text": ev.text, "timestamp": ts})
        written = upsert_events(events)
        # 写向量索引（忽略错误，保持主流程）
        try:
            if texts:
                vs_add_texts(texts, metas)
        except Exception:
            pass
        # 同步写缓存（可选）
        try:
            cache = get_cache_manager()
            for p in events:
                key = f"memory:{p['user_id']}:{p['timestamp']}:{p['type']}"
                cache.set(key, p, ttl=86400 * 7)
        except Exception:
            pass
        return {"status": "success", "written": int(written)}
    except Exception:
        # 回退到缓存
        try:
            cache = get_cache_manager()
            count = 0
            for ev in req.events:
                ts = ev.timestamp or datetime.now().isoformat(timespec='minutes')
                key = f"memory:{ev.user_id}:{ts}:{ev.type}"
                payload = {
                    "user_id": ev.user_id,
                    "type": ev.type,
                    "text": ev.text,
                    "metadata": ev.metadata,
                    "timestamp": ts,
                }
                cache.set(key, payload, ttl=86400 * 30)
                count += 1
            return {"status": "success", "written": count}
        except Exception as e:
            return {"status": "error", "message": str(e)}

@app.post("/memory/query", response_model=MemoryQueryResponse)
async def memory_query(req: MemoryQueryRequest):
    """优先向量检索（当有查询文本时），否则按SQLite时间倒序；失败回退缓存。"""
    try:
        items: List[Dict[str, Any]] = []
        q = (req.query or "").strip()
        if q:
            try:
                # 先向量检索（按 user_id 过滤），再按相似度阈值过滤，避免误召回
                vs_items = vs_query(q, top_k=req.top_k, filters={"user_id": req.user_id})
                threshold = float(os.getenv('MEMORY_VECTOR_SCORE_THRESHOLD', '0.6'))
                filtered = [it for it in vs_items if float(it.get('score', 0.0)) >= threshold]
                if filtered:
                    items = [
                        {"user_id": it.get("user_id"), "type": it.get("type"), "text": it.get("text"), "metadata": {}, "timestamp": it.get("timestamp")}
                        for it in filtered
                    ]
            except Exception:
                items = []
        if not items:
            items = query_events(req.user_id, req.query, req.top_k)
        return MemoryQueryResponse(status="success", data=items)
    except Exception:
        # 回退到缓存回扫
        cache = get_cache_manager()
        from datetime import timedelta
        now = datetime.now()
        results: List[Dict[str, Any]] = []
        q = (req.query or "").strip()
        days = 7
        for i in range(days):
            day = (now - timedelta(days=i)).strftime('%Y-%m-%d')
            for t in ["chat", "mood", "task", "session", "preference", "generic"]:
                for hh in range(0, 24):
                    for mm in (0, 15, 30, 45):
                        ts = f"{day}T{hh:02d}:{mm:02d}"
                        key = f"memory:{req.user_id}:{ts}:{t}"
                        item = cache.get(key)
                        if item:
                            if not q or (isinstance(item.get("text"), str) and q in item["text"]):
                                results.append(item)
                                if len(results) >= req.top_k:
                                    return MemoryQueryResponse(status="success", data=results)
        return MemoryQueryResponse(status="success", data=results)
    except Exception:
        return MemoryQueryResponse(status="error", data=[])



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

@app.post("/goals/extract")
async def extract_goals(payload: Dict):
    """从文本中提取可提醒的个人目标，落库并返回结构化目标"""
    try:
        text = (payload.get('text') or '').strip()
        user_id = payload.get('user_id') or 'anonymous'
        if not text:
            return {"status": "success", "data": []}
        # 复用聊天中的启发式
        goal_keywords = ["我希望", "我想要", "我打算", "我计划", "希望我能", "想要克服", "我要改进"]
        goals: List[GoalMemory] = []
        if any(k in text for k in goal_keywords):
            normalized = text
            for k in goal_keywords:
                normalized = normalized.replace(k, '')
            content = normalized.strip().strip('。.!?')
            if content:
                gm = GoalMemory(user_id=user_id, goal_type='personal_goal', content=content, extracted_at=datetime.now().isoformat(timespec='minutes'))
                goals.append(gm)
        # 落库
        if goals:
            events = []
            from .db import upsert_events
            for g in goals:
                events.append({
                    'user_id': g.user_id,
                    'type': 'goal',
                    'text': g.content,
                    'metadata': {'goal_type': g.goal_type, 'extracted_at': g.extracted_at},
                    'timestamp': g.extracted_at,
                })
            upsert_events(events)
        return {"status": "success", "data": [g.dict() for g in goals]}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/reminders/suggestions/{user_id}")
async def reminder_suggestions(user_id: str, limit: int = 5):
    """基于目标类记忆生成鼓励性提醒文案"""
    try:
        # 简化：从最近目标事件生成建议，同时融合最近心情、时间段进行个性化
        from .db import fetch_user_events
        events = fetch_user_events(user_id, since_days=90, limit=300)
        goals = [ev for ev in events if (ev.get('type') == 'goal' and ev.get('text'))]
        recent_moods = [ev for ev in events if ev.get('type') == 'mood']
        # 判断白天/晚上
        hour = datetime.now().hour
        daypart = 'morning' if 5 <= hour < 12 else ('afternoon' if 12 <= hour < 18 else 'night')
        # 最近心情偏向
        mood_bias = 'neutral'
        try:
            last_moods = recent_moods[-5:]
            mood_text = ' '.join((m.get('text') or '') for m in last_moods)
            if any(k in mood_text for k in ['开心','放松','满足','高兴','great','love']):
                mood_bias = 'positive'
            elif any(k in mood_text for k in ['难过','焦虑','压力','累','糟糕','sad','angry']):
                mood_bias = 'negative'
        except Exception:
            pass
        items: List[ReminderSuggestion] = []
        for g in goals[:max(1, limit)]:
            content = g.get('text')
            # 模板池（可迁移到 LLM）
            base = [
                f"{content}这件事，我相信你做得到。今天不需要完美，只要迈出小小一步。",
                f"关于 {content}，请温柔地对待自己，一点点来就很好。",
            ]
            if daypart == 'morning':
                base.append(f"新的一天开始啦，{content} 也许可以安排个5分钟小尝试～")
            elif daypart == 'night':
                base.append(f"今天辛苦了，{content} 明天再继续也很好，先给自己一点休息～")
            if mood_bias == 'negative':
                base.append(f"当感觉不太好时，{content} 可以分解到更小的一步，给自己一个容易完成的小目标。")
            elif mood_bias == 'positive':
                base.append(f"状态不错，不妨在 {content} 上加一个小挑战，积累一点点成就感！")
            items.append(ReminderSuggestion(text=base[0]))
        return {"status": "success", "data": [i.dict() for i in items]}
    except Exception as e:
        return {"status": "error", "message": str(e)}

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


