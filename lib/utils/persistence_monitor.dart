import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/data_persistence_service.dart';
import '../services/app_state_manager.dart';

/// 数据持久化监控器 - 用于监控和调试数据持久化系统
class PersistenceMonitor {
  static final PersistenceMonitor _instance = PersistenceMonitor._internal();
  factory PersistenceMonitor() => _instance;
  PersistenceMonitor._internal();

  final DataPersistenceService _persistenceService = DataPersistenceService.getInstance();
  final AppStateManager _stateManager = AppStateManager();

  Timer? _monitorTimer;
  final List<PersistenceEvent> _events = [];
  bool _isMonitoring = false;

  // 监控配置
  static const Duration _monitorInterval = Duration(seconds: 30);
  static const int _maxEvents = 100;

  /// 开始监控
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitorTimer = Timer.periodic(_monitorInterval, (timer) async {
      await _performHealthCheck();
    });

    _addEvent(PersistenceEventType.monitorStart, '数据持久化监控已启动');
    debugPrint('PersistenceMonitor: 监控已启动');
  }

  /// 停止监控
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;

    _addEvent(PersistenceEventType.monitorStop, '数据持久化监控已停止');
    debugPrint('PersistenceMonitor: 监控已停止');
  }

  /// 执行健康检查
  Future<void> _performHealthCheck() async {
    try {
      // 检查存储统计
      final storageStats = await _persistenceService.getStorageStats();

      // 检查是否有异常情况
      final totalSize = storageStats['totalSize'] as int? ?? 0;
      final totalKeys = storageStats['totalKeys'] as int? ?? 0;

      if (totalSize > 10 * 1024 * 1024) {
        // 10MB
        _addEvent(PersistenceEventType.warning,
            '存储空间使用过大: ${_formatBytes(totalSize)}');
      }

      if (totalKeys > 1000) {
        _addEvent(PersistenceEventType.warning, '存储键数量过多: $totalKeys');
      }

      // 检查备份文件
      final backupFiles = await _persistenceService.getBackupFiles();
      if (backupFiles.isEmpty) {
        _addEvent(PersistenceEventType.warning, '没有找到备份文件');
      }

      _addEvent(PersistenceEventType.healthCheck,
          '健康检查完成 - 存储: ${_formatBytes(totalSize)}, 键: $totalKeys, 备份: ${backupFiles.length}');
    } catch (e) {
      _addEvent(PersistenceEventType.error, '健康检查失败: $e');
    }
  }

  /// 记录数据操作事件
  void logDataOperation(String operation, String details,
      {bool isError = false}) {
    final eventType = isError
        ? PersistenceEventType.error
        : PersistenceEventType.dataOperation;
    _addEvent(eventType, '$operation: $details');
  }

  /// 记录备份操作事件
  void logBackupOperation(String operation, String details,
      {bool isError = false}) {
    final eventType =
        isError ? PersistenceEventType.error : PersistenceEventType.backup;
    _addEvent(eventType, '$operation: $details');
  }

  /// 记录性能事件
  void logPerformanceEvent(String operation, Duration duration,
      {Map<String, dynamic>? metadata}) {
    final details = '操作: $operation, 耗时: ${duration.inMilliseconds}ms';
    final metadataStr = metadata != null ? ', 元数据: $metadata' : '';
    _addEvent(PersistenceEventType.performance, details + metadataStr);
  }

  /// 添加事件
  void _addEvent(PersistenceEventType type, String message) {
    final event = PersistenceEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
    );

    _events.add(event);

    // 限制事件数量
    if (_events.length > _maxEvents) {
      _events.removeAt(0);
    }

    // 根据事件类型决定是否打印日志
    switch (type) {
      case PersistenceEventType.error:
        debugPrint('PersistenceMonitor [ERROR]: $message');
        break;
      case PersistenceEventType.warning:
        debugPrint('PersistenceMonitor [WARNING]: $message');
        break;
      case PersistenceEventType.performance:
        if (kDebugMode) {
          debugPrint('PersistenceMonitor [PERF]: $message');
        }
        break;
      default:
        if (kDebugMode) {
          debugPrint('PersistenceMonitor [INFO]: $message');
        }
        break;
    }
  }

  /// 获取监控报告
  Future<Map<String, dynamic>> getMonitoringReport() async {
    try {
      final storageStats = await _persistenceService.getStorageStats();
      final stateStats = await _stateManager.getStateStats();
      final backupFiles = await _persistenceService.getBackupFiles();

      // 统计事件类型
      final eventStats = <PersistenceEventType, int>{};
      for (final event in _events) {
        eventStats[event.type] = (eventStats[event.type] ?? 0) + 1;
      }

      return {
        'monitoring': {
          'isActive': _isMonitoring,
          'totalEvents': _events.length,
          'eventStats': eventStats.map((k, v) => MapEntry(k.toString(), v)),
        },
        'storage': storageStats,
        'appState': stateStats,
        'backups': {
          'count': backupFiles.length,
          'files': backupFiles
              .map((f) => {
                    'path': f.path,
                    'size': f.lengthSync(),
                    'modified': f.lastModifiedSync().toIso8601String(),
                  })
              .toList(),
        },
        'recentEvents': _events.take(20).map((e) => e.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    final performanceEvents = _events
        .where((e) => e.type == PersistenceEventType.performance)
        .toList();

    if (performanceEvents.isEmpty) {
      return {'message': '暂无性能数据'};
    }

    // 简单的性能统计
    final operations = <String, List<Duration>>{};

    for (final event in performanceEvents) {
      final message = event.message;
      final operationMatch = RegExp(r'操作: ([^,]+)').firstMatch(message);
      final durationMatch = RegExp(r'耗时: (\d+)ms').firstMatch(message);

      if (operationMatch != null && durationMatch != null) {
        final operation = operationMatch.group(1)!;
        final duration =
            Duration(milliseconds: int.parse(durationMatch.group(1)!));

        operations[operation] ??= [];
        operations[operation]!.add(duration);
      }
    }

    final stats = <String, dynamic>{};
    for (final entry in operations.entries) {
      final durations = entry.value;
      final totalMs = durations.fold(0, (sum, d) => sum + d.inMilliseconds);
      final avgMs = totalMs / durations.length;
      final maxMs = durations
          .map((d) => d.inMilliseconds)
          .reduce((a, b) => a > b ? a : b);
      final minMs = durations
          .map((d) => d.inMilliseconds)
          .reduce((a, b) => a < b ? a : b);

      stats[entry.key] = {
        'count': durations.length,
        'totalMs': totalMs,
        'avgMs': avgMs.round(),
        'maxMs': maxMs,
        'minMs': minMs,
      };
    }

    return stats;
  }

  /// 清除监控事件
  void clearEvents() {
    _events.clear();
    _addEvent(PersistenceEventType.info, '监控事件已清除');
  }

  /// 导出监控数据
  Future<String> exportMonitoringData() async {
    try {
      final report = await getMonitoringReport();
      final performanceStats = getPerformanceStats();

      final exportData = {
        'exportTime': DateTime.now().toIso8601String(),
        'report': report,
        'performance': performanceStats,
        'allEvents': _events.map((e) => e.toMap()).toList(),
      };

      return exportData.toString();
    } catch (e) {
      return 'Export failed: $e';
    }
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// 获取事件列表
  List<PersistenceEvent> get events => List.unmodifiable(_events);

  /// 是否正在监控
  bool get isMonitoring => _isMonitoring;

  /// 销毁监控器
  void dispose() {
    stopMonitoring();
    _events.clear();
  }
}

/// 持久化事件类型
enum PersistenceEventType {
  info,
  warning,
  error,
  dataOperation,
  backup,
  performance,
  healthCheck,
  monitorStart,
  monitorStop,
}

/// 持久化事件
class PersistenceEvent {
  final PersistenceEventType type;
  final String message;
  final DateTime timestamp;

  PersistenceEvent({
    required this.type,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
