from typing import Dict, List, Optional
from datetime import datetime, timedelta
import json
from .models import get_cache_manager

class RecommendationAnalytics:
    """推荐系统分析器"""
    
    def __init__(self):
        self.cache_manager = get_cache_manager()
    
    def log_recommendation(self, user_id: str, recommendations: List[Dict], context: Dict):
        """记录推荐结果"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "user_id": user_id,
            "recommendations": recommendations,
            "context": context,
            "feedback": None  # 待用户反馈
        }
        
        key = f"rec_log:{user_id}:{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.cache_manager.set(key, log_entry, ttl=86400 * 30)  # 30天
    
    def log_user_feedback(self, user_id: str, recommendation_id: str, feedback: Dict):
        """记录用户反馈"""
        feedback_entry = {
            "timestamp": datetime.now().isoformat(),
            "user_id": user_id,
            "recommendation_id": recommendation_id,
            "feedback": feedback
        }
        
        key = f"feedback:{user_id}:{recommendation_id}"
        self.cache_manager.set(key, feedback_entry, ttl=86400 * 90)  # 90天
    
    def get_recommendation_stats(self, days: int = 7) -> Dict:
        """获取推荐统计"""
        # 这里简化实现，实际应该从数据库查询
        return {
            "total_recommendations": 0,
            "user_engagement_rate": 0.0,
            "avg_rating": 0.0,
            "popular_categories": [],
            "improvement_suggestions": []
        }

class ABTestManager:
    """A/B测试管理器"""
    
    def __init__(self):
        self.cache_manager = get_cache_manager()
        self.active_tests = {
            "recommendation_style": {
                "variants": ["warm", "direct", "playful"],
                "weights": [0.4, 0.3, 0.3],
                "metrics": ["engagement_rate", "completion_rate", "user_satisfaction"]
            },
            "gift_count": {
                "variants": [6, 8, 10],
                "weights": [0.3, 0.4, 0.3],
                "metrics": ["choice_paralysis", "completion_rate"]
            }
        }
    
    def assign_variant(self, user_id: str, test_name: str) -> str:
        """为用户分配测试变体"""
        import hashlib
        import random
        
        # 基于用户ID的一致性哈希
        hash_input = f"{user_id}_{test_name}".encode()
        hash_value = int(hashlib.md5(hash_input).hexdigest(), 16)
        
        if test_name not in self.active_tests:
            return "default"
        
        test_config = self.active_tests[test_name]
        variants = test_config["variants"]
        weights = test_config["weights"]
        
        # 根据权重选择变体
        random.seed(hash_value)
        variant = random.choices(variants, weights=weights)[0]
        
        # 记录分配
        assignment_key = f"ab_assignment:{user_id}:{test_name}"
        self.cache_manager.set(assignment_key, {
            "variant": variant,
            "assigned_at": datetime.now().isoformat()
        }, ttl=86400 * 30)
        
        return str(variant)
    
    def log_test_event(self, user_id: str, test_name: str, event_type: str, data: Dict):
        """记录测试事件"""
        event_entry = {
            "timestamp": datetime.now().isoformat(),
            "user_id": user_id,
            "test_name": test_name,
            "event_type": event_type,
            "data": data
        }
        
        key = f"ab_event:{test_name}:{user_id}:{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.cache_manager.set(key, event_entry, ttl=86400 * 90)

def apply_recommendation_style(gifts: List[Dict], style: str) -> List[Dict]:
    """应用不同的推荐风格"""
    if style == "warm":
        # 温暖风格：更多情感化描述
        for gift in gifts:
            if "温暖" not in gift["description"]:
                gift["description"] = f"温暖提醒：{gift['description']}"
    elif style == "direct":
        # 直接风格：简洁明了
        for gift in gifts:
            gift["description"] = gift["title"]
    elif style == "playful":
        # 俏皮风格：添加可爱元素
        playful_prefixes = ["小贴士", "今日推荐", "试试看"]
        for i, gift in enumerate(gifts):
            prefix = playful_prefixes[i % len(playful_prefixes)]
            gift["description"] = f"{prefix}：{gift['description']} ✨"
    
    return gifts

# 全局实例
analytics = RecommendationAnalytics()
ab_test_manager = ABTestManager()
