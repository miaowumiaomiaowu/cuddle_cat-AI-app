# 🔑 API配置指南

## DeepSeek API配置

### 1. 获取API密钥

1. 访问 [DeepSeek平台](https://platform.deepseek.com/)
2. 注册账号并登录
3. 进入API管理页面
4. 创建新的API密钥
5. 复制生成的API密钥（格式：`sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`）

### 2. 配置环境变量

在项目根目录的 `.env` 文件中配置：

```env
# DeepSeek AI API密钥
DEEPSEEK_API_KEY=你的真实API密钥
DEEPSEEK_API_ENDPOINT=https://api.deepseek.com/v1/chat/completions
```

### 3. 验证配置

1. 启动应用
2. 进入开发者工具页面（设置 -> 开发者工具）
3. 点击"测试API连接"按钮
4. 查看连接状态

## 离线模式

如果没有配置API密钥或网络不可用，应用会自动切换到离线模式：

- ✅ 基础猫咪互动功能正常
- ✅ 智能离线回复系统
- ✅ 心理支持功能（基于规则）
- ✅ 旅行记录功能
- ✅ 心情记录功能

## 故障排除

### 常见问题

1. **API密钥无效**
   - 检查密钥格式是否正确
   - 确认密钥是否已激活
   - 检查账户余额

2. **网络连接问题**
   - 检查网络连接
   - 确认防火墙设置
   - 尝试使用VPN

3. **请求超时**
   - 应用会自动重试
   - 超时后切换到离线模式

### 调试工具

使用应用内的调试工具：
- API连接测试
- 网络状态检查
- 错误日志查看

## 安全提醒

⚠️ **重要**：
- 不要将API密钥提交到版本控制系统
- 定期更换API密钥
- 监控API使用量和费用
