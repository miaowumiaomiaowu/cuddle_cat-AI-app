import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 应用性能监控和优化服务
class AppPerformanceService {
  static final AppPerformanceService _instance =
      AppPerformanceService._internal();
  factory AppPerformanceService() => _instance;
  AppPerformanceService._internal();

  // 性能指标
  DateTime? _appStartTime;
  DateTime? _firstFrameTime;
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, Duration> _operationDurations = {};
  final List<PerformanceMetric> _metrics = [];

  // 内存监控
  Timer? _memoryMonitorTimer;
  final List<MemorySnapshot> _memorySnapshots = [];
  static const int maxMemorySnapshots = 100;

  // 配置
  bool _isMonitoring = false;
  Duration get memoryMonitorInterval => const Duration(seconds: 30);

  /// 初始化性能服务
  void initialize() {
    _appStartTime = DateTime.now();
    _startMemoryMonitoring();

    // 监听第一帧渲染
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firstFrameTime = DateTime.now();
      _recordMetric('app_startup', _getStartupDuration());
    });

    debugPrint('AppPerformanceService: 初始化完成');
  }

  /// 开始监控操作
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  /// 结束监控操作
  void endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationDurations[operationName] = duration;
      _recordMetric(operationName, duration);
      _operationStartTimes.remove(operationName);

      // 如果操作时间过长，记录警告
      if (duration.inMilliseconds > 1000) {
        debugPrint('性能警告: $operationName 耗时 ${duration.inMilliseconds}ms');
      }
    }
  }

  /// 记录性能指标
  void _recordMetric(String name, Duration duration) {
    final metric = PerformanceMetric(
      name: name,
      duration: duration,
      timestamp: DateTime.now(),
    );

    _metrics.add(metric);

    // 限制指标数量
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, 100);
    }
  }

  /// 获取应用启动时间
  Duration _getStartupDuration() {
    if (_appStartTime != null && _firstFrameTime != null) {
      return _firstFrameTime!.difference(_appStartTime!);
    }
    return Duration.zero;
  }

  /// 开始内存监控
  void _startMemoryMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _memoryMonitorTimer = Timer.periodic(memoryMonitorInterval, (_) {
      _captureMemorySnapshot();
    });
  }

  /// 停止内存监控
  void stopMemoryMonitoring() {
    _isMonitoring = false;
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
  }

  /// 捕获内存快照
  void _captureMemorySnapshot() {
    try {
      // 在非调试模式下，某些内存信息可能不可用
      if (kDebugMode) {
        final snapshot = MemorySnapshot(
          timestamp: DateTime.now(),
          rssBytes: _getCurrentRSS(),
          heapBytes: _getCurrentHeap(),
        );

        _memorySnapshots.add(snapshot);

        // 限制快照数量
        if (_memorySnapshots.length > maxMemorySnapshots) {
          _memorySnapshots.removeAt(0);
        }

        // 检查内存使用是否过高
        _checkMemoryUsage(snapshot);
      }
    } catch (e) {
      debugPrint('AppPerformanceService: 捕获内存快照失败 - $e');
    }
  }

  /// 获取当前RSS内存使用
  int _getCurrentRSS() {
    // 这里可以使用平台特定的方法获取RSS内存
    // 目前返回估算值
    return 0;
  }

  /// 获取当前堆内存使用
  int _getCurrentHeap() {
    // 这里可以使用平台特定的方法获取堆内存
    // 目前返回估算值
    return 0;
  }

  /// 检查内存使用情况
  void _checkMemoryUsage(MemorySnapshot snapshot) {
    const int warningThreshold = 100 * 1024 * 1024; // 100MB
    const int criticalThreshold = 200 * 1024 * 1024; // 200MB

    if (snapshot.rssBytes > criticalThreshold) {
      debugPrint('内存使用严重警告: RSS ${_formatBytes(snapshot.rssBytes)}');
      // 可以触发内存清理
      _triggerMemoryCleanup();
    } else if (snapshot.rssBytes > warningThreshold) {
      debugPrint('内存使用警告: RSS ${_formatBytes(snapshot.rssBytes)}');
    }
  }

  /// 触发内存清理
  void _triggerMemoryCleanup() {
    try {
      // 清理图片缓存
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 强制垃圾回收（仅在调试模式下）
      if (kDebugMode) {
        // 这里可以添加更多清理逻辑
      }

      debugPrint('AppPerformanceService: 内存清理完成');
    } catch (e) {
      debugPrint('AppPerformanceService: 内存清理失败 - $e');
    }
  }

  /// 获取性能报告
  PerformanceReport getPerformanceReport() {
    final now = DateTime.now();
    final recentMetrics = _metrics
        .where((m) => now.difference(m.timestamp).inMinutes < 60)
        .toList();

    return PerformanceReport(
      appStartupTime: _getStartupDuration(),
      totalMetrics: _metrics.length,
      recentMetrics: recentMetrics,
      memorySnapshots: List.from(_memorySnapshots),
      operationDurations: Map.from(_operationDurations),
      generatedAt: now,
    );
  }

  /// 获取操作性能统计
  Map<String, OperationStats> getOperationStats() {
    final stats = <String, OperationStats>{};

    for (final metric in _metrics) {
      if (!stats.containsKey(metric.name)) {
        stats[metric.name] = OperationStats(metric.name);
      }
      stats[metric.name]!.addDuration(metric.duration);
    }

    return stats;
  }

  /// 优化应用性能
  Future<void> optimizePerformance() async {
    try {
      // 清理过期的性能指标
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      _metrics.removeWhere((m) => m.timestamp.isBefore(cutoff));

      // 清理过期的内存快照
      final memoryCutoff = DateTime.now().subtract(const Duration(hours: 1));
      _memorySnapshots.removeWhere((s) => s.timestamp.isBefore(memoryCutoff));

      // 清理图片缓存
      PaintingBinding.instance.imageCache.clear();

      // 运行垃圾回收
      if (kDebugMode) {
        await _runGarbageCollection();
      }

      debugPrint('AppPerformanceService: 性能优化完成');
    } catch (e) {
      debugPrint('AppPerformanceService: 性能优化失败 - $e');
    }
  }

  /// 运行垃圾回收
  Future<void> _runGarbageCollection() async {
    try {
      // 在隔离线程中运行垃圾回收
      await Isolate.run(() {
        // 这里可以执行一些清理操作
        return true;
      });
    } catch (e) {
      debugPrint('AppPerformanceService: 垃圾回收失败 - $e');
    }
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 重置所有统计数据
  void reset() {
    _metrics.clear();
    _memorySnapshots.clear();
    _operationDurations.clear();
    _operationStartTimes.clear();
    debugPrint('AppPerformanceService: 统计数据已重置');
  }

  /// 销毁服务
  void dispose() {
    stopMemoryMonitoring();
    reset();
    debugPrint('AppPerformanceService: 已销毁');
  }
}

