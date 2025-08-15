import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime, timedelta
import json
import pickle
import threading
from collections import deque, defaultdict
from sklearn.linear_model import SGDRegressor, SGDClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error, accuracy_score
import redis
from .models import get_cache_manager

class OnlineLearningEngine:
    """在线学习引擎 - 实时更新模型"""
    
    def __init__(self, model_type: str = "regression"):
        self.model_type = model_type
        self.cache_manager = get_cache_manager()
        
        # 在线学习模型
        if model_type == "regression":
            self.model = SGDRegressor(
                learning_rate='adaptive',
                eta0=0.01,
                random_state=42,
                warm_start=True
            )
        else:
            self.model = SGDClassifier(
                learning_rate='adaptive',
                eta0=0.01,
                random_state=42,
                warm_start=True
            )
        
        # 特征缩放器
        self.scaler = StandardScaler()
        self.scaler_fitted = False
        
        # 模型状态
        self.is_initialized = False
        self.sample_count = 0
        self.performance_history = deque(maxlen=100)
        
        # 实时学习缓冲区
        self.learning_buffer = deque(maxlen=50)
        self.buffer_lock = threading.Lock()
        
        # 模型版本管理
        self.model_version = "1.0.0"
        self.last_update_time = datetime.now()
        
        # 加载已保存的模型
        self._load_model()

        # 如果没有加载到模型，尝试用合成数据初始化
        if not self.is_initialized:
            self._initialize_with_synthetic_data()

    def _initialize_with_synthetic_data(self):
        """使用合成数据初始化模型"""
        try:
            print(f"Initializing {self.model_type} model with synthetic data...")

            # 生成合成训练数据
            if self.model_type == "regression":
                # 心情预测：基于时间、天气、活动类型等特征
                synthetic_data = self._generate_mood_synthetic_data()
            else:
                # 分类任务：用户行为分类
                synthetic_data = self._generate_classification_synthetic_data()

            if synthetic_data:
                X, y = synthetic_data

                # 特征缩放
                X_scaled = self.scaler.fit_transform(X)
                self.scaler_fitted = True

                # 训练模型
                self.model.fit(X_scaled, y)
                self.is_initialized = True
                self.sample_count = len(X)
                self.last_update_time = datetime.now()

                # 评估性能
                self._evaluate_performance(X_scaled, y)

                # 保存模型
                self._save_model()

                print(f"Model initialized with {len(X)} synthetic samples")

        except Exception as e:
            print(f"Synthetic data initialization failed: {e}")

    def _generate_mood_synthetic_data(self):
        """生成心情预测的合成数据"""
        import random

        X = []
        y = []

        # 生成100个合成样本
        for _ in range(100):
            # 特征：[时间(0-23), 天气(0-100), 活动类型(0-10), 社交程度(0-5), 睡眠质量(1-5)]
            hour = random.randint(0, 23)
            weather = random.randint(0, 100)
            activity_type = random.randint(0, 10)
            social_level = random.randint(0, 5)
            sleep_quality = random.randint(1, 5)

            features = [hour, weather, activity_type, social_level, sleep_quality]

            # 基于特征生成目标心情分数 (1-5)
            mood_score = 3.0  # 基础分数

            # 时间影响
            if 6 <= hour <= 10 or 18 <= hour <= 22:  # 早晨和傍晚
                mood_score += 0.5
            elif 0 <= hour <= 5:  # 深夜
                mood_score -= 0.8

            # 天气影响
            if weather >= 80:  # 好天气
                mood_score += 0.7
            elif weather <= 30:  # 坏天气
                mood_score -= 0.5

            # 活动类型影响
            if activity_type in [1, 2, 7]:  # 运动、创作、社交
                mood_score += 0.6
            elif activity_type in [8, 9]:  # 工作、学习
                mood_score -= 0.2

            # 社交程度影响
            mood_score += social_level * 0.2

            # 睡眠质量影响
            mood_score += (sleep_quality - 3) * 0.4

            # 添加随机噪声
            mood_score += random.uniform(-0.3, 0.3)

            # 限制范围
            mood_score = max(1.0, min(5.0, mood_score))

            X.append(features)
            y.append(mood_score)

        return np.array(X), np.array(y)

    def _generate_classification_synthetic_data(self):
        """生成分类任务的合成数据"""
        import random

        X = []
        y = []

        # 生成100个合成样本
        for _ in range(100):
            # 特征：[参与度, 完成率, 反馈分数, 使用时长, 重复使用]
            engagement = random.uniform(0, 1)
            completion_rate = random.uniform(0, 1)
            feedback_score = random.uniform(1, 5)
            usage_duration = random.uniform(0, 60)  # 分钟
            repeat_usage = random.randint(0, 1)

            features = [engagement, completion_rate, feedback_score, usage_duration, repeat_usage]

            # 基于特征生成分类标签 (0: 不喜欢, 1: 一般, 2: 喜欢)
            score = 0

            if engagement > 0.7:
                score += 1
            if completion_rate > 0.8:
                score += 1
            if feedback_score > 3.5:
                score += 1
            if usage_duration > 10:
                score += 1
            if repeat_usage:
                score += 1

            # 转换为分类标签
            if score >= 4:
                label = 2  # 喜欢
            elif score >= 2:
                label = 1  # 一般
            else:
                label = 0  # 不喜欢

            X.append(features)
            y.append(label)

        return np.array(X), np.array(y)

    def add_training_sample(self, features: List[float], target: float,
                          user_id: str = None, weight: float = 1.0):
        """添加训练样本到缓冲区"""
        with self.buffer_lock:
            sample = {
                'features': features,
                'target': target,
                'user_id': user_id,
                'weight': weight,
                'timestamp': datetime.now().isoformat()
            }
            self.learning_buffer.append(sample)
            
            # 当缓冲区达到一定大小时触发学习
            if len(self.learning_buffer) >= 10:
                self._trigger_incremental_learning()
    
    def _trigger_incremental_learning(self):
        """触发增量学习"""
        try:
            # 准备训练数据
            features_batch = []
            targets_batch = []
            weights_batch = []
            
            # 从缓冲区获取样本
            samples_to_process = list(self.learning_buffer)
            self.learning_buffer.clear()
            
            for sample in samples_to_process:
                features_batch.append(sample['features'])
                targets_batch.append(sample['target'])
                weights_batch.append(sample['weight'])
            
            if not features_batch:
                return
            
            # 转换为numpy数组
            X = np.array(features_batch)
            y = np.array(targets_batch)
            sample_weights = np.array(weights_batch)
            
            # 特征缩放
            if not self.scaler_fitted:
                X_scaled = self.scaler.fit_transform(X)
                self.scaler_fitted = True
            else:
                # 增量更新缩放器
                self.scaler.partial_fit(X)
                X_scaled = self.scaler.transform(X)
            
            # 增量学习
            if not self.is_initialized:
                # 首次训练
                self.model.fit(X_scaled, y, sample_weight=sample_weights)
                self.is_initialized = True
            else:
                # 增量更新
                self.model.partial_fit(X_scaled, y, sample_weight=sample_weights)
            
            # 更新统计信息
            self.sample_count += len(features_batch)
            self.last_update_time = datetime.now()
            
            # 评估模型性能
            self._evaluate_performance(X_scaled, y)
            
            # 保存模型
            self._save_model()
            
            print(f"Incremental learning completed: {len(features_batch)} samples processed")
            
        except Exception as e:
            print(f"Incremental learning failed: {e}")
    
    def predict(self, features: List[float]) -> Tuple[float, float]:
        """预测并返回结果和置信度"""
        if not self.is_initialized:
            return 3.0, 0.5  # 默认预测
        
        try:
            X = np.array([features])
            if self.scaler_fitted:
                X_scaled = self.scaler.transform(X)
            else:
                X_scaled = X
            
            prediction = self.model.predict(X_scaled)[0]
            
            # 计算置信度（基于历史性能）
            confidence = self._calculate_confidence()
            
            return float(prediction), float(confidence)
            
        except Exception as e:
            print(f"Prediction failed: {e}")
            return 3.0, 0.3
    
    def _evaluate_performance(self, X: np.ndarray, y: np.ndarray):
        """评估模型性能"""
        try:
            predictions = self.model.predict(X)
            
            if self.model_type == "regression":
                mse = mean_squared_error(y, predictions)
                performance = {"mse": mse, "timestamp": datetime.now().isoformat()}
            else:
                accuracy = accuracy_score(y, predictions)
                performance = {"accuracy": accuracy, "timestamp": datetime.now().isoformat()}
            
            self.performance_history.append(performance)
            
        except Exception as e:
            print(f"Performance evaluation failed: {e}")
    
    def _calculate_confidence(self) -> float:
        """计算预测置信度"""
        if not self.performance_history:
            return 0.5
        
        # 基于最近的性能历史计算置信度
        recent_performances = list(self.performance_history)[-10:]
        
        if self.model_type == "regression":
            # 对于回归，基于MSE计算置信度
            mse_values = [p["mse"] for p in recent_performances]
            avg_mse = np.mean(mse_values)
            confidence = max(0.1, min(0.95, 1.0 / (1.0 + avg_mse)))
        else:
            # 对于分类，基于准确率计算置信度
            acc_values = [p["accuracy"] for p in recent_performances]
            confidence = np.mean(acc_values)
        
        return confidence
    
    def _save_model(self):
        """保存模型到缓存"""
        try:
            model_data = {
                'model': pickle.dumps(self.model),
                'scaler': pickle.dumps(self.scaler),
                'scaler_fitted': self.scaler_fitted,
                'is_initialized': self.is_initialized,
                'sample_count': self.sample_count,
                'model_version': self.model_version,
                'last_update_time': self.last_update_time.isoformat(),
                'performance_history': list(self.performance_history)
            }
            
            cache_key = f"online_model:{self.model_type}"
            self.cache_manager.set(cache_key, model_data, ttl=86400 * 7)  # 7天
            
        except Exception as e:
            print(f"Model saving failed: {e}")
    
    def _load_model(self):
        """从缓存加载模型"""
        try:
            cache_key = f"online_model:{self.model_type}"
            model_data = self.cache_manager.get(cache_key)
            
            if model_data:
                self.model = pickle.loads(model_data['model'])
                self.scaler = pickle.loads(model_data['scaler'])
                self.scaler_fitted = model_data['scaler_fitted']
                self.is_initialized = model_data['is_initialized']
                self.sample_count = model_data['sample_count']
                self.model_version = model_data['model_version']
                self.last_update_time = datetime.fromisoformat(model_data['last_update_time'])
                self.performance_history = deque(model_data['performance_history'], maxlen=100)
                
                print(f"Model loaded: {self.sample_count} samples, version {self.model_version}")
            
        except Exception as e:
            print(f"Model loading failed: {e}")
    
    def get_model_info(self) -> Dict:
        """获取模型信息"""
        return {
            'model_type': self.model_type,
            'is_initialized': self.is_initialized,
            'sample_count': self.sample_count,
            'model_version': self.model_version,
            'last_update_time': self.last_update_time.isoformat(),
            'buffer_size': len(self.learning_buffer),
            'performance_history_size': len(self.performance_history),
            'latest_performance': list(self.performance_history)[-1] if self.performance_history else None
        }

