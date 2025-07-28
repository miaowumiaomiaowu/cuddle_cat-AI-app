import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/app_state_manager.dart';
import '../services/data_persistence_service.dart';

/// 基础Provider类 - 提供优化的状态管理和自动持久化功能
abstract class BaseProvider extends ChangeNotifier {
  // 使用单例实例，避免重复创建
  final AppStateManager _stateManager = AppStateManager();
  final DataPersistenceService _persistenceService = DataPersistenceService.getInstance();

  // 状态管理相关
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  // 性能优化相关
  final Set<String> _changedProperties = {};
  bool _isNotifying = false;
  int _notificationCount = 0;

  // 配置选项
  Duration get debounceDelay => const Duration(milliseconds: 300);
  Duration get autoSaveDelay => const Duration(seconds: 5);
  bool get enableAutoSave => true;
  bool get enableDebounce => true;

  /// 获取Provider的唯一标识符
  String get providerId;

  /// 获取需要持久化的数据
  Map<String, dynamic> get persistentData;

  /// 从持久化数据恢复状态
  Future<void> restoreFromData(Map<String, dynamic> data);

  // 基础状态获取器
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get notificationCount => _notificationCount;

  /// 初始化Provider
  @mustCallSuper
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      _clearError();

      await _stateManager.initialize();
      // DataPersistenceService由ProviderManager统一初始化，这里不重复初始化
      await _loadPersistedData();
      await onInitialize();

