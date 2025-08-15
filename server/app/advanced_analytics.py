import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score
import json
from .models import get_cache_manager

class UserBehaviorAnalyzer:
    """用户行为分析器"""
    
    def __init__(self):
        self.cache_manager = get_cache_manager()
        self.scaler = StandardScaler()
        
    def analyze_user_clusters(self, user_data: List[Dict]) -> Dict:
        """用户聚类分析"""
        if len(user_data) < 10:
            return {"error": "数据量不足，需要至少10个用户"}
        
        # 特征工程
        features = self._extract_user_features(user_data)
        if len(features) == 0:
            return {"error": "无法提取有效特征"}
        
        # 数据标准化
        features_scaled = self.scaler.fit_transform(features)
        
        # K-means聚类
        optimal_k = self._find_optimal_clusters(features_scaled)
        kmeans = KMeans(n_clusters=optimal_k, random_state=42)
        cluster_labels = kmeans.fit_predict(features_scaled)
        
        # PCA降维用于可视化
        pca = PCA(n_components=2)
        features_2d = pca.fit_transform(features_scaled)
        
        # 分析每个聚类的特征
        cluster_analysis = self._analyze_clusters(user_data, cluster_labels, features)
        
        return {
            "optimal_clusters": optimal_k,
            "cluster_labels": cluster_labels.tolist(),
            "cluster_analysis": cluster_analysis,
            "pca_coordinates": features_2d.tolist(),
            "feature_importance": pca.explained_variance_ratio_.tolist()
        }
    
    def _extract_user_features(self, user_data: List[Dict]) -> np.ndarray:
        """提取用户特征"""
        features = []
        
        for user in user_data:
            feature_vector = [
                user.get('total_tasks_completed', 0),
                user.get('avg_session_duration', 0),
                user.get('days_active', 0),
                user.get('max_streak', 0),
                user.get('avg_mood_score', 0),
                user.get('total_gifts_received', 0),
                user.get('completion_rate', 0),
                len(user.get('preferred_categories', [])),
                user.get('evening_activity_ratio', 0),
                user.get('weekend_activity_ratio', 0),
            ]
            features.append(feature_vector)
        
        return np.array(features)
    
    def _find_optimal_clusters(self, features: np.ndarray) -> int:
        """使用肘部法则找到最优聚类数"""
        max_k = min(10, len(features) // 2)
        inertias = []
        
        for k in range(2, max_k + 1):
            kmeans = KMeans(n_clusters=k, random_state=42)
            kmeans.fit(features)
            inertias.append(kmeans.inertia_)
        
        # 简化的肘部检测
        if len(inertias) >= 3:
            diffs = np.diff(inertias)
            second_diffs = np.diff(diffs)
            optimal_k = np.argmax(second_diffs) + 3  # +3 because we start from k=2
        else:
            optimal_k = 3
        
        return min(optimal_k, max_k)
    
    def _analyze_clusters(self, user_data: List[Dict], labels: np.ndarray, features: np.ndarray) -> Dict:
        """分析每个聚类的特征"""
        cluster_analysis = {}
        unique_labels = np.unique(labels)
        
        feature_names = [
            'total_tasks_completed', 'avg_session_duration', 'days_active',
            'max_streak', 'avg_mood_score', 'total_gifts_received',
            'completion_rate', 'category_diversity', 'evening_activity_ratio',
            'weekend_activity_ratio'
        ]
        
        for label in unique_labels:
            cluster_mask = labels == label
            cluster_features = features[cluster_mask]
            cluster_users = [user_data[i] for i in range(len(user_data)) if cluster_mask[i]]
            
            # 计算聚类统计
            cluster_stats = {}
            for i, feature_name in enumerate(feature_names):
                cluster_stats[feature_name] = {
                    'mean': float(np.mean(cluster_features[:, i])),
                    'std': float(np.std(cluster_features[:, i])),
                    'min': float(np.min(cluster_features[:, i])),
                    'max': float(np.max(cluster_features[:, i]))
                }
            
            # 聚类标签
            cluster_label = self._generate_cluster_label(cluster_stats)
            
            cluster_analysis[f"cluster_{label}"] = {
                'label': cluster_label,
                'size': int(np.sum(cluster_mask)),
                'percentage': float(np.sum(cluster_mask) / len(labels) * 100),
                'stats': cluster_stats,
                'characteristics': self._describe_cluster(cluster_stats)
            }
        
        return cluster_analysis
    
    def _generate_cluster_label(self, stats: Dict) -> str:
        """为聚类生成描述性标签"""
        completion_rate = stats['completion_rate']['mean']
        streak = stats['max_streak']['mean']
        activity = stats['days_active']['mean']
        
        if completion_rate > 0.8 and streak > 14:
            return "高度活跃用户"
        elif completion_rate > 0.6 and activity > 30:
            return "稳定用户"
        elif streak < 3 and activity < 7:
            return "新手用户"
        elif completion_rate < 0.3:
            return "低活跃用户"
        else:
            return "普通用户"
    
    def _describe_cluster(self, stats: Dict) -> List[str]:
        """描述聚类特征"""
        characteristics = []
        
        if stats['completion_rate']['mean'] > 0.8:
            characteristics.append("任务完成率很高")
        elif stats['completion_rate']['mean'] < 0.3:
            characteristics.append("任务完成率较低")
        
        if stats['max_streak']['mean'] > 21:
            characteristics.append("具有很强的坚持能力")
        elif stats['max_streak']['mean'] < 3:
            characteristics.append("坚持能力有待提升")
        
        if stats['avg_mood_score']['mean'] > 4:
            characteristics.append("整体心情较好")
        elif stats['avg_mood_score']['mean'] < 3:
            characteristics.append("心情状态需要关注")
        
        if stats['evening_activity_ratio']['mean'] > 0.6:
            characteristics.append("偏好晚间活动")
        
        if stats['weekend_activity_ratio']['mean'] > 0.4:
            characteristics.append("周末活跃度高")
        
        return characteristics

class MoodPredictor:
    """心情预测模型"""
    
    def __init__(self):
        self.model = RandomForestRegressor(n_estimators=100, random_state=42)
        self.is_trained = False
        self.feature_names = [
            'hour_of_day', 'day_of_week', 'weather_score',
            'tasks_completed_today', 'recent_mood_avg',
            'streak_length', 'sleep_quality', 'social_interaction'
        ]
    
    def train(self, training_data: List[Dict]) -> Dict:
        """训练心情预测模型"""
        if len(training_data) < 50:
            return {"error": "训练数据不足，需要至少50条记录"}
        
        # 特征工程
        X, y = self._prepare_training_data(training_data)
        
        if len(X) == 0:
            return {"error": "无法提取有效的训练特征"}
        
        # 训练模型
        self.model.fit(X, y)
        self.is_trained = True
        
        # 模型评估
        y_pred = self.model.predict(X)
        mse = mean_squared_error(y, y_pred)
        r2 = r2_score(y, y_pred)
        
        # 特征重要性
        feature_importance = dict(zip(self.feature_names, self.model.feature_importances_))
        
        return {
            "training_samples": len(X),
            "mse": float(mse),
            "r2_score": float(r2),
            "feature_importance": feature_importance,
            "model_status": "trained"
        }
    
    def predict_mood(self, user_context: Dict) -> Dict:
        """预测用户心情"""
        if not self.is_trained:
            return {"error": "模型尚未训练"}
        
        # 提取特征
        features = self._extract_prediction_features(user_context)
        
        # 预测
        predicted_mood = self.model.predict([features])[0]
        
        # 预测置信度（基于特征的标准差）
        confidence = self._calculate_confidence(features)
        
        # 生成建议
        suggestions = self._generate_mood_suggestions(predicted_mood, user_context)
        
        return {
            "predicted_mood": float(predicted_mood),
            "confidence": float(confidence),
            "mood_category": self._categorize_mood(predicted_mood),
            "suggestions": suggestions
        }
    
    def _prepare_training_data(self, data: List[Dict]) -> Tuple[np.ndarray, np.ndarray]:
        """准备训练数据"""
        X, y = [], []
        
        for record in data:
            features = self._extract_prediction_features(record)
            mood_score = record.get('mood_score', 3)  # 1-5分制
            
            if features is not None:
                X.append(features)
                y.append(mood_score)
        
        return np.array(X), np.array(y)
    
    def _extract_prediction_features(self, context: Dict) -> List[float]:
        """提取预测特征"""
        try:
            features = [
                context.get('hour_of_day', 12),
                context.get('day_of_week', 1),
                context.get('weather_score', 3),
                context.get('tasks_completed_today', 0),
                context.get('recent_mood_avg', 3),
                context.get('streak_length', 0),
                context.get('sleep_quality', 3),
                context.get('social_interaction', 0)
            ]
            return features
        except Exception:
            return None
    
    def _calculate_confidence(self, features: List[float]) -> float:
        """计算预测置信度"""
        # 简化的置信度计算
        # 实际应用中可以使用更复杂的方法
        return 0.75  # 固定置信度，实际应该基于模型不确定性
    
    def _categorize_mood(self, mood_score: float) -> str:
        """将心情分数转换为类别"""
        if mood_score >= 4.5:
            return "非常好"
        elif mood_score >= 3.5:
            return "较好"
        elif mood_score >= 2.5:
            return "一般"
        elif mood_score >= 1.5:
            return "较差"
        else:
            return "很差"
    
    def _generate_mood_suggestions(self, predicted_mood: float, context: Dict) -> List[str]:
        """基于预测心情生成建议"""
        suggestions = []
        
        if predicted_mood < 2.5:
            suggestions.extend([
                "建议进行一些放松活动",
                "可以尝试深呼吸或冥想",
                "考虑与朋友聊天或寻求支持"
            ])
        elif predicted_mood < 3.5:
            suggestions.extend([
                "适当的运动可能会有帮助",
                "尝试做一些喜欢的事情",
                "保持规律的作息"
            ])
        else:
            suggestions.extend([
                "保持当前的良好状态",
                "可以尝试一些新的挑战",
                "分享你的快乐给他人"
            ])
        
        return suggestions

# 全局实例
behavior_analyzer = UserBehaviorAnalyzer()
mood_predictor = MoodPredictor()
