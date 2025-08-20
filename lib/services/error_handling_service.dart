import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'dart:async';

/// 错误处理和用户反馈服务
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final List<AppError> _errorHistory = [];
  StreamController<AppError>? _errorStreamController;

  /// 初始化错误处理服务
  void initialize() {
    _errorStreamController = StreamController<AppError>.broadcast();

    // 设置全局错误处理
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // 设置Zone错误处理
    runZonedGuarded(() {
      // 应用运行在这个Zone中
    }, (error, stackTrace) {
      _handleZoneError(error, stackTrace);
    });
  }

  /// 处理Flutter框架错误
  void _handleFlutterError(FlutterErrorDetails details) {
    final error = AppError(
      type: ErrorType.flutter,
      message: details.exception.toString(),
      stackTrace: details.stack.toString(),
      timestamp: DateTime.now(),
      context: details.context?.toString(),
    );

    _recordError(error);

    if (kDebugMode) {
      debugPrint('Flutter错误: ${error.message}');
      debugPrint('堆栈跟踪: ${error.stackTrace}');
    }
  }

  /// 处理Zone错误
  void _handleZoneError(Object error, StackTrace stackTrace) {
    final appError = AppError(
      type: ErrorType.runtime,
      message: error.toString(),
      stackTrace: stackTrace.toString(),
      timestamp: DateTime.now(),
    );

    _recordError(appError);

    if (kDebugMode) {
      debugPrint('运行时错误: ${appError.message}');
      debugPrint('堆栈跟踪: ${appError.stackTrace}');
    }
  }

  /// 记录应用错误
  void recordError(String message, {
    ErrorType type = ErrorType.application,
    String? stackTrace,
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) {
    final error = AppError(
      type: type,
      message: message,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      context: context,
      severity: severity,
    );

    _recordError(error);
  }

  /// 记录网络错误
  void recordNetworkError(String endpoint, int? statusCode, String message) {
    final error = AppError(
      type: ErrorType.network,
      message: 'Network Error: $message',
      timestamp: DateTime.now(),
      context: 'Endpoint: $endpoint, Status: $statusCode',
      severity: ErrorSeverity.medium,
    );

    _recordError(error);
  }

  /// 记录数据错误
  void recordDataError(String operation, String message) {
    final error = AppError(
      type: ErrorType.data,
      message: 'Data Error: $message',
      timestamp: DateTime.now(),
      context: 'Operation: $operation',
      severity: ErrorSeverity.high,
    );

    _recordError(error);
  }

  /// 显示用户友好的错误消息
  void showUserFriendlyError(BuildContext context, String message, {
    ErrorSeverity severity = ErrorSeverity.medium,
    Duration duration = const Duration(seconds: 4),
  }) {
    Color backgroundColor;
    IconData icon;

    switch (severity) {
      case ErrorSeverity.low:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
      case ErrorSeverity.medium:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case ErrorSeverity.high:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case ErrorSeverity.critical:
        backgroundColor = Colors.red[900]!;
        icon = Icons.dangerous;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: severity == ErrorSeverity.high || severity == ErrorSeverity.critical
            ? SnackBarAction(
                label: '详情',
                textColor: Colors.white,
                onPressed: () => _showErrorDetails(context),
              )
            : null,
      ),
    );
  }

  /// 显示成功消息
  void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示加载状态
  void showLoadingMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示确认对话框
  Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = '确认',
    String cancelText = '取消',
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dialog',
      transitionDuration: AppTheme.motionMedium,
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: AppTheme.easeStandard);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  /// 内部方法：记录错误
  void _recordError(AppError error) {
    _errorHistory.add(error);

    // 限制错误历史记录数量
    if (_errorHistory.length > 100) {
      _errorHistory.removeAt(0);
    }

    // 通知错误流监听者
    _errorStreamController?.add(error);

    // 如果是严重错误，立即处理
    if (error.severity == ErrorSeverity.critical) {
      _handleCriticalError(error);
    }
  }

  /// 处理严重错误
  void _handleCriticalError(AppError error) {
    debugPrint('严重错误: ${error.message}');
    // 这里可以添加崩溃报告、自动重启等逻辑
  }

  /// 显示错误详情
  void _showErrorDetails(BuildContext context) {
    if (_errorHistory.isEmpty) return;

    final recentError = _errorHistory.last;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dialog',
      transitionDuration: AppTheme.motionMedium,
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: AppTheme.easeStandard);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: AlertDialog(
              title: const Text('错误详情'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('类型: ${_getErrorTypeText(recentError.type)}'),
                    const SizedBox(height: 8),
                    Text('时间: ${recentError.timestamp}'),
                    const SizedBox(height: 8),
                    Text('消息: ${recentError.message}'),
                    if (recentError.context != null) ...[
                      const SizedBox(height: 8),
                      Text('上下文: ${recentError.context}'),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('关闭'),
                ),
                if (kDebugMode)
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('复制'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 获取错误类型文本
  String _getErrorTypeText(ErrorType type) {
    switch (type) {
      case ErrorType.flutter:
        return 'Flutter框架错误';
      case ErrorType.runtime:
        return '运行时错误';
      case ErrorType.network:
        return '网络错误';
      case ErrorType.data:
        return '数据错误';
      case ErrorType.application:
        return '应用错误';
    }
  }

  /// 获取错误历史
  List<AppError> getErrorHistory() => List.from(_errorHistory);

  /// 清除错误历史
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  /// 获取错误流
  Stream<AppError>? get errorStream => _errorStreamController?.stream;

  /// 释放资源
  void dispose() {
    _errorStreamController?.close();
    _errorStreamController = null;
  }
}

/// 应用错误模型
class AppError {
  final ErrorType type;
  final String message;
  final String? stackTrace;
  final DateTime timestamp;
  final String? context;
  final ErrorSeverity severity;

  AppError({
    required this.type,
    required this.message,
    this.stackTrace,
    required this.timestamp,
    this.context,
    this.severity = ErrorSeverity.medium,
  });

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, timestamp: $timestamp)';
  }
}

/// 错误类型枚举
enum ErrorType {
  flutter,      // Flutter框架错误
  runtime,      // 运行时错误
  network,      // 网络错误
  data,         // 数据错误
  application,  // 应用逻辑错误
}

/// 错误严重程度枚举
enum ErrorSeverity {
  low,       // 低：信息性错误，不影响功能
  medium,    // 中：警告性错误，可能影响部分功能
  high,      // 高：严重错误，影响主要功能
  critical,  // 严重：致命错误，可能导致崩溃
}
