import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_analysis_facade.dart';

class AIAnalysisHttp implements AIAnalysisFacade {
  final String baseUrl;
  final http.Client _client;
  AIAnalysisHttp(this.baseUrl, [http.Client? client]) : _client = client ?? http.Client();

  @override
  Future<AnalysisResult> analyzeAndRecommend(UserSignals input) async {
    try {
      final uri = Uri.parse('$baseUrl/recommend/gifts');
      final resp = await _client
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
            'recentMessages': input.recentMessages,
            'moodRecords': input.moodRecords,
            'stats': input.stats,
          }))
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final gifts = (data['gifts'] as List?)?.map((e) {
          final m = e as Map<String, dynamic>;
          return GiftingTask(
            title: m['title'] as String,
            emoji: (m['emoji'] as String?) ?? '🎁',
            category: (m['category'] as String?) ?? 'gift',
            description: (m['description'] as String?) ?? '',
            estimatedMinutes: (m['estimatedMinutes'] as num?)?.toInt(),
          );
        }).toList() ?? [];
        return AnalysisResult(
          emotions: List<String>.from(data['emotions'] as List? ?? const []),
          scores: Map<String, double>.from((data['scores'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {}),
          gifts: gifts,
        );
      }
    } catch (_) {}
    return AIAnalysisStub().analyzeAndRecommend(input);
  }
}

