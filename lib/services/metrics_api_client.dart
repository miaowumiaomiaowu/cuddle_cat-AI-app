import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MetricsApiClient {
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

  Map<String, String> _headers() {
    final key = dotenv.env['METRICS_API_KEY'];
    return {
      if (key != null && key.isNotEmpty) 'X-API-Key': key,
    };
  }

  Future<Map<String, dynamic>?> fetchMetrics() async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) return null;
    try {
      final resp = await http.get(Uri.parse('$baseUrl/metrics'), headers: _headers());
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['status'] == 'success') return data['data'] as Map<String, dynamic>;
      }
      if (resp.statusCode == 403) {
        return {
          'counters': const <String, dynamic>{},
          'uptime_seconds': 0,
          'error': 'forbidden',
        };
      }
    } catch (_) {}
    return null;
  }
}

