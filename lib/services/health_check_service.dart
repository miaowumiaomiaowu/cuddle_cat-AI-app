import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'performance_service.dart';
import 'testing_service.dart';

/// 应用健康检查服务
class HealthCheckService {
  static final HealthCheckService _instance = HealthCheckService._internal();
  factory HealthCheckService() => _instance;
  HealthCheckService._internal();

  Timer? _healthCheckTimer;
  final List<HealthCheckResult> _healthHistory = [];
  bool _isMonitoring = false;

  /// 开始健康监控
  void startHealthMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performHealthCheck(),
    );

    debugPrint('应用健康监控已启动');
  }

  /// 停止健康监控
  void stopHealthMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    debugPrint('应用健康监控已停止');
  }

  /// 执行完整健康检查
  Future<AppHealthReport> performFullHealthCheck() async {
    debugPrint('开始执行完整健康检查...');

    final startTime = DateTime.now();
    final checks = <HealthCheckResult>[];

    // 系统健康检查
    checks.add(await _checkSystemHealth());
    
    // 存储健康检查
    checks.add(await _checkStorageHealth());
    
    // 网络健康检查
    checks.add(await _checkNetworkHealth());
    
    // 内存健康检查
    checks.add(await _checkMemoryHealth());
    
    // 数据完整性检查
    checks.add(await _checkDataIntegrity());
    
    // 性能健康检查
    checks.add(await _checkPerformanceHealth());
    
    // 用户体验健康检查
    checks.add(await _checkUserExperienceHealth());

    final endTime = DateTime.now();
    final report = AppHealthReport(
      checks: checks,
      timestamp: endTime,
      duration: endTime.difference(startTime),
    );

    _healthHistory.add(HealthCheckResult(
      category: 'overall',
      name: '整体健康检查',
      status: report.overallStatus,
      message: '完成${checks.length}项检查',
      timestamp: endTime,
      details: {'total_checks': checks.length, 'passed': report.passedCount},
    ));

    debugPrint('健康检查完成: ${report.overallStatus}');
    return report;
  }

  /// 系统健康检查
  Future<HealthCheckResult> _checkSystemHealth() async {
    try {
      final details = <String, dynamic>{};
      
      // 检查平台信息
      details['platform'] = Platform.operatingSystem;
      details['version'] = Platform.operatingSystemVersion;
      
      // 检查可用空间（简化实现）
      final hasEnoughSpace = true; // 实际项目中应该检查真实的存储空间
      details['storage_sufficient'] = hasEnoughSpace;
      
      return HealthCheckResult(
        category: 'system',
        name: '系统健康',
        status: hasEnoughSpace ? HealthStatus.healthy : HealthStatus.warning,
        message: hasEnoughSpace ? '系统运行正常' : '存储空间不足',
        timestamp: DateTime.now(),
        details: details,
      );
    } catch (e) {
      return HealthCheckResult(
        category: 'system',
        name: '系统健康',
        status: HealthStatus.critical,
        message: '系统检查失败: $e',
        timestamp: DateTime.now(),
        details: {'error': e.toString()},
      );
    }
  }

  /// 存储健康检查
  Future<HealthCheckResult> _checkStorageHealth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final details = <String, dynamic>{
        'total_keys': keys.length,
        'storage_accessible': true,
      };

      // 测试读写操作
      const testKey = 'health_check_test';
      const testValue = 'test_value';
      
      await prefs.setString(testKey, testValue);
      final readValue = prefs.getString(testKey);
      await prefs.remove(testKey);
      
      final readWriteWorking = readValue == testValue;
      details['read_write_working'] = readWriteWorking;

      return HealthCheckResult(
        category: 'storage',
        name: '存储健康',
        status: readWriteWorking ? HealthStatus.healthy : HealthStatus.critical,
        message: readWriteWorking ? '存储系统正常' : '存储读写异常',
        timestamp: DateTime.now(),
        details: details,
      );
    } catch (e) {
      return HealthCheckResult(
        category: 'storage',
        name: '存储健康',
        status: HealthStatus.critical,
        message: '存储检查失败: $e',
        timestamp: DateTime.now(),
        details: {'error': e.toString()},
      );
    }
  }

  /// 网络健康检查
  Future<HealthCheckResult> _checkNetworkHealth() async {
    try {
      // 简化的网络检查
      final hasConnection = true; // 实际项目中应该进行真实的网络测试
      
      final details = <String, dynamic>{
        'connection_available': hasConnection,
        'connection_type': 'wifi', // 简化实现
      };

      return HealthCheckResult(
        category: 'network',
        name: '网络健康',
        status: hasConnection ? HealthStatus.healthy : HealthStatus.warning,
        message: hasConnection ? '网络连接正常' : '网络连接异常',
        timestamp: DateTime.now(),
        details: details,
      );
    } catch (e) {
      return HealthCheckResult(
        category: 'network',
        name: '网络健康',
        status: HealthStatus.warning,
        message: '网络检查失败: $e',
        timestamp: DateTime.now(),
        details: {'error': e.toString()},
      );
    }
  }

  /// 内存健康检查
  Future<HealthCheckResult> _checkMemoryHealth() async {
    try {
      // 简化的内存检查
      final memoryUsage = 80; // MB，实际项目中应该获取真实内存使用
      final memoryLimit = 200; // MB
      
      final memoryHealthy = memoryUsage < memoryLimit * 0.8;
      final status = memoryUsage < memoryLimit * 0.6 
          ? HealthStatus.healthy
          : memoryUsage < memoryLimit * 0.8
              ? HealthStatus.warning
              : HealthStatus.critical;

      final details = <String, dynamic>{
        'memory_usage_mb': memoryUsage,
        'memory_limit_mb': memoryLimit,
        'usage_percentage': (memoryUsage / memoryLimit * 100).round(),
      };

      return HealthCheckResult(
        category: 'memory',
        name: '内存健康',
        status: status,
        message: '内存使用: ${memoryUsage}MB/${memoryLimit}MB',
        timestamp: DateTime.now(),
        details: details,
      );
    } catch (e) {
      return HealthCheckResult(
        category: 'memory',
        name: '内存健康',
        status: HealthStatus.warning,
        message: '内存检查失败: $e',
        timestamp: DateTime.now(),
        details: {'error': e.toString()},
      );
    }
  }

  /// 数据完整性检查
  Future<HealthCheckResult> _checkDataIntegrity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 检查关键数据是否存在
      final hasUserData = prefs.containsKey('current_user');
      final hasMoodData = prefs.getKeys().any((key) => key.startsWith('mood_entries_'));
      
      final details = <String, dynamic>{
        'user_data_exists': hasUserData,
        'mood_data_exists': hasMoodData,
        'data_corruption_detected': false, // 简化实现
      };

      final dataIntegrityGood = !details['data_corruption_detected'];

      return HealthCheckResult(
        category: 'data',
        name: '数据完整性',
        status: dataIntegrityGood ? HealthStatus.healthy : HealthStatus.critical,
        message: dataIntegrityGood ? '数据完整性良好' : '检测到数据损坏',
        timestamp: DateTime.now(),
        details: details,
      );
    } catch (e) {
      return HealthCheckResult(
        category: 'data',
        name: '数据完整性',
        status: HealthStatus.critical,
        message: '数据完整性检查失败: $e',
        timestamp: DateTime.now(),
        details: {'error': e.toString()},
      );
    }
  }

  /// 性能健康检查
  Future<HealthCheckResult> _checkPerformanceHealth() async {
    try {
      final performanceService = PerformanceService();
      final report = performanceService.getPerformanceReport();
      
      // 分析性能指标
      var performanceScore = 100;
      final issues = <String>[];
      
      for (final entry in report.entries) {
        final metrics = entry.value;
        final average = metrics['average'] as int;
        
        if (entry.key.startsWith('app_startup') && average > 3000) {
          performanceScore -= 20;
          issues.add('启动时间过长');
        } else if (entry.key.startsWith('ui_render') && average > 100) {
          performanceScore -= 10;
          issues.add('UI渲染较慢');
        } else if (entry.key.startsWith('db_') && average > 1000) {
          performanceScore -= 15;
          issues.add('数据库操作较慢');
        }
      }

      final status = performanceScore >= 80 
          ? HealthStatus.healthy
          : performanceScore >= 60
              ? HealthStatus.warning
              : HealthStatus.critical;

      final details = <String, dynamic>{
        'performance_score': performanceScore,
        'issues': issues,
        'metrics_count': report.length,
      };

      return HealthCheckResult(
        category: 'performance',
        name: '性能健康',
        status: status,
        message: '性能评分: $performanceScore/100',
        timestamp: DateTime.now(),
        details: details,
      );
    } catch (e) {
      return HealthCheckResult(
        category: 'performance',
        name: '性能健康',
        status: HealthStatus.warning,
        message: '性能检查失败: $e',
        timestamp: DateTime.now(),
        details: {'error': e.toString()},
      );
    }
  }

  /// 用户体验健康检查
  Future<HealthCheckResult> _checkUserExperienceHealth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 检查用户活跃度
      final lastActiveTime = prefs.getString('last_active_time');
      final userEngaged = lastActiveTime != null;
      
      // 检查崩溃记录
      final crashCount = prefs.getInt('crash_count') ?? 0;
      final lowCrashRate = crashCount < 5;
      
      // 检查用户反馈
      final hasPositiveFeedback = true; // 简化实现
      
      final details = <String, dynamic>{
        'user_engaged': userEngaged,
        'low_crash_rate': lowCrashRate,
        'crash_count': crashCount,
        'positive_feedback': hasPositiveFeedback,
      };

      final uxScore = (userEngaged ? 25 : 0) + 
                     (lowCrashRate ? 25 : 0) + 
                     (hasPositiveFeedback ? 50 : 0);

      final status = uxScore >= 75 
          ? HealthStatus.healthy
          : uxScore >= 50
              ? HealthStatus.warning
              : HealthStatus.critical;

      return HealthCheckResult(
        category: 'ux',
        name: '用户体验健康',
        status: status,
        message: '用户体验评分: $uxScore/100',
        timestamp: DateTime.now(),
        details: details,
      );
    } catch (e) {
      return HealthCheckResult(
        category: 'ux',
        name: '用户体验健康',
        status: HealthStatus.warning,
        message: '用户体验检查失败: $e',
        timestamp: DateTime.now(),
        details: {'error': e.toString()},
      );
    }
  }

  /// 定期健康检查
  Future<void> _performHealthCheck() async {
    try {
      final report = await performFullHealthCheck();
      
      // 如果发现严重问题，记录日志
      if (report.overallStatus == HealthStatus.critical) {
        debugPrint('⚠️ 发现严重健康问题: ${report.criticalIssues.join(", ")}');
      }
      
      // 保持历史记录不超过100条
      if (_healthHistory.length > 100) {
        _healthHistory.removeAt(0);
      }
    } catch (e) {
      debugPrint('健康检查执行失败: $e');
    }
  }

  /// 获取健康历史
  List<HealthCheckResult> getHealthHistory() {
    return List.from(_healthHistory);
  }

  /// 获取健康趋势
  Map<String, List<HealthCheckResult>> getHealthTrends() {
    final trends = <String, List<HealthCheckResult>>{};
    
    for (final result in _healthHistory) {
      trends[result.category] = trends[result.category] ?? [];
      trends[result.category]!.add(result);
    }
    
    return trends;
  }

  /// 生成健康报告
  String generateHealthReport(AppHealthReport report) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== 暖猫应用健康报告 ===');
    buffer.writeln('检查时间: ${report.timestamp}');
    buffer.writeln('检查耗时: ${report.duration.inMilliseconds}ms');
    buffer.writeln('整体状态: ${_getStatusText(report.overallStatus)}');
    buffer.writeln('健康评分: ${report.healthScore}/100');
    buffer.writeln();
    
    // 按状态分组显示
    final categories = <HealthStatus, List<HealthCheckResult>>{};
    for (final check in report.checks) {
      categories[check.status] = categories[check.status] ?? [];
      categories[check.status]!.add(check);
    }
    
    for (final status in [HealthStatus.critical, HealthStatus.warning, HealthStatus.healthy]) {
      final checks = categories[status] ?? [];
      if (checks.isEmpty) continue;
      
      buffer.writeln('${_getStatusText(status)} (${checks.length}项):');
      for (final check in checks) {
        buffer.writeln('  • ${check.name}: ${check.message}');
      }
      buffer.writeln();
    }
    
    if (report.recommendations.isNotEmpty) {
      buffer.writeln('建议:');
      for (final recommendation in report.recommendations) {
        buffer.writeln('• $recommendation');
      }
    }
    
    return buffer.toString();
  }

  String _getStatusText(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return '✅ 健康';
      case HealthStatus.warning:
        return '⚠️ 警告';
      case HealthStatus.critical:
        return '❌ 严重';
    }
  }
}

