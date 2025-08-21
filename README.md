# 🐱 暖猫 (Cuddle Cat)

> 一款基于 AI 驱动的心理健康与情感陪伴应用，融合了先进的情绪分析、智能对话和个性化建议系统

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6+-0175C2?style=flat&logo=dart)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?style=flat&logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat&logo=python)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## ✨ 项目概述

暖猫是一款创新的心理健康应用，通过可爱的猫咪助手形象，为用户提供温暖的情感陪伴和专业的心理支持。应用结合了现代 AI 技术与人性化设计，创造出独特的"情绪记录  温和陪伴  智能建议"体验。

### 🎯 核心价值
- **🧠 智能情绪分析**：基于 DeepSeek 模型的深度情绪理解与模式识别
- **💝 温暖陪伴体验**：可爱猫咪助手提供24/7情感支持
- **📊 数据驱动洞察**：科学的心理健康追踪与趋势分析
- **🎁 个性化建议**：AI驱动的幸福清单与健康计划定制
- **🔒 隐私优先设计**：本地存储优先，可选云端同步

---

## 🚀 主要功能

### 🐾 智能猫咪助手
- **个性化对话**：基于 DeepSeek AI 模型的智能回复系统
- **情绪感知**：实时识别用户情绪状态，调整对话风格
- **上下文记忆**：长期记忆用户偏好与重要信息
- **多种猫咪品种**：波斯猫、布偶猫、暹罗猫等可选择领养，对应不同对话风格

###  情绪记录与分析
- **多维度记录**：心情类型、强度等级、触发事件
- **智能标签系统**：工作、家庭、健康等分类标签
- **趋势可视化**：FL Chart 驱动的美观图表展示


###  幸福任务系统
- **AI推荐引擎**：基于心情记录生成个性化幸福清单
- **健康计划定制**：周期性目标设定与习惯培养
- **微幸福打卡**：深呼吸、伸展运动等快速正念练习
- **进度追踪**：完成率统计与连续打卡记录

###  智能分析面板
- **情绪模式识别**：AI分析情绪变化规律
- **预测性洞察**：基于历史数据的情绪趋势预测
- **个人画像构建**：持续学习用户特征的心理健康档案
- **突破检测**：识别积极变化与成长里程碑

---

## 🏗️ 技术架构

### 前端架构 (Flutter)
```
📱 Flutter App (Dart 3.6+)
├── 🎨 UI Layer
│   ├── Material Design 3 + 自定义主题系统
│   ├── 响应式布局 (手机/平板适配)
│   └── 流畅动画 (Lottie + 自定义动效)
├── 🔄 状态管理
│   ├── Provider + ChangeNotifier 架构
│   ├── 多Provider协调 (Mood/Cat/Happiness/User)
│   └── 生命周期管理与错误处理
├── 💾 数据层
│   ├── SharedPreferences (本地存储)
│   ├── SQLite (复杂数据结构)
│   └── HTTP Client (可选云端同步)
└── 🧩 核心服务
    ├── AI Psychology Service (情绪分析)
    ├── Memory Service (长期记忆)
    ├── Reminder Service (智能提醒)
    └── Config Service (运行时配置)
```

### 后端架构 (FastAPI)
```
🐍 Python Backend (FastAPI + Uvicorn)
├── 🤖 AI 引擎
│   ├── DeepSeek API 集成
│   ├── Sentence Transformers (文本嵌入)
│   ├── 情绪分析模型 (Transformers)
│   └── 在线学习系统 (自适应优化)
├── 💾 数据存储
│   ├── PostgreSQL + pgvector (向量存储)
│   ├── SQLite (轻量级部署)
│   └── Redis (缓存与会话)
├── 📊 分析服务
│   ├── 行为模式分析
│   ├── 情绪预测模型
│   └── 个性化推荐引擎
└── 🔧 运维支持
    ├── Prometheus 指标监控
    ├── 健康检查端点
    └── Docker 容器化部署
```

---

## 🛠️ 技术栈详解

### 移动端技术
| 技术 | 版本 | 用途 |
|------|------|------|
| **Flutter** | 3.16+ | 跨平台UI框架 |
| **Dart** | 3.6+ | 编程语言 |
| **Provider** | 6.1.1 | 状态管理 |
| **FL Chart** | 0.68.0 | 数据可视化 |
| **Lottie** | 3.1.0 | 动画效果 |
| **SQLite** | 2.3.0 | 本地数据库 |
| **Google Fonts** | 6.3.0 | 字体系统 |

### 后端技术
| 技术 | 版本 | 用途 |
|------|------|------|
| **FastAPI** | 0.115.0 | Web框架 |
| **PyTorch** | 2.3.1 | 机器学习 |
| **Transformers** | 4.43.3 | NLP模型 |
| **PostgreSQL** | 16+ | 主数据库 |
| **pgvector** | 0.2.5+ | 向量存储 |
| **Redis** | 5.0+ | 缓存系统 |

---

## 🚀 快速开始

