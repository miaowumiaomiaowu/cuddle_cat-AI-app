import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 统一的应用配置读取服务
/// - 从 .env 读取阿里云 ECS 后端地址、开关与超时等
/// - 提供默认值与类型安全的访问器
class ConfigService {
  ConfigService._();
  static final ConfigService instance = ConfigService._();

  // 通用读取
  String _env(String key, [String fallback = '']) {
    final v = dotenv.env[key];
    if (v == null || v.isEmpty) return fallback;
    return v;
  }

  bool _envBool(String key, [bool fallback = false]) {
    final v = dotenv.env[key]?.toLowerCase().trim();
    if (v == null || v.isEmpty) return fallback;
    return v == '1' || v == 'true' || v == 'yes' || v == 'on';
  }

  int _envInt(String key, [int fallback = 0]) {
    final v = dotenv.env[key];
    if (v == null || v.isEmpty) return fallback;
    return int.tryParse(v) ?? fallback;
  }

  // 是否启用远程后端（ECS）
  bool get enableRemoteBackend => _envBool('ENABLE_REMOTE_BACKEND', false);

  // 服务器基础 URL（例如 https://api.example.com 或 http://<ecs_ip>:8080）
  String get serverBaseUrl => _env('SERVER_BASE_URL');

  // 健康检查路径（可选，默认 /health）
  String get healthPath => _env('HEALTH_PATH', '/health');

  // 网络超时（毫秒）
  int get connectTimeoutMs => _envInt('CONNECT_TIMEOUT_MS', 10000);
  int get receiveTimeoutMs => _envInt('RECEIVE_TIMEOUT_MS', 15000);
  int get sendTimeoutMs => _envInt('SEND_TIMEOUT_MS', 10000);

  // 额外请求头（如需要可扩展）
  Map<String, String> get defaultHeaders => {
        'Accept': 'application/json',
        // 可在这里添加鉴权头，如 'Authorization': 'Bearer <token>'
      };

  // 是否配置完整以启用远程模式
  bool get isRemoteConfigured => enableRemoteBackend && serverBaseUrl.isNotEmpty;

  void debugDump() {
    debugPrint('[Config] ENABLE_REMOTE_BACKEND=$enableRemoteBackend');
    debugPrint('[Config] SERVER_BASE_URL=$serverBaseUrl');
    debugPrint('[Config] HEALTH_PATH=$healthPath');
    debugPrint('[Config] TIMEOUTS: c=$connectTimeoutMs r=$receiveTimeoutMs s=$sendTimeoutMs');
  }
}