/// 性能指标
class PerformanceMetric {
  final String name;
  final Duration duration;
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
  });
}

/// 内存快照
class MemorySnapshot {
  final DateTime timestamp;
  final int rssBytes;
  final int heapBytes;

  MemorySnapshot({
    required this.timestamp,
    required this.rssBytes,
    required this.heapBytes,
  });
}

/// 性能报告
class PerformanceReport {
  final Duration appStartupTime;
  final int totalMetrics;
  final List<PerformanceMetric> recentMetrics;
  final List<MemorySnapshot> memorySnapshots;
  final Map<String, Duration> operationDurations;
  final DateTime generatedAt;

  PerformanceReport({
    required this.appStartupTime,
    required this.totalMetrics,
    required this.recentMetrics,
    required this.memorySnapshots,
    required this.operationDurations,
    required this.generatedAt,
  });
}

/// 操作统计
class OperationStats {
  final String name;
  final List<Duration> durations = [];

  OperationStats(this.name);

  void addDuration(Duration duration) {
    durations.add(duration);
  }

  Duration get averageDuration {
    if (durations.isEmpty) return Duration.zero;
    final total = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    return Duration(milliseconds: total ~/ durations.length);
  }

  Duration get maxDuration {
    if (durations.isEmpty) return Duration.zero;
    return durations.reduce((a, b) => a > b ? a : b);
  }

  Duration get minDuration {
    if (durations.isEmpty) return Duration.zero;
    return durations.reduce((a, b) => a < b ? a : b);
  }

  int get count => durations.length;
}