class AdaptiveRecommendationEngine:
    """自适应推荐引擎"""
    
    def __init__(self):
        self.cache_manager = get_cache_manager()
        
        # 多个在线学习模型
        self.mood_predictor = OnlineLearningEngine("regression")
        self.engagement_predictor = OnlineLearningEngine("regression")
        self.satisfaction_predictor = OnlineLearningEngine("regression")
        
        # 用户偏好学习
        self.user_preferences = defaultdict(lambda: {
            'category_weights': defaultdict(float),
            'time_preferences': defaultdict(float),
            'difficulty_preference': 0.5,
            'social_preference': 0.5,
            'last_updated': datetime.now()
        })
        
        # 推荐策略权重
        self.strategy_weights = {
            'mood_based': 0.3,
            'engagement_based': 0.25,
            'satisfaction_based': 0.25,
            'diversity': 0.2
        }
        
        self._load_user_preferences()
    
    def update_user_feedback(self, user_id: str, recommendation_id: str, 
                           feedback: Dict[str, Any]):
        """更新用户反馈并触发学习"""
        try:
            # 提取特征
            features = self._extract_recommendation_features(feedback)
            
            # 更新不同的预测模型
            if 'mood_after' in feedback and 'mood_before' in feedback:
                mood_improvement = feedback['mood_after'] - feedback['mood_before']
                self.mood_predictor.add_training_sample(
                    features, mood_improvement, user_id, weight=1.0
                )
            
            if 'engagement_score' in feedback:
                self.engagement_predictor.add_training_sample(
                    features, feedback['engagement_score'], user_id, weight=1.0
                )
            
            if 'satisfaction_rating' in feedback:
                self.satisfaction_predictor.add_training_sample(
                    features, feedback['satisfaction_rating'], user_id, weight=1.0
                )
            
            # 更新用户偏好
            self._update_user_preferences(user_id, feedback)
            
        except Exception as e:
            print(f"Feedback update failed: {e}")
    
    def _extract_recommendation_features(self, feedback: Dict) -> List[float]:
        """从反馈中提取特征"""
        features = [
            feedback.get('hour_of_day', 12),
            feedback.get('day_of_week', 1),
            feedback.get('weather_score', 3),
            feedback.get('current_mood', 3),
            feedback.get('stress_level', 3),
            feedback.get('energy_level', 3),
            feedback.get('social_context', 0),
            feedback.get('task_difficulty', 0.5),
            feedback.get('task_duration', 15),
            feedback.get('category_preference', 0.5)
        ]
        return features
    
    def _update_user_preferences(self, user_id: str, feedback: Dict):
        """更新用户偏好"""
        prefs = self.user_preferences[user_id]
        
        # 更新分类偏好
        if 'category' in feedback and 'satisfaction_rating' in feedback:
            category = feedback['category']
            rating = feedback['satisfaction_rating']
            
            # 使用指数移动平均更新偏好
            alpha = 0.1
            current_weight = prefs['category_weights'][category]
            prefs['category_weights'][category] = (1 - alpha) * current_weight + alpha * rating
        
        # 更新时间偏好
        if 'hour_of_day' in feedback and 'engagement_score' in feedback:
            hour = feedback['hour_of_day']
            engagement = feedback['engagement_score']
            
            alpha = 0.1
            current_pref = prefs['time_preferences'][hour]
            prefs['time_preferences'][hour] = (1 - alpha) * current_pref + alpha * engagement
        
        # 更新难度偏好
        if 'task_difficulty' in feedback and 'satisfaction_rating' in feedback:
            difficulty = feedback['task_difficulty']
            rating = feedback['satisfaction_rating']
            
            if rating > 3:  # 满意的任务
                alpha = 0.05
                prefs['difficulty_preference'] = (1 - alpha) * prefs['difficulty_preference'] + alpha * difficulty
        
        prefs['last_updated'] = datetime.now()
        self._save_user_preferences()
    
    def generate_adaptive_recommendations(self, user_id: str, context: Dict, 
                                        candidate_tasks: List[Dict]) -> List[Dict]:
        """生成自适应推荐"""
        try:
            scored_tasks = []
            user_prefs = self.user_preferences[user_id]
            
            for task in candidate_tasks:
                # 构建任务特征
                task_features = self._build_task_features(task, context, user_prefs)
                
                # 多模型预测
                mood_score, mood_conf = self.mood_predictor.predict(task_features)
                engagement_score, eng_conf = self.engagement_predictor.predict(task_features)
                satisfaction_score, sat_conf = self.satisfaction_predictor.predict(task_features)
                
                # 计算综合分数
                total_score = (
                    self.strategy_weights['mood_based'] * mood_score * mood_conf +
                    self.strategy_weights['engagement_based'] * engagement_score * eng_conf +
                    self.strategy_weights['satisfaction_based'] * satisfaction_score * sat_conf +
                    self.strategy_weights['diversity'] * self._calculate_diversity_score(task, user_id)
                )
                
                # 应用用户偏好
                preference_boost = self._calculate_preference_boost(task, user_prefs, context)
                final_score = total_score * (1 + preference_boost)
                
                scored_tasks.append({
                    **task,
                    'adaptive_score': final_score,
                    'mood_prediction': mood_score,
                    'engagement_prediction': engagement_score,
                    'satisfaction_prediction': satisfaction_score,
                    'confidence': (mood_conf + eng_conf + sat_conf) / 3
                })
            
            # 排序并返回
            scored_tasks.sort(key=lambda x: x['adaptive_score'], reverse=True)
            return scored_tasks
            
        except Exception as e:
            print(f"Adaptive recommendation failed: {e}")
            return candidate_tasks
    
    def _build_task_features(self, task: Dict, context: Dict, user_prefs: Dict) -> List[float]:
        """构建任务特征向量"""
        features = [
            context.get('hour_of_day', 12),
            context.get('day_of_week', 1),
            context.get('weather_score', 3),
            context.get('current_mood', 3),
            context.get('stress_level', 3),
            context.get('energy_level', 3),
            context.get('social_context', 0),
            task.get('difficulty', 0.5),
            task.get('estimated_duration', 15),
            user_prefs['category_weights'].get(task.get('category', ''), 0.5)
        ]
        return features
    
    def _calculate_diversity_score(self, task: Dict, user_id: str) -> float:
        """计算多样性分数"""
        # 简化实现：基于最近推荐的任务类型计算多样性
        recent_categories = self._get_recent_categories(user_id)
        task_category = task.get('category', '')
        
        if task_category in recent_categories:
            return 0.3  # 降低重复类型的分数
        else:
            return 1.0  # 提升新类型的分数
    
    def _calculate_preference_boost(self, task: Dict, user_prefs: Dict, context: Dict) -> float:
        """计算用户偏好加成"""
        boost = 0.0
        
        # 分类偏好加成
        category = task.get('category', '')
        category_weight = user_prefs['category_weights'].get(category, 0.5)
        boost += (category_weight - 0.5) * 0.2
        
        # 时间偏好加成
        hour = context.get('hour_of_day', 12)
        time_pref = user_prefs['time_preferences'].get(hour, 0.5)
        boost += (time_pref - 0.5) * 0.1
        
        # 难度偏好加成
        task_difficulty = task.get('difficulty', 0.5)
        difficulty_pref = user_prefs['difficulty_preference']
        difficulty_match = 1 - abs(task_difficulty - difficulty_pref)
        boost += (difficulty_match - 0.5) * 0.1
        
        return max(-0.3, min(0.3, boost))  # 限制加成范围
    
    def _get_recent_categories(self, user_id: str) -> List[str]:
        """获取用户最近的任务类型"""
        cache_key = f"recent_categories:{user_id}"
        recent = self.cache_manager.get(cache_key)
        return recent or []
    
    def _save_user_preferences(self):
        """保存用户偏好"""
        try:
            # 转换为可序列化的格式
            serializable_prefs = {}
            for user_id, prefs in self.user_preferences.items():
                serializable_prefs[user_id] = {
                    'category_weights': dict(prefs['category_weights']),
                    'time_preferences': dict(prefs['time_preferences']),
                    'difficulty_preference': prefs['difficulty_preference'],
                    'social_preference': prefs['social_preference'],
                    'last_updated': prefs['last_updated'].isoformat()
                }
            
            cache_key = "user_preferences"
            self.cache_manager.set(cache_key, serializable_prefs, ttl=86400 * 30)
            
        except Exception as e:
            print(f"User preferences saving failed: {e}")
    
    def _load_user_preferences(self):
        """加载用户偏好"""
        try:
            cache_key = "user_preferences"
            prefs_data = self.cache_manager.get(cache_key)
            
            if prefs_data:
                for user_id, prefs in prefs_data.items():
                    self.user_preferences[user_id] = {
                        'category_weights': defaultdict(float, prefs['category_weights']),
                        'time_preferences': defaultdict(float, prefs['time_preferences']),
                        'difficulty_preference': prefs['difficulty_preference'],
                        'social_preference': prefs['social_preference'],
                        'last_updated': datetime.fromisoformat(prefs['last_updated'])
                    }
                
                print(f"User preferences loaded for {len(prefs_data)} users")
            
        except Exception as e:
            print(f"User preferences loading failed: {e}")
    
    def get_system_stats(self) -> Dict:
        """获取系统统计信息"""
        return {
            'mood_predictor': self.mood_predictor.get_model_info(),
            'engagement_predictor': self.engagement_predictor.get_model_info(),
            'satisfaction_predictor': self.satisfaction_predictor.get_model_info(),
            'total_users': len(self.user_preferences),
            'strategy_weights': self.strategy_weights
        }

# 全局实例
adaptive_engine = AdaptiveRecommendationEngine()
