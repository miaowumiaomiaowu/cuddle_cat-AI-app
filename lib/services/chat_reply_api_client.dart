import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatReplyApiClient {
  Future<String?> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('ai_analysis_enabled') ?? false;
    if (!enabled) return null;
    final url = prefs.getString('ai_analysis_base_url');
    if (url != null && url.isNotEmpty) return url;
    // Fallback to SERVER_BASE_URL for new config, then legacy AI_ANALYSIS_BASE_URL
    final server = dotenv.env['SERVER_BASE_URL'];
    if (server != null && server.isNotEmpty) return server;
    return dotenv.env['AI_ANALYSIS_BASE_URL'];
  }

  Future<Map<String, dynamic>?> reply({
    required List<Map<String, String>> messages,
    int topK = 3,
  }) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'anonymous';
      final resp = await http
          .post(
            Uri.parse('$baseUrl/chat/reply'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'messages': messages,
              'top_k_memories': topK,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['status'] == 'success') return data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ChatReplyApiClient.reply error: $e');
    }
    return null;
  }
}

