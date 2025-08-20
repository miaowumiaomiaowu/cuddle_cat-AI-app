import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SystemHealthService {
  static const String _healthCheckKey = 'last_health_check';
  static const String _systemStatsKey = 'system_stats';
  
  Future<SystemHealthReport> performHealthCheck() async {
    final report = SystemHealthReport();
    
    try {
      // 检查本地存储
      await _checkLocalStorage(report);
      
      // 检查网络连接
      await _checkNetworkConnectivity(report);
      
      // 检查AI服务
      await _checkAIServices(report);
      
      // 检查数据完整性
      await _checkDataIntegrity(report);
      
      // 检查性能指标
      await _checkPerformanceMetrics(report);
      
      // 保存健康检查结果
      await _saveHealthCheckResult(report);
      
    } catch (e) {
      report.addError('健康检查失败', e.toString());
    }
    
    return report;
  }

  Future<void> _checkLocalStorage(SystemHealthReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 检查关键配置
      final aiEnabled = prefs.getBool('ai_analysis_enabled');
      final baseUrl = prefs.getString('ai_analysis_base_url');
      
      report.addCheck('AI分析配置', aiEnabled != null ? '已配置' : '未配置');
      report.addCheck('服务端地址', baseUrl?.isNotEmpty == true ? '已设置' : '未设置');
      
      // 检查存储空间
      final keys = prefs.getKeys();
      report.addCheck('本地存储项目数', keys.length.toString());
      
      // 检查数据大小（估算）
      int totalSize = 0;
      for (final key in keys) {
        final value = prefs.get(key);
        if (value is String) {
          totalSize += value.length;
        }
      }
      report.addCheck('本地存储大小', '${(totalSize / 1024).toStringAsFixed(1)} KB');
      
    } catch (e) {
      report.addError('本地存储检查', e.toString());
    }
  }

  Future<void> _checkNetworkConnectivity(SystemHealthReport report) async {
    try {
      // 检查基本网络连接
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        report.addCheck('网络连接', '正常');
      } else {
        report.addError('网络连接', '无法连接到互联网');
      }
      
    } catch (e) {
      report.addError('网络连接', '网络检查失败: $e');
    }
  }

  Future<void> _checkAIServices(SystemHealthReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('ai_analysis_enabled') ?? false;
      final baseUrl = prefs.getString('ai_analysis_base_url');
      
      if (!enabled || baseUrl == null || baseUrl.isEmpty) {
        report.addCheck('AI服务', '已禁用');
        return;
      }
      
      // 检查服务端健康状态
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        report.addCheck('AI服务状态', data['status'] ?? '未知');
        report.addCheck('AI服务名称', data['service'] ?? '未知');
      } else {
        report.addError('AI服务', '服务响应异常: ${response.statusCode}');
      }
      
      // 检查学习系统状态
      try {
        final statsResponse = await http.get(
          Uri.parse('$baseUrl/learning/system-stats'),
        ).timeout(const Duration(seconds: 5));
        
        if (statsResponse.statusCode == 200) {
          final statsData = jsonDecode(statsResponse.body);
          if (statsData['status'] == 'success') {
            final data = statsData['data'];
            report.addCheck('学习系统用户数', data['total_users']?.toString() ?? '0');
            
            // 检查各个模型状态
            final moodPredictor = data['mood_predictor'];
            if (moodPredictor != null) {
              report.addCheck('心情预测模型', 
                moodPredictor['is_initialized'] == true ? '已训练' : '未训练');
              report.addCheck('心情模型样本数', 
                moodPredictor['sample_count']?.toString() ?? '0');
            }
          }
        }
      } catch (e) {
        report.addWarning('学习系统检查', '无法获取学习系统状态');
      }
      
    } catch (e) {
      report.addError('AI服务检查', e.toString());
    }
  }

  Future<void> _checkDataIntegrity(SystemHealthReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 检查心情记录
      final moodData = prefs.getString('mood_entries');
      if (moodData != null) {
        try {
          final moodList = jsonDecode(moodData) as List;
          report.addCheck('心情记录数量', moodList.length.toString());
          
          // 检查最近的记录
          if (moodList.isNotEmpty) {
            final latest = moodList.last;
            final timestamp = DateTime.parse(latest['timestamp']);
            final daysSince = DateTime.now().difference(timestamp).inDays;
            report.addCheck('最近心情记录', '$daysSince天前');
          }
        } catch (e) {
          report.addError('心情记录格式', '数据格式错误');
        }
      } else {
        report.addCheck('心情记录数量', '0');
      }
      
      // 检查任务数据
      final tasksData = prefs.getString('happiness_tasks');
      if (tasksData != null) {
        try {
          final tasksList = jsonDecode(tasksData) as List;
          report.addCheck('任务数量', tasksList.length.toString());
        } catch (e) {
          report.addError('任务数据格式', '数据格式错误');
        }
      } else {
        report.addCheck('任务数量', '0');
      }
      
    } catch (e) {
      report.addError('数据完整性检查', e.toString());
    }
  }

  Future<void> _checkPerformanceMetrics(SystemHealthReport report) async {
    try {
      // 检查应用启动时间（模拟）
      final startTime = DateTime.now();
      await Future.delayed(const Duration(milliseconds: 100));
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      report.addCheck('模拟加载时间', '${loadTime}ms');
      
      // 检查内存使用（在debug模式下）
      if (kDebugMode) {
        report.addCheck('运行模式', 'Debug');
      } else {
        report.addCheck('运行模式', 'Release');
      }
      
      // 检查平台信息
      report.addCheck('平台', Platform.operatingSystem);
      
    } catch (e) {
      report.addError('性能指标检查', e.toString());
    }
  }

  Future<void> _saveHealthCheckResult(SystemHealthReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_healthCheckKey, DateTime.now().toIso8601String());
      await prefs.setString(_systemStatsKey, jsonEncode(report.toJson()));
    } catch (e) {
      debugPrint('保存健康检查结果失败: $e');
    }
  }

  Future<DateTime?> getLastHealthCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(_healthCheckKey);
      if (timeStr != null) {
        return DateTime.parse(timeStr);
      }
    } catch (e) {
      debugPrint('获取上次健康检查时间失败: $e');
    }
    return null;
  }

  Future<SystemHealthReport?> getLastHealthReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportStr = prefs.getString(_systemStatsKey);
      if (reportStr != null) {
        final json = jsonDecode(reportStr);
        return SystemHealthReport.fromJson(json);
      }
    } catch (e) {
      debugPrint('获取上次健康报告失败: $e');
    }
    return null;
  }
}

