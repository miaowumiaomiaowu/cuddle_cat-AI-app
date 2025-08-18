import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FeedbackApiClient {
  Future<String?> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('ai_analysis_enabled') ?? false;
    if (!enabled) return null;
    final url = prefs.getString('ai_analysis_base_url');
    if (url != null && url.isNotEmpty) return url;
    final server = dotenv.env['SERVER_BASE_URL'];
    if (server != null && server.isNotEmpty) return server;
    return dotenv.env['AI_ANALYSIS_BASE_URL'];
  }

  Future<bool> postFeedback({
    required String feedbackType,
    String? targetType,
    String? targetId,
    double? score,
    String? comment,
  }) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'anonymous';
      final body = {
        'user_id': userId,
        'feedback_type': feedbackType,
        if (targetType != null) 'target_type': targetType,
        if (targetId != null) 'target_id': targetId,
        if (score != null) 'score': score,
        if (comment != null) 'comment': comment,
      };
      final resp = await http
          .post(
            Uri.parse('$baseUrl/feedback'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['status'] == 'success';
      }
    } catch (e) {
      debugPrint('FeedbackApiClient.postFeedback error: $e');
    }
    return false;
  }
}

