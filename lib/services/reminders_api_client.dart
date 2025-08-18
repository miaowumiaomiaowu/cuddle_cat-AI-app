import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RemindersApiClient {
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

  Future<List<String>> getSuggestions({required String userId, int limit = 5}) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) return [];
    final resp = await http.get(Uri.parse('$baseUrl/reminders/suggestions/$userId?limit=$limit'));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['status'] == 'success') {
        final List list = data['data'] as List? ?? [];
        return list.map((e) => (e as Map<String, dynamic>)['text'] as String).toList();
      }
    }
    return [];
  }
}