class SystemHealthReport {
  final List<HealthCheck> checks = [];
  final List<HealthError> errors = [];
  final List<HealthWarning> warnings = [];
  final DateTime timestamp = DateTime.now();

  SystemHealthReport();

  void addCheck(String name, String status) {
    checks.add(HealthCheck(name: name, status: status));
  }

  void addError(String category, String message) {
    errors.add(HealthError(category: category, message: message));
  }

  void addWarning(String category, String message) {
    warnings.add(HealthWarning(category: category, message: message));
  }

  bool get isHealthy => errors.isEmpty;
  
  String get overallStatus {
    if (errors.isNotEmpty) return '异常';
    if (warnings.isNotEmpty) return '警告';
    return '正常';
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'checks': checks.map((c) => c.toJson()).toList(),
    'errors': errors.map((e) => e.toJson()).toList(),
    'warnings': warnings.map((w) => w.toJson()).toList(),
  };

  factory SystemHealthReport.fromJson(Map<String, dynamic> json) {
    final report = SystemHealthReport();
    
    final checksJson = json['checks'] as List? ?? [];
    for (final checkJson in checksJson) {
      report.checks.add(HealthCheck.fromJson(checkJson));
    }
    
    final errorsJson = json['errors'] as List? ?? [];
    for (final errorJson in errorsJson) {
      report.errors.add(HealthError.fromJson(errorJson));
    }
    
    final warningsJson = json['warnings'] as List? ?? [];
    for (final warningJson in warningsJson) {
      report.warnings.add(HealthWarning.fromJson(warningJson));
    }
    
    return report;
  }
}

class HealthCheck {
  final String name;
  final String status;

  HealthCheck({required this.name, required this.status});

  Map<String, dynamic> toJson() => {'name': name, 'status': status};
  
  factory HealthCheck.fromJson(Map<String, dynamic> json) => HealthCheck(
    name: json['name'] as String,
    status: json['status'] as String,
  );
}

class HealthError {
  final String category;
  final String message;

  HealthError({required this.category, required this.message});

  Map<String, dynamic> toJson() => {'category': category, 'message': message};
  
  factory HealthError.fromJson(Map<String, dynamic> json) => HealthError(
    category: json['category'] as String,
    message: json['message'] as String,
  );
}

class HealthWarning {
  final String category;
  final String message;

  HealthWarning({required this.category, required this.message});

  Map<String, dynamic> toJson() => {'category': category, 'message': message};
  
  factory HealthWarning.fromJson(Map<String, dynamic> json) => HealthWarning(
    category: json['category'] as String,
    message: json['message'] as String,
  );
}
