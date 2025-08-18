import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wellness_plan.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WellnessPlanService {
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

  Future<WellnessPlan?> fetchPlan({
    required List<String> recentMessages,
    required List<Map<String, dynamic>> moodRecords,
    required Map<String, dynamic> stats,
    Map<String, dynamic>? weather,
  }) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) return null;

    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/recommend/wellness-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recentMessages': recentMessages,
          'moodRecords': moodRecords,
          'stats': stats,
          'weather': weather,
        }),
      ).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['status'] == 'success' && data['data'] is Map<String, dynamic>) {
          return WellnessPlan.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('fetchPlan error: $e');
    }

    return null;
  }
}