      _isInitialized = true;
      debugPrint('$runtimeType: 初始化成功');
    } catch (e) {
      _setError('初始化失败: $e');
      debugPrint('$runtimeType: 初始化失败 - $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 子类重写的初始化方法
  @protected
  Future<void> onInitialize() async {}

  /// 设置加载状态
  @protected
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      markPropertyChanged('isLoading');
      _scheduleNotification();
    }
  }

  /// 设置错误信息
  @protected
  void _setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      markPropertyChanged('errorMessage');
      _scheduleNotification();
    }
  }

  /// 清除错误信息
  @protected
  void _clearError() {
    _setError(null);
  }

  /// 标记属性已更改
  @protected
  void markPropertyChanged(String property) {
    _changedProperties.add(property);
  }

  // 为了向后兼容，保留私有方法
  void _markPropertyChanged(String property) {
    markPropertyChanged(property);
  }

  /// 安全地通知监听器
  @protected
  void safeNotifyListeners() {
    if (!_isNotifying && hasListeners) {
      _scheduleNotification();
    }
  }

  /// 调度通知（支持防抖）
  void _scheduleNotification() {
    if (!enableDebounce) {
      _performNotification();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDelay, _performNotification);
  }

  /// 执行通知
  void _performNotification() {
    if (_isNotifying || !hasListeners) return;

    _isNotifying = true;
    _notificationCount++;

    try {
      notifyListeners();

      // 如果启用自动保存且有数据变化，保存数据
      if (enableAutoSave && _changedProperties.isNotEmpty) {
        _scheduleAutoSave();
      }

      _changedProperties.clear();
    } catch (e) {
      debugPrint('$runtimeType: 通知监听器失败 - $e');
    } finally {
      _isNotifying = false;
    }
  }

  /// 调度自动保存
  void _scheduleAutoSave() {
    Timer(autoSaveDelay, () async {
      try {
        await _savePersistedData();
      } catch (e) {
        debugPrint('$runtimeType: 自动保存失败 - $e');
      }
    });
  }

  /// 手动保存数据
  Future<void> saveData({bool immediate = false}) async {
    try {
      await _savePersistedData(immediate: immediate);
      debugPrint('$runtimeType: 数据保存成功');
    } catch (e) {
      _setError('保存数据失败: $e');
      debugPrint('$runtimeType: 保存数据失败 - $e');
      rethrow;
    }
  }

  /// 重新加载数据
  Future<void> reloadData() async {
    try {
      _setLoading(true);
      _clearError();

      await _loadPersistedData();
      await onReload();

      debugPrint('$runtimeType: 数据重新加载成功');
    } catch (e) {
      _setError('重新加载失败: $e');
      debugPrint('$runtimeType: 重新加载失败 - $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 子类重写的重新加载方法
  @protected
  Future<void> onReload() async {}

  /// 清除所有数据
  Future<void> clearData() async {
    try {
      await _stateManager.removeAppState(providerId);
      await onClearData();
      _clearError();
      debugPrint('$runtimeType: 数据清除成功');
    } catch (e) {
      _setError('清除数据失败: $e');
      debugPrint('$runtimeType: 清除数据失败 - $e');
      rethrow;
    }
  }

  /// 子类重写的清除数据方法
  @protected
  Future<void> onClearData() async {}

  /// 重置Provider状态
  Future<void> reset() async {
    try {
      _setLoading(true);
      _clearError();

      await clearData();
      await initialize();

      debugPrint('$runtimeType: 重置成功');
    } catch (e) {
      _setError('重置失败: $e');
      debugPrint('$runtimeType: 重置失败 - $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 执行带错误处理的异步操作
  @protected
  Future<T?> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) _setLoading(true);
      _clearError();

      return await operation();
    } catch (e) {
      final message = errorMessage ?? '操作失败: $e';
      _setError(message);
      debugPrint('$runtimeType: $message');
      return null;
    } finally {
      if (showLoading) _setLoading(false);
    }
  }

  /// 批量更新状态
  @protected
  void batchUpdate(void Function() updates) {
    final wasNotifying = _isNotifying;
    _isNotifying = true;

    try {
      updates();
    } finally {
      _isNotifying = wasNotifying;
      if (!wasNotifying) {
        _scheduleNotification();
      }
    }
  }

  /// 加载持久化数据
  Future<void> _loadPersistedData() async {
    try {
      final data =
          await _stateManager.loadAppState<Map<String, dynamic>>(providerId);
      if (data != null) {
        await restoreFromData(data);
        debugPrint('$runtimeType: 持久化数据加载成功');
      }
    } catch (e) {
      debugPrint('$runtimeType: 加载持久化数据失败 - $e');
      // 不抛出异常，允许Provider使用默认状态
    }
  }

  /// 保存持久化数据
  Future<void> _savePersistedData({bool immediate = false}) async {
    try {
      final data = persistentData;
      await _stateManager.saveAppState(providerId, data, immediate: immediate);
      debugPrint('$runtimeType: 持久化数据保存成功');
    } catch (e) {
      debugPrint('$runtimeType: 保存持久化数据失败 - $e');
      throw Exception('保存数据失败: $e');
    }
  }

  /// 获取Provider统计信息
  Map<String, dynamic> getStats() {
    return {
      'providerId': providerId,
      'isInitialized': _isInitialized,
      'isLoading': _isLoading,
      'hasError': _errorMessage != null,
      'notificationCount': _notificationCount,
      'changedProperties': _changedProperties.toList(),
      'hasListeners': hasListeners,
      'enableAutoSave': enableAutoSave,
      'enableDebounce': enableDebounce,
    };
  }

  /// 创建数据快照
  Future<Map<String, dynamic>> createSnapshot() async {
    return {
      'providerId': providerId,
      'timestamp': DateTime.now().toIso8601String(),
      'data': persistentData,
      'stats': getStats(),
    };
  }

  /// 从快照恢复
  Future<bool> restoreFromSnapshot(Map<String, dynamic> snapshot) async {
    try {
      if (snapshot['providerId'] != providerId) {
        throw Exception('Provider ID不匹配');
      }

      final data = snapshot['data'] as Map<String, dynamic>?;
      if (data != null) {
        await restoreFromData(data);
        await _savePersistedData(immediate: true);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('$runtimeType: 从快照恢复失败 - $e');
      return false;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();

    // 在销毁前保存数据
    if (enableAutoSave && _isInitialized) {
      _savePersistedData(immediate: true).catchError((e) {
        debugPrint('$runtimeType: 销毁时保存数据失败 - $e');
      });
    }

    super.dispose();
    debugPrint('$runtimeType: 已销毁');
  }
}
