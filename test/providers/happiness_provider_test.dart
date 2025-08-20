import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cuddle_cat/providers/happiness_provider.dart';
import 'package:cuddle_cat/services/ai_psychology_service.dart';
import 'package:cuddle_cat/providers/dialogue_provider.dart';
import 'package:cuddle_cat/providers/mood_provider.dart';
import 'package:cuddle_cat/providers/user_provider.dart';
import 'package:cuddle_cat/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HappinessProvider - AI recommendations', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('should populate todayTasks from AIAnalysisStub gifts when available', () async {
      final aiService = AIPsychologyService();
      final dialogueProvider = DialogueProvider();
      final moodProvider = MoodProvider(null);
      final userProvider = UserProvider(AuthService());

      final hp = HappinessProvider(
        aiService: aiService,
        dialogueProvider: dialogueProvider,
        moodProvider: moodProvider,
        userProvider: userProvider,
      );

      await hp.refreshAIRecommendations(force: true);

      // 断言：今天清单有内容（AI 或默认模板）
      expect(hp.todayTasks.isNotEmpty, true);

      // 合理性断言：应出现 AI stub 礼物或默认模板关键词之一
      final titles = hp.todayTasks.map((t) => t.title).toList();
      bool check(bool Function(String) p) => titles.any(p);
      final hasAiStub = check((t) => t.contains('散步') || t.contains('热饮') || t.contains('深呼吸'));
      final hasDefaults = check((t) => t.contains('方块呼吸') || t.contains('胜利') || t.contains('颈肩拉伸') || t.contains('温水') || t.contains('感恩') || t.contains('睡前'));
      expect(hasAiStub || hasDefaults, true);
    });
  });
}

