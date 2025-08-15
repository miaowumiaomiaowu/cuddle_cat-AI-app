#!/usr/bin/env python3
"""
简单的API测试脚本
"""
import requests
import json

def test_root():
    """测试根端点"""
    try:
        response = requests.get('http://localhost:8002/')
        print(f"Root endpoint: {response.status_code}")
        print(f"Response: {response.json()}")
        return True
    except Exception as e:
        print(f"Root endpoint failed: {e}")
        return False

def test_recommend():
    """测试推荐端点"""
    try:
        data = {
            "recentMessages": ["我今天心情不太好"],
            "moodRecords": [],
            "stats": {},
            "weather": None
        }
        
        response = requests.post(
            'http://localhost:8002/recommend/gifts',
            json=data,
            timeout=30
        )
        
        print(f"Recommend endpoint: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)}")
            return True
        else:
            print(f"Error response: {response.text}")
            print(f"Headers: {response.headers}")
            return False
            
    except Exception as e:
        print(f"Recommend endpoint failed: {e}")
        return False

def test_learning_stats():
    """测试学习系统统计端点"""
    try:
        response = requests.get('http://localhost:8002/learning/system-stats')
        print(f"Learning stats endpoint: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)}")
            return True
        else:
            print(f"Error response: {response.text}")
            return False
    except Exception as e:
        print(f"Learning stats endpoint failed: {e}")
        return False

def test_model_training():
    """测试模型训练端点"""
    try:
        response = requests.post('http://localhost:8002/learning/train-models')
        print(f"Model training endpoint: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)}")
            return True
        else:
            print(f"Error response: {response.text}")
            return False
    except Exception as e:
        print(f"Model training endpoint failed: {e}")
        return False

def test_add_training_data():
    """测试添加训练数据端点"""
    try:
        data = {
            "model_type": "mood",
            "features": [12, 75, 3, 2, 4],  # 时间、天气、活动、社交、睡眠
            "target": 4.2,
            "user_id": "test_user",
            "weight": 1.0
        }

        response = requests.post(
            'http://localhost:8002/learning/add-training-data',
            json=data
        )

        print(f"Add training data endpoint: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)}")
            return True
        else:
            print(f"Error response: {response.text}")
            return False
    except Exception as e:
        print(f"Add training data endpoint failed: {e}")
        return False

if __name__ == "__main__":
    print("🧪 测试 Cuddle Cat AI API")
    print("=" * 50)
    
    # 测试根端点
    print("\n1. 测试根端点...")
    test_root()
    
    # 测试推荐端点
    print("\n2. 测试推荐端点...")
    test_recommend()
    
    # 测试学习系统统计
    print("\n3. 测试学习系统统计...")
    test_learning_stats()

    # 测试模型训练
    print("\n4. 测试模型训练...")
    test_model_training()

    # 测试添加训练数据
    print("\n5. 测试添加训练数据...")
    test_add_training_data()

    # 再次测试学习系统统计（查看训练后的状态）
    print("\n6. 测试训练后的学习系统统计...")
    test_learning_stats()

    print("\n✅ 测试完成!")
