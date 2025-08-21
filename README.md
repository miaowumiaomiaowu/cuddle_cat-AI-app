# 暖猫 (Cuddle Cat)

一款基于 AI 分析能力，关注“情绪记录 × 温和陪伴 × 轻量建议”的 Flutter 应用。

- 🐾 猫咪助手式对话与陪伴
- 📓 情绪记录与趋势洞察
- 🎁 温和建议/礼物卡片与计划
- 🗺️ 心情地图

开发者：韩嘉仪 / Han Jiayi · GitHub: https://github.com/miaowumiaowu

---

## 🤖 AI 功能特性

### 智能对话与陪伴
- 个性化回复：AI 猫咪助手基于 DeepSeek 模型，能够理解你的情绪状态和个人偏好，提供温暖贴心的回复
- 上下文记忆：记住你之前分享的经历、喜好和困扰，让每次对话更有连续性和针对性
- 情绪感知：识别你当前的心情状态，调整对话风格和建议方向，提供恰当的情感支持

### 个性化建议系统
- 智能礼物推荐：结合你的心情记录、兴趣偏好和当前状态，推荐适合的幸福清单
- 健康计划定制：根据你的生活习惯和目标，制定个性化的幸福提升计划，包含具体的行动步骤
- 情境感知建议：考虑时间、地点、天气等因素，提供更贴合当下情境的温和建议

### 情绪分析与洞察
- 深度情绪理解：不仅识别基础情绪，还能分析情绪背后的原因和模式
- 趋势预测：基于历史数据预测可能的情绪变化，提前给出关怀提醒
- 个人画像构建：持续学习你的情绪特点，构建专属的心理健康档案

### 记忆与学习系统
- 长期记忆：保存重要的对话内容和个人信息，建立更深的陪伴关系
- 偏好学习：自动学习你的喜好、习惯和反馈，不断优化建议质量
- 成长追踪：记录你的心理成长轨迹，见证每一个积极的变化

> 说明：若你不配置任何后端/密钥，应用也可在本地正常使用（以规则与本地偏好推断为主）；当你接入后端并启用在线能力时，以上 AI 功能将获得更强的个性化与上下文理解。

---

## 🌟 核心体验亮点
- 对话可感知情绪走向，并在合适时机引用你过往分享的关键信息
- 推荐卡片包含理由与预计时长，帮助你采取“小步快走”的行动
- 周期性健康计划提供目标/习惯/检查点，不强迫、可持续
- 记忆系统长期保存重要线索，结合当前语境生成更贴近你的回应
- 默认可离线使用；连接在线 AI 后，个性化与上下文理解更强


---

## 🧩 功能模块

- 🧠 细粒度情绪维度：在建议与计划生成时综合考虑强度、标签与近期节律
- 🕒 时段敏感：晚间更偏向放松类建议，白天更倾向行动类
- 🧾 理由可解释：每张卡片/每条建议尽量附带“为什么推荐给你”的说明
- 🔁 反馈可用：对建议的“喜欢/有用”反馈会用于后续优化


- 💬 沉浸式聊天
  - 留有“参考与反馈”区块：展示依据的历史偏好/记忆摘要，提供“喜欢/有用”等反馈入口
  - 在未启用后端时，聊天以“温和建议/提示”形式呈现（规则推断）
  - 当启用在线 AI 时，会结合你的历史偏好、近期情绪与关键记忆生成更贴合当下的回复与建议
  - 对话消息的“依据参考（used_memories/profile）”可在界面中展开查看

- 📈 情绪记录与洞察
  - 快速心情/详细记录：强度、标签、备注
  - 趋势、分布、近 7 天完成率、积极/消极占比等基础统计
- 🎯 幸福清单与温和建议
  - 情绪事件会带上地点、标签与注释，方便回顾触发因素
  - 统计面板支持按时间范围快速切换，帮助你发现模式与改善窗口
  - 结合近期记录生成幸福清单（时长/类别/理由）
- ⚙️ 设置与开发者工具
  - 快速查看基础系统信息与本地存储自检
  - 指标开关与 API Key（用于 /metrics）

---

## 🚀 快速开始

1) 准备环境
- Flutter 3.x
- Dart 3.6+

2) 拉取依赖
- `flutter pub get`

3) 运行
- `flutter run`

4) 可选：配置 .env（仅在你需要启用在线能力时）
- 复制 .env.example 为 .env，并按需填写：
  - ENABLE_REMOTE_BACKEND=true 与 SERVER_BASE_URL（启用本仓库 server/ 后端）
  - DEEPSEEK_API_KEY（用于 server 端调用第三方模型）
  - METRICS_API_KEY/AI_SERVICE_INTERNAL_KEY（可选，保护 /metrics 与内部端点）

---

## 🛠️ 后端（FastAPI，server/）

快速启动：
```bash
cd server
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

主要端点：
- GET  /health
- POST /chat/reply
- POST /recommend/gifts
- POST /recommend/wellness-plan
- POST /memory/upsert
- POST /memory/query
- POST /feedback；GET /feedback/stats/{user_id}
- GET  /analytics/stats；POST /analytics/predict-mood；POST /analytics/emotion-advanced
- GET  /metrics；GET /metrics_prom（如设置 METRICS_API_KEY 则需携带 X-API-Key）
- GET  /learning/system-stats；POST /learning/train-models；POST /learning/add-training-data

Flutter 侧通过 .env 与运行时设置读取 SERVER_BASE_URL；当 `ENABLE_REMOTE_BACKEND=true` 时始终使用 HTTP 后端。

---

## 🔒 数据与隐私

- 默认本地存储（SharedPreferences）；未接入云同步
- 启用后端时，建议通过 HTTPS/TLS 暴露服务，并限制访问来源
- 指标端点可通过 METRICS_API_KEY 受保护

---

## 🧪 开发与调试

- 开发者工具页：
  - 查看运行时配置、基础系统信息、本地存储自检
  - 重置某些节律限制（例如“今日礼物限制”）
- Android 模拟器代理脚本（Windows）：
  - `scripts/setup_android_proxy.bat`（将模拟器 127.0.0.1:7890 反向映射到宿主机）

---

## 🗺️ 架构概览（简）

- Flutter 客户端
  - Provider + ChangeNotifier
  - ArtisticTheme 设计体系（柔和绿色系、圆角、温和动效）
  - 本地存储：SharedPreferences
  - 网络：http + 轻量超时/降级
- FastAPI 后端（可选）
  - 规则/轻学习 + 记忆检索（SQLite + 轻量向量索引）
  - Analytics & Online Learning：用于画像与排序优化
  - Metrics：/metrics 与 /metrics_prom（可选 API Key）


---

## 👩🏻‍💻 开发者与支持

- 开发者：韩嘉仪 / Han Jiayi
- GitHub：https://github.com/miaowumiaowu

