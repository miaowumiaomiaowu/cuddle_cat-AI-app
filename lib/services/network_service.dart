import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config_service.dart';

/// 网络请求服务 - 统一封装后端访问（含阿里云ECS）
class NetworkService {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  final http.Client _client = http.Client();

  Uri _buildUri(String pathOrFullUrl, [Map<String, dynamic>? query]) {
    // 如果是完整URL，直接使用
    if (pathOrFullUrl.startsWith('http://') || pathOrFullUrl.startsWith('https://')) {
      final uri = Uri.parse(pathOrFullUrl);
      if (query == null || query.isEmpty) return uri;
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...query.map((k, v) => MapEntry(k, v.toString())),
      });
    }

    // 否则拼接到 baseUrl
    final base = ConfigService.instance.serverBaseUrl;
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = pathOrFullUrl.startsWith('/') ? pathOrFullUrl : '/$pathOrFullUrl';
    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Map<String, String> _headers([Map<String, String>? extra]) {
    return {
      ...ConfigService.instance.defaultHeaders,
      'Content-Type': 'application/json',
      if (extra != null) ...extra,
    };
  }

  Duration get _connectTimeout => Duration(milliseconds: ConfigService.instance.connectTimeoutMs);
  Duration get _receiveTimeout => Duration(milliseconds: ConfigService.instance.receiveTimeoutMs);

  Future<http.Response> get(String pathOrUrl, {Map<String, dynamic>? query, Map<String, String>? headers}) async {
    final uri = _buildUri(pathOrUrl, query);
    if (kDebugMode) debugPrint('[GET] $uri');
    try {
      final response = await _client
          .get(uri, headers: _headers(headers))
          .timeout(_receiveTimeout, onTimeout: () => throw TimeoutException('GET timeout'));
      _ensureSuccess(response);
      return response;
    } on SocketException {
      rethrow;
    }
  }

  Future<http.Response> post(String pathOrUrl, {Object? body, Map<String, String>? headers}) async {
    final uri = _buildUri(pathOrUrl);
    if (kDebugMode) debugPrint('[POST] $uri');
    try {
      final response = await _client
          .post(uri, headers: _headers(headers), body: body is String ? body : jsonEncode(body))
          .timeout(_receiveTimeout, onTimeout: () => throw TimeoutException('POST timeout'));
      _ensureSuccess(response);
      return response;
    } on SocketException {
      rethrow;
    }
  }

  Future<BackendHealth> healthCheck() async {
    final cfg = ConfigService.instance;
    if (!cfg.isRemoteConfigured) {
      return BackendHealth(false, message: '未启用远程后端或未配置SERVER_BASE_URL');
    }
    final uri = _buildUri(cfg.healthPath.startsWith('http') ? cfg.healthPath : cfg.healthPath);
    try {
      final resp = await _client
          .get(uri, headers: _headers())
          .timeout(_connectTimeout, onTimeout: () => throw TimeoutException('Health check timeout'));
      final ok = resp.statusCode >= 200 && resp.statusCode < 300;
      return BackendHealth(ok, statusCode: resp.statusCode, rawBody: resp.body);
    } catch (e) {
      return BackendHealth(false, message: e.toString());
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}

class BackendHealth {
  final bool ok;
  final int? statusCode;
  final String? rawBody;
  final String? message;
  BackendHealth(this.ok, {this.statusCode, this.rawBody, this.message});
}
