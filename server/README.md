# 🐍 暖猫 AI 分析服务 (FastAPI)

> 基于 FastAPI 的智能后端服务，为暖猫应用提供 AI 对话、情绪分析、个性化推荐和数据分析功能

[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?style=flat&logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat&logo=python)](https://python.org)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=flat&logo=docker)](https://docker.com)

## ✨ 功能特性

### 🤖 AI 对话服务
- **智能回复生成**：基于 DeepSeek 模型的上下文感知对话
- **情绪识别**：实时分析用户情绪状态
- **个性化响应**：根据用户历史调整回复风格

### 📊 数据分析引擎
- **行为模式分析**：识别用户行为趋势和习惯
- **情绪预测模型**：基于历史数据预测情绪变化
- **个性化推荐**：AI驱动的幸福清单和健康计划

### 💾 记忆与学习系统
- **长期记忆存储**：用户偏好和重要信息持久化
- **向量化检索**：基于语义相似度的记忆查询
- **自适应学习**：根据用户反馈优化推荐质量

### 📈 监控与指标
- **Prometheus 集成**：完整的性能指标监控
- **健康检查**：服务状态和依赖检查
- **错误追踪**：详细的错误日志和分析

---

## 🚀 API 端点

### 核心服务
| 端点 | 方法 | 描述 |
|------|------|------|
| `/health` | GET | 服务健康检查 |
| `/chat/reply` | POST | AI 对话回复生成 |
| `/recommend` | POST | 综合分析与推荐 |

### 记忆系统
| 端点 | 方法 | 描述 |
|------|------|------|
| `/memory/upsert` | POST | 存储用户记忆事件 |
| `/memory/query` | POST | 查询相关记忆 |

### 分析服务
| 端点 | 方法 | 描述 |
|------|------|------|
| `/analytics/stats` | GET | 获取分析统计数据 |
| `/analytics/stats` | GET | 系统统计信息 |
| `/analytics/predict-mood` | POST | 情绪预测分析 |
| `/analytics/emotion-advanced` | POST | 高级情绪分析 |

### 反馈系统
| 端点 | 方法 | 描述 |
|------|------|------|
| `/feedback` | POST | 用户反馈收集 |
| `/feedback/stats/{user_id}` | GET | 用户反馈统计 |

### 监控指标
| 端点 | 方法 | 描述 | 认证 |
|------|------|------|------|
| `/metrics` | GET | JSON 格式指标 | API Key |
| `/metrics_prom` | GET | Prometheus 格式指标 | API Key |

### 反馈系统
| 端点 | 方法 | 描述 |
|------|------|------|
| `/feedback` | POST | 用户反馈收集 |

---

## 🛠️ 快速开始

### 环境要求
- **Python**: 3.11+
- **内存**: 最少 2GB RAM
- **存储**: 1GB 可用空间

### 1️⃣ 本地开发
```bash
# 创建虚拟环境
python -m venv .venv

# 激活虚拟环境
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt

# 启动开发服务器
uvicorn app.main:app --reload --port 8000
```

### 2️⃣ Docker 部署
```bash
# 构建镜像
docker build -t cuddlecat-ai-service .

# 运行容器
docker run -p 8000:8000 cuddlecat-ai-service

# 使用 docker-compose (推荐)
cd ..
docker-compose up -d
```

### 3️⃣ 环境配置
```bash
# 复制环境配置模板
cp .env.example .env

# 编辑配置文件
# DEEPSEEK_API_KEY=your_api_key_here
# DATABASE_URL=postgresql://user:pass@localhost:5432/cuddlecat
# REDIS_URL=redis://localhost:6379
```

---

## 🔧 技术架构

### 核心技术栈
- **Web框架**: FastAPI 0.115+
- **AI模型**: DeepSeek API + Transformers
- **数据库**: PostgreSQL + pgvector
- **缓存**: Redis
- **监控**: Prometheus + 自定义指标

### 服务架构
```
🐍 FastAPI Service
├── 🤖 AI 引擎
│   ├── DeepSeek API (对话生成)
│   ├── Transformers (情绪分析)
│   └── Sentence Transformers (文本嵌入)
├── 💾 数据存储
│   ├── PostgreSQL + pgvector (向量存储)
│   ├── SQLite (轻量级部署)
│   └── Redis (缓存层，可选)
├── 📊 分析引擎
│   ├── 行为模式分析
│   ├── 情绪预测模型
│   └── 个性化推荐系统
└── � 监控系统
    ├── Prometheus 指标
    ├── 健康检查端点
    └── 性能追踪
```

---

## 📊 性能与监控

### 关键指标
- **响应时间**: P95 < 2s, P99 < 5s
- **可用性**: > 99.9%
- **错误率**: < 0.1%
- **内存使用**: < 1GB (正常负载)

### 监控配置
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'cuddlecat-ai'
    static_configs:
      - targets: ['localhost:8000']
    metrics_path: '/metrics_prom'
    headers:
      X-API-Key: 'your_metrics_api_key'
```

---

## 🔒 安全配置

### API 密钥保护
```bash
# 设置监控端点保护
export METRICS_API_KEY=your_secure_key

# 设置内部服务密钥
export AI_SERVICE_INTERNAL_KEY=your_internal_key
```

### 输入验证
- **消息长度**: ≤ 2000 字符
- **记忆事件**: type ≤ 32, text ≤ 2000
- **反馈评分**: 0-1 范围
- **用户ID**: 必需且非空

---

## 🧪 测试与调试

### 运行测试
```bash
# 安装测试依赖
pip install pytest pytest-asyncio httpx

# 运行所有测试
pytest

# 运行特定测试
pytest tests/test_api.py -v

# 生成覆盖率报告
pytest --cov=app tests/
```

### API 测试
```bash
# 健康检查
curl http://localhost:8000/health

# 测试对话接口 (需要配置 API 密钥)
curl -X POST http://localhost:8000/chat/reply \
  -H "Content-Type: application/json" \
  -d '{"message": "你好", "user_id": "test_user"}'

# 测试推荐接口
curl -X POST http://localhost:8000/recommend \
  -H "Content-Type: application/json" \
  -d '{"recentMessages": ["今天心情不错"], "moodRecords": [], "stats": {}}'
```

---

## 📚 开发指南

### 项目结构
```
server/
├── app/
│   ├── main.py              # FastAPI 应用入口
│   ├── models.py            # AI 模型管理
│   ├── db.py               # 数据库操作
│   ├── vector_store.py     # 向量存储
│   ├── advanced_analytics.py # 高级分析
│   └── online_learning.py  # 在线学习
├── tests/                  # 测试文件
├── requirements.txt        # Python 依赖
├── Dockerfile             # 容器配置
└── README.md              # 本文档
```

### 添加新端点
1. 在 `app/main.py` 中定义路由
2. 添加请求/响应模型
3. 实现业务逻辑
4. 添加相应测试
5. 更新文档

---

## 🚢 部署指南

### 生产环境部署
```bash
# 使用 Gunicorn + Uvicorn
pip install gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker

# 或使用 Docker Compose
docker-compose -f docker-compose.prod.yml up -d
```

### 环境变量
| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `DEEPSEEK_API_KEY` | DeepSeek API 密钥 | - |
| `DEEPSEEK_MODEL` | DeepSeek 模型名称 | deepseek-chat |
| `DATABASE_URL` | PostgreSQL 连接字符串 | SQLite |
| `REDIS_URL` | Redis 连接字符串 | - |
| `METRICS_API_KEY` | 监控端点密钥 | - |
| `AI_SERVICE_INTERNAL_KEY` | 内部服务密钥 | - |
| `DATA_DIR` | 数据存储目录 | ./app |
| `EMBED_MODEL` | 文本嵌入模型 | moka-ai/m3e-small |
| `SERVER_VERSION` | 服务版本号 | 0.1.0 |

---

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](../LICENSE) 文件了解详情。

