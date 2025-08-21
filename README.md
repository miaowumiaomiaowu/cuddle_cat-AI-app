# 暖猫 (Cuddle Cat)

Flutter 应用，聚焦：
- 情绪记录与统计（本地存储）
- 沉浸式聊天（猫咪助手）
- 幸福清单与温和建议（基于规则，支持可选后端推荐）
- 心情地图（自绘可视化，非第三方地图 SDK）

开发者：韩嘉仪 / Han Jiayi  ·  GitHub: https://github.com/miaowumiaomiaowu

## 功能概览（已实现）
- 沉浸式聊天首页：对话记录、输入、打字指示，悬浮猫助手微互动
- 情绪记录：快速心情、详细记录，标签/强度/备注；本地持久化（SharedPreferences）
- 统计与洞察：趋势、分布、积极/消极占比等基础分析
- 幸福清单：基于心情记录生成温和建议；支持“礼物视图”与计划卡片
- 心情地图：基于记录位置的自绘可视化（示意图层）
- 设置/开发者工具：运行时配置、简单指标与调试

说明：应用默认离线可用；如配置 .env 的 DeepSeek 密钥，可在对话中使用在线 AI 回复（失败时由上层统一报错，不做虚假兜底）。

## 快速开始
1) 安装依赖
- Flutter 3.x
- 在项目根目录执行：`flutter pub get`

2) 运行
- `flutter run`

3) 可选：环境变量（.env）
- 复制 .env.example 为 .env，并按需填写：
  - DEEPSEEK_API_KEY（可选）
  - DEEPSEEK_API_ENDPOINT（可选，默认官方）
  - USE_HTTP_PROXY/HTTP_PROXY_HOST/HTTP_PROXY_PORT（可选，开发调试代理）
  - ENABLE_REMOTE_BACKEND=true 与 SERVER_BASE_URL（可选，启用本仓库 server/ 后端）

## 可选后端（FastAPI，位于 server/）
当前 server/ 实现了聊天回复、礼物与健康计划建议、记忆、反馈、基础分析、指标等端点。

快速启动：
```bash
cd server
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

主要端点（节选）：
- GET  /health
- POST /chat/reply
- POST /recommend/gifts
- POST /memory/upsert, /memory/query
- POST /feedback；GET /feedback/stats/{user_id}
- GET  /analytics/stats；POST /analytics/predict-mood；POST /analytics/emotion-advanced
- GET  /metrics 与 /metrics_prom（可选密钥保护）
- GET  /learning/system-stats；POST /learning/train-models；POST /learning/add-training-data

Flutter 侧通过 .env 与运行时设置读取 SERVER_BASE_URL；当 `ENABLE_REMOTE_BACKEND=true` 时强制走远端。

## 数据与隐私
- 用户数据默认保存在本地（SharedPreferences）；未实现云同步
- 未集成 Firebase/地图 SDK/社交分享等第三方方案
- 可选 AI/后端需由你自行配置密钥与服务器

## 路线与规划（简）
- 近期：完善记录/统计体验，优化错误体验与无障碍
- 可能：更丰富的建议生成、更细的学习/偏好、数据导入导出
- 长期：多语言、更多端（Web/桌面）等（以实际实现为准）

## 开发者与支持
- 开发者：韩嘉仪 / Han Jiayi
- GitHub：https://github.com/miaowumiaomiaowu

## 附：Android 模拟器代理脚本（Windows）
- 脚本：`scripts/setup_android_proxy.bat`
- 用途：将模拟器的 127.0.0.1:7890 反向映射到宿主机
- 使用：确保 adb 可用，运行脚本并开启系统代理；重启模拟器需重跑脚本

