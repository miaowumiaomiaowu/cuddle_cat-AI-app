import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config_service.dart';

class AuthApiClient {
  final http.Client _client;
  AuthApiClient({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path) {
    final base = ConfigService.instance.serverBaseUrl;
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final resp = await _client.post(
      _uri('/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Register failed: HTTP ${resp.statusCode} ${resp.body}');
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await _client.post(
      _uri('/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Login failed: HTTP ${resp.statusCode} ${resp.body}');
  }
}

