import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

/// 性能监控服务
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<int>> _performanceMetrics = {};
  Timer? _memoryMonitorTimer;
  
  bool _isMonitoring = false;

  /// 开始性能监控
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _startMemoryMonitoring();
    debugPrint('性能监控已启动');
  }

  /// 停止性能监控
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _memoryMonitorTimer?.cancel();
    debugPrint('性能监控已停止');
  }

  /// 开始计时
  void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  /// 结束计时并记录
  void endTimer(String operation) {
    final startTime = _startTimes[operation];
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _recordMetric(operation, duration);
    _startTimes.remove(operation);

    if (kDebugMode) {
      debugPrint('性能指标 - $operation: ${duration}ms');
    }
  }

  /// 记录自定义指标
  void recordMetric(String name, int value) {
    _recordMetric(name, value);
  }

  /// 获取性能报告
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    for (final entry in _performanceMetrics.entries) {
      final metrics = entry.value;
      if (metrics.isEmpty) continue;

      final average = metrics.reduce((a, b) => a + b) / metrics.length;
      final min = metrics.reduce((a, b) => a < b ? a : b);
      final max = metrics.reduce((a, b) => a > b ? a : b);

      report[entry.key] = {
        'average': average.round(),
        'min': min,
        'max': max,
        'count': metrics.length,
      };
    }

    return report;
  }

  /// 清除性能数据
  void clearMetrics() {
    _performanceMetrics.clear();
    _startTimes.clear();
  }

  /// 检查应用启动性能
  Future<void> checkAppStartupPerformance() async {
    startTimer('app_startup');
    
    // 模拟启动检查
    await Future.delayed(const Duration(milliseconds: 100));
    
    endTimer('app_startup');
  }

  /// 检查数据库操作性能
  Future<void> measureDatabaseOperation(String operation, Future<void> Function() task) async {
    startTimer('db_$operation');
    
    try {
      await task();
    } finally {
      endTimer('db_$operation');
    }
  }

  /// 检查网络请求性能
  Future<T> measureNetworkRequest<T>(String endpoint, Future<T> Function() request) async {
    startTimer('network_$endpoint');
    
    try {
      return await request();
    } finally {
      endTimer('network_$endpoint');
    }
  }

  /// 检查UI渲染性能
  void measureUIRender(String screenName, VoidCallback renderTask) {
    startTimer('ui_render_$screenName');
    
    renderTask();
    
    // 使用 addPostFrameCallback 确保渲染完成后再结束计时
    WidgetsBinding.instance.addPostFrameCallback((_) {
      endTimer('ui_render_$screenName');
    });
  }

  /// 内存使用监控
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkMemoryUsage();
    });
  }

  /// 检查内存使用情况
  void _checkMemoryUsage() {
    // 在实际项目中，可以使用 dart:developer 的 Service 类来获取内存信息
    // 这里提供一个简化的实现
    if (kDebugMode) {
      debugPrint('内存监控: 定期检查内存使用情况');
    }
  }

  /// 记录指标
  void _recordMetric(String name, int value) {
    _performanceMetrics[name] = _performanceMetrics[name] ?? [];
    _performanceMetrics[name]!.add(value);
    
    // 限制每个指标最多保存100个数据点
    if (_performanceMetrics[name]!.length > 100) {
      _performanceMetrics[name]!.removeAt(0);
    }
  }

  /// 获取应用性能建议
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];
    final report = getPerformanceReport();

    // 检查启动时间
    final startupMetrics = report['app_startup'];
    if (startupMetrics != null && startupMetrics['average'] > 3000) {
      recommendations.add('应用启动时间较长，建议优化初始化流程');
    }

    // 检查数据库操作
    for (final entry in report.entries) {
      if (entry.key.startsWith('db_') && entry.value['average'] > 1000) {
        recommendations.add('数据库操作 ${entry.key} 耗时较长，建议优化查询');
      }
    }

    // 检查网络请求
    for (final entry in report.entries) {
      if (entry.key.startsWith('network_') && entry.value['average'] > 5000) {
        recommendations.add('网络请求 ${entry.key} 响应较慢，建议检查网络连接');
      }
    }

    // 检查UI渲染
    for (final entry in report.entries) {
      if (entry.key.startsWith('ui_render_') && entry.value['average'] > 100) {
        recommendations.add('UI渲染 ${entry.key} 较慢，建议优化界面复杂度');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('应用性能良好，无需特别优化');
    }

    return recommendations;
  }

  /// 导出性能数据
  String exportPerformanceData() {
    final report = getPerformanceReport();
    final recommendations = getPerformanceRecommendations();
    
    final buffer = StringBuffer();
    buffer.writeln('=== 暖猫应用性能报告 ===');
    buffer.writeln('生成时间: ${DateTime.now()}');
    buffer.writeln();
    
    buffer.writeln('性能指标:');
    for (final entry in report.entries) {
      final metrics = entry.value;
      buffer.writeln('${entry.key}:');
      buffer.writeln('  平均值: ${metrics['average']}ms');
      buffer.writeln('  最小值: ${metrics['min']}ms');
      buffer.writeln('  最大值: ${metrics['max']}ms');
      buffer.writeln('  采样数: ${metrics['count']}');
      buffer.writeln();
    }
    
    buffer.writeln('优化建议:');
    for (final recommendation in recommendations) {
      buffer.writeln('• $recommendation');
    }
    
    return buffer.toString();
  }
}

/// 性能监控装饰器
class PerformanceMonitor {
  static final PerformanceService _service = PerformanceService();

  /// 监控异步操作
  static Future<T> monitor<T>(String operation, Future<T> Function() task) async {
    _service.startTimer(operation);
    try {
      return await task();
    } finally {
      _service.endTimer(operation);
    }
  }

  /// 监控同步操作
  static T monitorSync<T>(String operation, T Function() task) {
    _service.startTimer(operation);
    try {
      return task();
    } finally {
      _service.endTimer(operation);
    }
  }

  /// 监控Widget构建
  static Widget monitorBuild(String widgetName, Widget Function() builder) {
    return Builder(
      builder: (context) {
        _service.startTimer('build_$widgetName');
        final widget = builder();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _service.endTimer('build_$widgetName');
        });
        return widget;
      },
    );
  }
}

/// 性能优化工具类
class PerformanceOptimizer {
  /// 预加载关键资源
  static Future<void> preloadCriticalResources() async {
    // 预加载图片资源
    await _preloadImages();
    
    // 预热关键服务
    await _warmupServices();
    
    debugPrint('关键资源预加载完成');
  }

  /// 预加载图片
  static Future<void> _preloadImages() async {
    // 在实际项目中，这里应该预加载关键图片
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 预热服务
  static Future<void> _warmupServices() async {
    // 预热关键服务，如数据库连接、网络连接等
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// 优化列表性能
  static Widget optimizeListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // 启用缓存扩展
      cacheExtent: 200,
      // 添加语义标签
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
    );
  }

  /// 优化图片加载
  static Widget optimizeImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      // 启用缓存
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      // 错误处理
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
    );
  }

  /// 防抖动函数
  static Timer? _debounceTimer;
  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// 节流函数
  static DateTime? _lastThrottleTime;
  static void throttle(Duration interval, VoidCallback callback) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || 
        now.difference(_lastThrottleTime!) >= interval) {
      _lastThrottleTime = now;
      callback();
    }
  }
}
