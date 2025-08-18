# 安全配置与合规指引

本项目提供轻量的安全加固能力，建议在生产环境启用。

## 1) 指标与内部端点保护
- 设置环境变量 `METRICS_API_KEY`（或 `AI_SERVICE_INTERNAL_KEY`），后端会要求请求头 `X-API-Key`
- 受保护端点：
  - `GET /metrics`（JSON 指标）
  - `GET /metrics_prom`（Prometheus 文本）
- Flutter 侧：`lib/services/metrics_api_client.dart` 会自动从 `.env` 读取 `METRICS_API_KEY` 并附带请求头

## 2) 输入限制（默认值，可调整）
- ChatMessage.content：≤ 2000 字符
- MemoryEvent.type：≤ 32；MemoryEvent.text：≤ 2000
- MemoryEvent.metadata：key ≤ 64；string 型 value ≤ 256
- FeedbackEvent：
  - feedback_type ∈ {like, dislike, complete, skip, useful}
  - score ∈ [0,1]
  - comment ≤ 500 字符

触发限制时，返回 HTTP 422 并包含错误信息。

## 3) 日志与数据最小化
- 指标与返回值中避免包含用户明文内容
- 推荐仅在开发模式输出调试日志；生产务必降低日志级别并过滤敏感字段

## 4) 部署建议
- 将后端部署在受控网络，调试与内部端点仅在内网开放
- 通过反向代理（如 Nginx）增加基础限流（Rate Limit）与超时保护
- 使用 HTTPS/TLS 终端，保护传输层安全

## 5) 监控对接
- Prometheus 抓取 `GET /metrics_prom`
- 常用公式：
  - 错误率：`rate(cuddle_chat_reply_errors[5m]) / rate(cuddle_chat_reply_requests[5m])`
  - 回退率：`rate(cuddle_mem_retrieval_fallback[5m]) / rate(cuddle_mem_retrieval_total[5m])`
  - 延迟：`cuddle_latency_ms_p95`, `cuddle_latency_ms_avg`

## 6) 后续可选强化（按需）
- 为更多调试端点加 API Key 或开关
- 对日志与审计设计统一格式与脱敏策略
- 增加 IP 白名单或 mTLS（服务间）

