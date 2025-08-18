

class UserPreferencesService {
  // 已废弃：AI 聊天风格由“猫咪性格”统一决定；这里返回默认值维持兼容，不再持久化新的偏好
  static Future<String> getTone() async => 'auto';
  static Future<void> setTone(String v) async {}

  static Future<int> getAdviceRatio() async => 50;
  static Future<void> setAdviceRatio(int v) async {}

  static Future<String> getLang() async => 'auto';
  static Future<void> setLang(String v) async {}

  static Future<String> getContextWindow() async => 'medium';
  static Future<void> setContextWindow(String v) async {}
}

