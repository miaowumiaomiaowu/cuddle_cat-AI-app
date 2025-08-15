import os
import json
import torch
from typing import List, Dict, Optional, Tuple
from transformers import AutoTokenizer, AutoModel, pipeline
from sentence_transformers import SentenceTransformer
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
import redis
from datetime import datetime, timedelta

class EmotionAnalyzer:
    """增强的中文情感分析模型"""

    def __init__(self, model_name: str = "hfl/chinese-roberta-wwm-ext"):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Using device: {self.device}")

        # 支持多种模型配置
        self.model_configs = {
            "roberta": "hfl/chinese-roberta-wwm-ext",
            "bert": "bert-base-chinese",
            "macbert": "hfl/chinese-macbert-base",
            "electra": "hfl/chinese-electra-180g-base-discriminator"
        }

        self.sentiment_pipeline = None
        self.tokenizer = None
        self.model = None

        # 尝试加载主模型
        self._load_primary_model(model_name)

        # 如果主模型失败，尝试备用模型
        if self.sentiment_pipeline is None:
            self._load_fallback_models()

        # 增强的情感关键词字典
        self.emotion_keywords = {
            "happy": ["开心", "快乐", "兴奋", "愉快", "满足", "幸福", "高兴", "喜悦", "欢乐", "愉悦", "舒心", "畅快"],
            "sad": ["难过", "伤心", "沮丧", "失落", "悲伤", "郁闷", "忧伤", "哀伤", "痛苦", "心痛", "绝望"],
            "anxious": ["焦虑", "紧张", "担心", "不安", "恐惧", "害怕", "忧虑", "惊慌", "恐慌", "紧张不安"],
            "angry": ["生气", "愤怒", "烦躁", "恼火", "气愤", "暴躁", "愤慨", "恼怒", "火大", "抓狂"],
            "calm": ["平静", "放松", "安静", "淡定", "冷静", "宁静", "安详", "祥和", "悠然", "从容"],
            "tired": ["疲惫", "累", "困", "乏力", "疲劳", "疲倦", "劳累", "精疲力竭", "筋疲力尽"],
            "excited": ["激动", "兴奋", "亢奋", "热血", "振奋", "激昂", "热情", "狂热"],
            "confused": ["困惑", "迷茫", "不解", "疑惑", "茫然", "纠结", "矛盾", "犹豫"],
            "grateful": ["感谢", "感激", "感恩", "谢谢", "感动", "温暖", "暖心"],
            "lonely": ["孤独", "寂寞", "孤单", "独自", "一个人", "无聊", "空虚"]
        }

        # 情感强度词汇
        self.intensity_modifiers = {
            "very": ["非常", "特别", "极其", "超级", "十分", "相当", "格外"],
            "slightly": ["有点", "稍微", "略微", "一点", "些许", "轻微"],
            "extremely": ["极度", "极其", "超级", "非常非常", "特别特别"]
        }
    
    def analyze_emotion(self, text: str) -> Dict[str, float]:
        """分析文本情感"""
        if not text.strip():
            return {"neutral": 1.0}
            
        # 优先使用模型
        if self.sentiment_pipeline:
            try:
                result = self.sentiment_pipeline(text)
                # 转换为我们的格式
                label = result[0]['label'].lower()
                score = result[0]['score']
                
                # 映射标签
                emotion_map = {
                    'positive': 'happy',
                    'negative': 'sad',
                    'neutral': 'calm'
                }
                emotion = emotion_map.get(label, 'calm')
                return {emotion: score}
            except Exception as e:
                print(f"Model analysis failed: {e}")
        
        # 回退到关键词方法
        return self._keyword_analysis(text)
    
    def _keyword_analysis(self, text: str) -> Dict[str, float]:
        """基于关键词的情感分析"""
        text_lower = text.lower()
        scores = {}
        
        for emotion, keywords in self.emotion_keywords.items():
            score = sum(1 for keyword in keywords if keyword in text_lower)
            if score > 0:
                scores[emotion] = min(score / len(keywords), 1.0)
        
        if not scores:
            scores["neutral"] = 1.0
            
        return scores

    def _load_primary_model(self, model_name: str):
        """加载主要模型"""
        try:
            self.sentiment_pipeline = pipeline(
                "sentiment-analysis",
                model=model_name,
                device=0 if self.device == "cuda" else -1
            )
            print(f"Successfully loaded primary model: {model_name}")
        except Exception as e:
            print(f"Failed to load primary model {model_name}: {e}")

    def _load_fallback_models(self):
        """尝试加载备用模型"""
        for name, model_path in self.model_configs.items():
            try:
                self.sentiment_pipeline = pipeline(
                    "sentiment-analysis",
                    model=model_path,
                    device=0 if self.device == "cuda" else -1
                )
                print(f"Successfully loaded fallback model: {model_path}")
                break
            except Exception as e:
                print(f"Failed to load fallback model {model_path}: {e}")
                continue

    def analyze_emotion_advanced(self, text: str, context: Dict = None) -> Dict[str, float]:
        """高级情感分析，考虑上下文"""
        if not text.strip():
            return {"neutral": 1.0}

        # 基础情感分析
        base_emotions = self.analyze_emotion(text)

        # 上下文增强
        if context:
            base_emotions = self._enhance_with_context(base_emotions, context)

        # 强度分析
        intensity = self._analyze_intensity(text)

        # 应用强度调整
        enhanced_emotions = {}
        for emotion, score in base_emotions.items():
            enhanced_emotions[emotion] = min(score * intensity, 1.0)

        return enhanced_emotions

    def _enhance_with_context(self, emotions: Dict[str, float], context: Dict) -> Dict[str, float]:
        """基于上下文增强情感分析"""
        enhanced = emotions.copy()

        # 时间上下文
        if 'time_of_day' in context:
            hour = context['time_of_day']
            if 22 <= hour or hour <= 6:  # 深夜/凌晨
                enhanced['tired'] = enhanced.get('tired', 0) + 0.2
            elif 6 <= hour <= 9:  # 早晨
                enhanced['calm'] = enhanced.get('calm', 0) + 0.1

        # 天气上下文
        if 'weather' in context:
            weather = context['weather']
            if 'rain' in weather.lower():
                enhanced['sad'] = enhanced.get('sad', 0) + 0.1
            elif 'sunny' in weather.lower():
                enhanced['happy'] = enhanced.get('happy', 0) + 0.1

        # 历史情绪上下文
        if 'recent_emotions' in context:
            recent = context['recent_emotions']
            if len(recent) > 0:
                # 情绪惯性：最近的情绪会影响当前分析
                for emotion in recent[-3:]:  # 最近3次情绪
                    if emotion in enhanced:
                        enhanced[emotion] = enhanced[emotion] + 0.05

        return enhanced

    def _analyze_intensity(self, text: str) -> float:
        """分析情感强度"""
        text_lower = text.lower()
        intensity = 1.0

        # 检查强度修饰词
        for level, words in self.intensity_modifiers.items():
            for word in words:
                if word in text_lower:
                    if level == "very":
                        intensity *= 1.3
                    elif level == "slightly":
                        intensity *= 0.7
                    elif level == "extremely":
                        intensity *= 1.5
                    break

        # 检查重复字符（如"好好好"、"哈哈哈"）
        import re
        repeated_chars = re.findall(r'(.)\1{2,}', text)
        if repeated_chars:
            intensity *= 1.2

        # 检查感叹号和问号
        exclamation_count = text.count('!')
        question_count = text.count('?')
        intensity *= (1 + (exclamation_count + question_count) * 0.1)

        return min(intensity, 2.0)  # 限制最大强度