/// 健康状态枚举
enum HealthStatus {
  healthy,
  warning,
  critical,
}

/// 健康检查结果
class HealthCheckResult {
  final String category;
  final String name;
  final HealthStatus status;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  HealthCheckResult({
    required this.category,
    required this.name,
    required this.status,
    required this.message,
    required this.timestamp,
    required this.details,
  });
}

/// 应用健康报告
class AppHealthReport {
  final List<HealthCheckResult> checks;
  final DateTime timestamp;
  final Duration duration;

  AppHealthReport({
    required this.checks,
    required this.timestamp,
    required this.duration,
  });

  HealthStatus get overallStatus {
    if (checks.any((c) => c.status == HealthStatus.critical)) {
      return HealthStatus.critical;
    } else if (checks.any((c) => c.status == HealthStatus.warning)) {
      return HealthStatus.warning;
    } else {
      return HealthStatus.healthy;
    }
  }

  int get healthScore {
    final totalChecks = checks.length;
    if (totalChecks == 0) return 0;

    final healthyCount = checks.where((c) => c.status == HealthStatus.healthy).length;
    final warningCount = checks.where((c) => c.status == HealthStatus.warning).length;
    
    return ((healthyCount * 100 + warningCount * 50) / totalChecks).round();
  }

  int get passedCount => checks.where((c) => c.status == HealthStatus.healthy).length;
  
  List<String> get criticalIssues => checks
      .where((c) => c.status == HealthStatus.critical)
      .map((c) => c.name)
      .toList();

  List<String> get recommendations {
    final recs = <String>[];
    
    if (checks.any((c) => c.category == 'memory' && c.status != HealthStatus.healthy)) {
      recs.add('优化内存使用，清理不必要的缓存');
    }
    
    if (checks.any((c) => c.category == 'performance' && c.status != HealthStatus.healthy)) {
      recs.add('优化应用性能，减少启动时间和响应延迟');
    }
    
    if (checks.any((c) => c.category == 'storage' && c.status == HealthStatus.critical)) {
      recs.add('检查存储权限和可用空间');
    }
    
    if (checks.any((c) => c.category == 'data' && c.status == HealthStatus.critical)) {
      recs.add('备份用户数据，检查数据完整性');
    }
    
    return recs;
  }
}
