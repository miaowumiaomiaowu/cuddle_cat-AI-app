import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_analysis_facade.dart';
import 'ai_trace_service.dart';

class AIAnalysisHttp implements AIAnalysisFacade {
  final String baseUrl;
  final http.Client _client;
  AIAnalysisHttp(this.baseUrl, [http.Client? client]) : _client = client ?? http.Client();

  @override
  Future<AnalysisResult> analyzeAndRecommend(UserSignals input) async {
    final traceId = DateTime.now().microsecondsSinceEpoch.toString();
    final path = '/recommend/gifts';
    try {
      final uri = Uri.parse('$baseUrl$path');
      AiTraceService.instance.recordStart(
        id: traceId,
        baseUrl: baseUrl,
        path: path,
        requestSummary: {
          'recentMessages': input.recentMessages.length,
          'moodRecords': input.moodRecords.length,
          'hasStats': input.stats.isNotEmpty,
        },
      );
      final resp = await _client
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
            'recentMessages': input.recentMessages,
            'moodRecords': input.moodRecords,
            'stats': input.stats,
            'weather': input.weather,
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
            reason: (m['reason'] as String?) ?? m['why'] as String?,
            estimatedMinutes: (m['estimatedMinutes'] as num?)?.toInt(),
          );
        }).toList() ?? [];
        AiTraceService.instance.recordSuccess(
          id: traceId,
          statusCode: resp.statusCode,
          responseSummary: {
            'emotions': (data['emotions'] as List?)?.length ?? 0,
            'scoresKeys': (data['scores'] as Map?)?.length ?? 0,
            'gifts': gifts.length,
          },
        );
        return AnalysisResult(
          emotions: List<String>.from(data['emotions'] as List? ?? const []),
          scores: Map<String, double>.from((data['scores'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {}),
          gifts: gifts,
        );
      }
      AiTraceService.instance.recordError(id: traceId, statusCode: resp.statusCode, error: 'HTTP ${resp.statusCode}');
    } catch (e) {
      AiTraceService.instance.recordError(id: traceId, error: e.toString());
    }
    return AIAnalysisStub().analyzeAndRecommend(input);
  }
}