class EmbeddingRecommender:
    """基于嵌入的推荐系统"""
    
    def __init__(self, model_name: str = "moka-ai/m3e-base"):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        
        try:
            self.model = SentenceTransformer(model_name, device=self.device)
        except Exception as e:
            print(f"Failed to load embedding model: {e}")
            self.model = None
    
    def encode_texts(self, texts: List[str]) -> np.ndarray:
        """编码文本为向量"""
        if not self.model:
            # 回退到简单的词频向量
            return self._simple_vectorize(texts)
            
        try:
            embeddings = self.model.encode(texts, convert_to_numpy=True)
            return embeddings
        except Exception as e:
            print(f"Encoding failed: {e}")
            return self._simple_vectorize(texts)
    
    def _simple_vectorize(self, texts: List[str]) -> np.ndarray:
        """简单的词频向量化"""
        from collections import Counter
        import jieba
        
        # 分词并统计词频
        all_words = set()
        text_words = []
        
        for text in texts:
            words = list(jieba.cut(text))
            text_words.append(words)
            all_words.update(words)
        
        word_to_idx = {word: idx for idx, word in enumerate(all_words)}
        vectors = []
        
        for words in text_words:
            vector = np.zeros(len(all_words))
            word_count = Counter(words)
            for word, count in word_count.items():
                if word in word_to_idx:
                    vector[word_to_idx[word]] = count
            vectors.append(vector)
        
        return np.array(vectors)
    
    def find_similar(self, query_text: str, candidate_texts: List[str], top_k: int = 5) -> List[Tuple[int, float]]:
        """找到最相似的文本"""
        all_texts = [query_text] + candidate_texts
        embeddings = self.encode_texts(all_texts)
        
        if len(embeddings) == 0:
            return []
        
        query_embedding = embeddings[0:1]
        candidate_embeddings = embeddings[1:]
        
        similarities = cosine_similarity(query_embedding, candidate_embeddings)[0]
        
        # 获取top_k个最相似的
        top_indices = np.argsort(similarities)[::-1][:top_k]
        results = [(idx, similarities[idx]) for idx in top_indices]
        
        return results

