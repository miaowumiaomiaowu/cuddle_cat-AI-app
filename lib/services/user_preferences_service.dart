import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static const _kTone = 'ai_tone'; // cute/cool/funny/gentle/rational/literary/auto
  static const _kAdviceRatio = 'ai_advice_ratio'; // 0..100
  static const _kLang = 'ai_lang_pref'; // auto/zh/en
  static const _kContext = 'ai_context_window'; // short/medium/long

  static Future<String> getTone() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kTone) ?? 'auto';
  }

  static Future<void> setTone(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTone, v);
  }

  static Future<int> getAdviceRatio() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kAdviceRatio) ?? 50;
  }

  static Future<void> setAdviceRatio(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kAdviceRatio, v.clamp(0, 100));
  }

  static Future<String> getLang() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLang) ?? 'auto';
  }

  static Future<void> setLang(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, v);
  }

  static Future<String> getContextWindow() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kContext) ?? 'medium';
  }

  static Future<void> setContextWindow(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kContext, v);
  }
}

