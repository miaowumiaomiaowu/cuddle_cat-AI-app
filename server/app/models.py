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
    """中文情感分析模型"""
    
    def __init__(self, model_name: str = "hfl/chinese-roberta-wwm-ext"):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Using device: {self.device}")
        
        try:
            # 尝试加载情感分析pipeline
            self.sentiment_pipeline = pipeline(
                "sentiment-analysis",
                model=model_name,
                device=0 if self.device == "cuda" else -1
            )
        except Exception as e:
            print(f"Failed to load sentiment model: {e}")
            # 回退到规则方法
            self.sentiment_pipeline = None
            
        # 情感关键词字典
        self.emotion_keywords = {
            "happy": ["开心", "快乐", "兴奋", "愉快", "满足", "幸福", "高兴"],
            "sad": ["难过", "伤心", "沮丧", "失落", "悲伤", "郁闷"],
            "anxious": ["焦虑", "紧张", "担心", "不安", "恐惧", "害怕"],
            "angry": ["生气", "愤怒", "烦躁", "恼火", "气愤"],
            "calm": ["平静", "放松", "安静", "淡定", "冷静"],
            "tired": ["疲惫", "累", "困", "乏力", "疲劳"],
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
    """缓存管理器"""
    
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
    
    def get(self, key: str) -> Optional[Dict]:
        """获取缓存"""
        if not self.enabled:
            return self._memory_cache.get(key)
            
        try:
            data = self.redis_client.get(key)
            if data:
                return json.loads(data)
        except Exception as e:
            print(f"Cache get failed: {e}")
        return None
    
    def set(self, key: str, value: Dict, ttl: int = 3600):
        """设置缓存"""
        if not self.enabled:
            self._memory_cache[key] = value
            return
            
        try:
            self.redis_client.setex(key, ttl, json.dumps(value))
        except Exception as e:
            print(f"Cache set failed: {e}")
    
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