class CacheManager:
    """智能缓存管理器"""

    def __init__(self, redis_url: str = "redis://localhost:6379"):
        try:
            self.redis_client = redis.from_url(redis_url)
            self.redis_client.ping()
            self.enabled = True
        except Exception as e:
            print(f"Redis connection failed: {e}")
            self.redis_client = None
            self.enabled = False
            self._memory_cache = {}

        # 智能缓存统计
        self.cache_stats = {
            "hits": 0,
            "misses": 0,
            "sets": 0,
            "deletes": 0,
            "evictions": 0
        }
        self.max_memory_cache_size = 1000
        self.cache_access_times = {}
        self.cache_hit_counts = {}
    
    def get(self, key: str) -> Optional[Dict]:
        """智能获取缓存"""
        # 更新访问时间和命中次数
        self.cache_access_times[key] = datetime.now()
        self.cache_hit_counts[key] = self.cache_hit_counts.get(key, 0) + 1

        if not self.enabled:
            result = self._memory_cache.get(key)
            if result:
                self.cache_stats["hits"] += 1
                return result
            else:
                self.cache_stats["misses"] += 1
                return None

        try:
            data = self.redis_client.get(key)
            if data:
                self.cache_stats["hits"] += 1
                result = json.loads(data)
                # 同时缓存到内存中以提高性能
                self._update_memory_cache(key, result)
                return result
            else:
                self.cache_stats["misses"] += 1
                return None
        except Exception as e:
            print(f"Cache get failed: {e}")
            self.cache_stats["misses"] += 1
            return None
    
    def set(self, key: str, value: Dict, ttl: int = 3600):
        """智能设置缓存"""
        self.cache_stats["sets"] += 1

        if not self.enabled:
            self._update_memory_cache(key, value)
            return

        try:
            self.redis_client.setex(key, ttl, json.dumps(value))
            # 同时更新内存缓存
            self._update_memory_cache(key, value)
        except Exception as e:
            print(f"Cache set failed: {e}")
            self._update_memory_cache(key, value)

    def _update_memory_cache(self, key: str, value: Dict):
        """更新内存缓存，使用LRU策略"""
        # 如果缓存已满，移除最少使用的项
        if len(self._memory_cache) >= self.max_memory_cache_size:
            self._evict_lru_items()

        self._memory_cache[key] = value
        self.cache_access_times[key] = datetime.now()

    def _evict_lru_items(self):
        """移除最少使用的缓存项"""
        if not self.cache_access_times:
            return

        # 按访问时间排序，移除最旧的25%
        sorted_items = sorted(
            self.cache_access_times.items(),
            key=lambda x: x[1]
        )

        items_to_remove = len(sorted_items) // 4
        for key, _ in sorted_items[:items_to_remove]:
            self._memory_cache.pop(key, None)
            self.cache_access_times.pop(key, None)
            self.cache_hit_counts.pop(key, None)
            self.cache_stats["evictions"] += 1

    def get_cache_stats(self) -> Dict:
        """获取缓存统计信息"""
        hit_rate = 0
        if self.cache_stats["hits"] + self.cache_stats["misses"] > 0:
            hit_rate = self.cache_stats["hits"] / (self.cache_stats["hits"] + self.cache_stats["misses"])

        return {
            **self.cache_stats,
            "hit_rate": hit_rate,
            "memory_cache_size": len(self._memory_cache),
            "redis_enabled": self.enabled
        }
    
    def generate_key(self, user_signals: Dict) -> str:
        """生成缓存键"""
        # 基于用户信号生成唯一键
        key_parts = [
            str(len(user_signals.get('recentMessages', []))),
            str(len(user_signals.get('moodRecords', []))),
            str(user_signals.get('weather', {}).get('current_weather', {}).get('weathercode', 0)),
            datetime.now().strftime('%Y-%m-%d'),  # 按天缓存
        ]
        return f"recommendations:{'_'.join(key_parts)}"

# 全局实例
emotion_analyzer = None
embedding_recommender = None
cache_manager = None

def get_emotion_analyzer() -> EmotionAnalyzer:
    global emotion_analyzer
    if emotion_analyzer is None:
        emotion_analyzer = EmotionAnalyzer()
    return emotion_analyzer

def get_embedding_recommender() -> EmbeddingRecommender:
    global embedding_recommender
    if embedding_recommender is None:
        embedding_recommender = EmbeddingRecommender()
    return embedding_recommender

def get_cache_manager() -> CacheManager:
    global cache_manager
    if cache_manager is None:
        cache_manager = CacheManager()
    return cache_manager