### 环境要求
- **Flutter SDK**: 3.16.0+
- **Dart SDK**: 3.6.0+
- **Python**: 3.11+ (后端可选)
- **Node.js**: 18+ (开发工具)

### 1️⃣ 克隆项目
```bash
git clone https://github.com/miaowumiaowu/cuddle_cat.git
cd cuddle_cat
```

### 2️⃣ 安装依赖
```bash
# Flutter 依赖
flutter pub get

# 后端依赖 (可选)
cd server
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 3️⃣ 配置环境
```bash
# 复制环境配置模板
cp .env.example .env

# 编辑配置文件 (可选)
# DEEPSEEK_API_KEY=your_api_key_here
# ENABLE_REMOTE_BACKEND=true
# SERVER_BASE_URL=http://localhost:8000
```

### 4️⃣ 启动应用
```bash
# 启动 Flutter 应用
flutter run

# 启动后端服务 (可选)
cd server
uvicorn app.main:app --reload --port 8000
```

---

## 📱 应用截图

### 主要界面
- **🏠 沉浸式聊天首页**: 与AI猫咪助手的温暖对话
- **📊 幸福清单面板**: 个性化建议与幸福清单，提升用户幸福感
- **📈 智能分析页面**: 情绪趋势与深度洞察
- **👤 个人中心**: 用户设置与数据管理

### 核心功能演示
- **🎭 情绪记录**: 多维度心情追踪与标签系统
- **🎁 幸福清单**: AI驱动的个性化幸福清单
- **📅 习惯培养**: 可持续的健康计划制定

---

## 🔧 开发指南

### 项目结构
```
cuddle_cat/
├── 📱 lib/                    # Flutter 应用源码
│   ├── models/                # 数据模型
│   ├── providers/             # 状态管理
│   ├── screens/               # 页面组件
│   ├── services/              # 业务服务
│   ├── widgets/               # UI组件
│   └── theme/                 # 主题系统
├── 🐍 server/                 # Python 后端
│   ├── app/                   # FastAPI 应用
│   ├── requirements.txt       # Python 依赖
│   └── Dockerfile            # 容器配置
├── 🧪 test/                   # 测试文件
├── 📚 docs/                   # 项目文档
└── 🐳 docker-compose.yml     # 容器编排
```

### 开发工具
- **🔍 开发者工具页面**: 运行时配置与系统诊断
- **🐛 调试面板**: API连接测试与错误日志
- **📊 指标监控**: Prometheus格式的性能指标
- **🔧 代理配置**: Android模拟器网络代理脚本

---

## 🚢 部署指南

### Docker 部署 (推荐)
```bash
# 启动完整服务栈
docker-compose up -d

# 服务访问地址
# - 后端API: http://localhost:8002
# - PostgreSQL: localhost:5434
# - Redis: localhost:6379
```

### 手动部署
```bash
# 后端服务
cd server
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Flutter Web (可选)
flutter build web
# 部署 build/web 目录到静态服务器
```

---

## 📊 性能特性

### 🚀 性能优化
- **懒加载**: Provider延迟初始化，减少启动时间
- **内存管理**: 智能缓存与资源回收机制
- **网络优化**: 请求超时控制与降级策略
- **本地优先**: 离线模式确保基础功能可用

### 📈 可扩展性
- **模块化架构**: 松耦合的服务设计
- **插件系统**: 可扩展的AI模型接入
- **多租户支持**: 用户数据隔离与权限管理
- **水平扩展**: 容器化部署支持集群扩展

---

## 🔒 隐私与安全

### 数据保护
- **🏠 本地优先**: 默认本地存储，无强制云同步
- **🔐 加密传输**: HTTPS/TLS端到端加密
- **🎭 匿名化**: 敏感数据脱敏处理
- **🗑️ 数据清理**: 用户可控的数据删除

### 安全措施
- **🔑 API密钥管理**: 环境变量安全存储
- **🛡️ 访问控制**: 基于角色的权限系统
- **📊 审计日志**: 关键操作记录与监控
- **🔍 漏洞扫描**: 定期安全检查与更新


---

## 👩‍💻 开发者信息

**开发者**: 韩嘉仪 / Han Jiayi
**GitHub**: [@miaowumiaowu](https://github.com/miaowumiaowu)
**项目地址**: [https://github.com/miaowumiaowu/cuddle_cat](https://github.com/miaowumiaowu/cuddle_cat)

---

## 🙏 致谢

感谢以下开源项目和服务：
- [Flutter](https://flutter.dev) - 跨平台UI框架
- [FastAPI](https://fastapi.tiangolo.com) - 现代Python Web框架
- [DeepSeek](https://platform.deepseek.com) - AI模型服务
- [PostgreSQL](https://postgresql.org) - 开源数据库
- [pgvector](https://github.com/pgvector/pgvector) - 向量存储扩展

---

<div align="center">

**🐱 用温暖的技术，陪伴每一个需要关怀的心灵 🐱**

Made with ❤️ by Han Jiayi

</div>