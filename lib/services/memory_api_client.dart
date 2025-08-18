import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MemoryApiClient {
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

  Future<List<Map<String, dynamic>>> queryMemories({
    required String userId,
    String? query,
    int topK = 3,
  }) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) return const [];
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/memory/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'query': query,
          'top_k': topK,
        }),
      ).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final items = (data['data'] as List?) ?? const [];
          return items.map((e) => (e as Map).cast<String, dynamic>()).toList();
        }
      }
    } catch (e) {
      debugPrint('MemoryApiClient.queryMemories error: $e');
    }
    return const [];
  }
}

