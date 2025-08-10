import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'data_persistence_service.dart';

/// 应用状态管理器 - 负责应用状态的自动保存和恢复
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();

  final DataPersistenceService _persistenceService = DataPersistenceService.getInstance();

  // 状态保存相关
  Timer? _autoSaveTimer;
  final Map<String, dynamic> _pendingChanges = {};
  bool _isInitialized = false;
  bool _isInitializing = false;

  // 应用生命周期相关
  AppLifecycleState? _lastLifecycleState;

  // 状态键常量
  static const String _appStateKey = 'app_state';
  static const String _lastActiveTimeKey = 'last_active_time';
  static const String _sessionIdKey = 'session_id';
  static const String _appVersionKey = 'app_version';

  // 自动保存间隔
  static const Duration _autoSaveInterval = Duration(seconds: 30);
  static const Duration _immediateStateKeys = Duration(seconds: 5);

  /// 初始化状态管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 如果正在初始化，等待完成
    if (_isInitializing) {
      while (_isInitializing && !_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return;
    }

    _isInitializing = true;

    try {
      // DataPersistenceService由ProviderManager统一初始化，这里不重复初始化
      await _restoreAppState();
      _startAutoSave();
      _setupLifecycleListener();

      _isInitialized = true;
      debugPrint('AppStateManager: 初始化成功');
    } catch (e) {
      debugPrint('AppStateManager: 初始化失败 - $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 保存应用状态
  Future<void> saveAppState(String key, dynamic value,
      {bool immediate = false}) async {
    if (!_isInitialized) {
      debugPrint('AppStateManager: 尚未初始化，跳过保存操作');
      return;
    }

    try {
      _pendingChanges[key] = value;

      if (immediate) {
        await _flushPendingChanges();
      }

      debugPrint('AppStateManager: 状态已标记保存 [$key]');
    } catch (e) {
      debugPrint('AppStateManager: 保存状态失败 [$key] - $e');
    }
  }

  /// 读取应用状态
  Future<T?> loadAppState<T>(String key, {T? defaultValue}) async {
    if (!_isInitialized) {
      debugPrint('AppStateManager: 尚未初始化，返回默认值');
      return defaultValue;
    }

    try {
      // 先检查待保存的更改
      if (_pendingChanges.containsKey(key)) {
        return _pendingChanges[key] as T?;
      }

      // 从持久化存储读取
      final appState = await _persistenceService
          .loadData<Map<String, dynamic>>(_appStateKey, defaultValue: {});
      return appState?[key] as T? ?? defaultValue;
    } catch (e) {
      debugPrint('AppStateManager: 读取状态失败 [$key] - $e');
      return defaultValue;
    }
  }

  /// 删除应用状态
  Future<void> removeAppState(String key) async {
    if (!_isInitialized) {
      debugPrint('AppStateManager: 尚未初始化，跳过删除操作');
      return;
    }

    try {
      _pendingChanges[key] = null; // 标记为删除
      debugPrint('AppStateManager: 状态已标记删除 [$key]');
    } catch (e) {
      debugPrint('AppStateManager: 删除状态失败 [$key] - $e');
    }
  }

  /// 批量保存状态
  Future<void> saveBatchAppState(Map<String, dynamic> states,
      {bool immediate = false}) async {
    if (!_isInitialized) {
      debugPrint('AppStateManager: 尚未初始化，跳过批量保存操作');
      return;
    }

    try {
      _pendingChanges.addAll(states);

      if (immediate) {
        await _flushPendingChanges();
      }

      debugPrint('AppStateManager: 批量状态已标记保存 [${states.keys.join(', ')}]');
    } catch (e) {
      debugPrint('AppStateManager: 批量保存状态失败 - $e');
    }
  }

  /// 强制刷新待保存的更改
  Future<void> flushPendingChanges() async {
    await _flushPendingChanges();
  }

  /// 获取应用会话信息
  Future<Map<String, dynamic>> getSessionInfo() async {
    final sessionId = await loadAppState<String>(_sessionIdKey);
    final lastActiveTime = await loadAppState<String>(_lastActiveTimeKey);
    final appVersion = await loadAppState<String>(_appVersionKey);

    return {
      'sessionId': sessionId,
      'lastActiveTime': lastActiveTime,
      'appVersion': appVersion,
      'currentTime': DateTime.now().toIso8601String(),
    };
  }

  /// 更新会话信息
  Future<void> updateSessionInfo() async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    await saveBatchAppState({
      _sessionIdKey: sessionId,
      _lastActiveTimeKey: DateTime.now().toIso8601String(),
      _appVersionKey: '1.0.0', // 可以从package info获取
    }, immediate: true);
  }

  /// 检查应用是否从后台恢复
  Future<bool> isRestoredFromBackground() async {
    final lastActiveTime = await loadAppState<String>(_lastActiveTimeKey);
    if (lastActiveTime == null) return false;

    final lastActive = DateTime.parse(lastActiveTime);
    final now = DateTime.now();

    // 如果超过5分钟没有活动，认为是从后台恢复
    return now.difference(lastActive).inMinutes > 5;
  }

  /// 清除所有应用状态
  Future<void> clearAllAppState() async {
    try {
      _pendingChanges.clear();
      await _persistenceService.removeData(_appStateKey);
      debugPrint('AppStateManager: 所有应用状态已清除');
    } catch (e) {
      debugPrint('AppStateManager: 清除应用状态失败 - $e');
    }
  }

  /// 获取状态统计信息
  Future<Map<String, dynamic>> getStateStats() async {
    try {
      final appState = await _persistenceService
          .loadData<Map<String, dynamic>>(_appStateKey, defaultValue: {});
      final storageStats = await _persistenceService.getStorageStats();

      return {
        'stateKeys': appState?.keys.length ?? 0,
        'pendingChanges': _pendingChanges.length,
        'isAutoSaveActive': _autoSaveTimer?.isActive ?? false,
        'storageStats': storageStats,
      };
    } catch (e) {
      debugPrint('AppStateManager: 获取状态统计失败 - $e');
      return {};
    }
  }

  /// 恢复应用状态
  Future<void> _restoreAppState() async {
    try {
      // 验证和修复数据
      await _persistenceService.validateAndRepairData();

      // 更新会话信息
      await updateSessionInfo();

      debugPrint('AppStateManager: 应用状态恢复成功');
    } catch (e) {
      debugPrint('AppStateManager: 恢复应用状态失败 - $e');
    }
  }

  /// 刷新待保存的更改
  Future<void> _flushPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    try {
      // 获取当前应用状态
      final currentAppState = await _persistenceService
          .loadData<Map<String, dynamic>>(_appStateKey, defaultValue: {});
      final updatedAppState = Map<String, dynamic>.from(currentAppState ?? {});

      // 应用待保存的更改
      for (final entry in _pendingChanges.entries) {
        if (entry.value == null) {
          updatedAppState.remove(entry.key);
        } else {
          updatedAppState[entry.key] = entry.value;
        }
      }

      // 保存到持久化存储
      await _persistenceService.saveData(_appStateKey, updatedAppState);

      debugPrint('AppStateManager: 已刷新 ${_pendingChanges.length} 个待保存更改');
      _pendingChanges.clear();
    } catch (e) {
      debugPrint('AppStateManager: 刷新待保存更改失败 - $e');
    }
  }

  /// 启动自动保存
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (timer) async {
      if (_pendingChanges.isNotEmpty) {
        await _flushPendingChanges();
      }
    });

    debugPrint('AppStateManager: 自动保存已启动');
  }

  /// 停止自动保存
  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    debugPrint('AppStateManager: 自动保存已停止');
  }

  /// 设置应用生命周期监听
  void _setupLifecycleListener() {
    SystemChannels.lifecycle.setMessageHandler((message) async {
      final state = AppLifecycleState.values.firstWhere(
        (s) => s.toString() == 'AppLifecycleState.$message',
        orElse: () => AppLifecycleState.resumed,
      );

      await _handleLifecycleChange(state);
      return null;
    });
  }

  /// 处理应用生命周期变化
  Future<void> _handleLifecycleChange(AppLifecycleState state) async {
    debugPrint('AppStateManager: 生命周期状态变化 - $state');

    switch (state) {
      case AppLifecycleState.paused:
        // 应用进入后台，立即保存状态
        await _flushPendingChanges();
        await saveAppState(_lastActiveTimeKey, DateTime.now().toIso8601String(),
            immediate: true);
        _stopAutoSave();
        break;

      case AppLifecycleState.resumed:
        // 应用恢复前台，重启自动保存
        _startAutoSave();
        await updateSessionInfo();
        break;

      case AppLifecycleState.detached:
        // 应用即将终止，保存所有状态
        await _flushPendingChanges();
        await _persistenceService.createBackup();
        break;

      default:
        break;
    }

    _lastLifecycleState = state;
  }

  /// 销毁状态管理器
  Future<void> dispose() async {
    try {
      await _flushPendingChanges();
      _stopAutoSave();
      _isInitialized = false;
      debugPrint('AppStateManager: 已销毁');
    } catch (e) {
      debugPrint('AppStateManager: 销毁失败 - $e');
    }
  }

  /// 创建状态快照
  Future<Map<String, dynamic>> createStateSnapshot() async {
    try {
      final appState = await _persistenceService
          .loadData<Map<String, dynamic>>(_appStateKey, defaultValue: {});
      final sessionInfo = await getSessionInfo();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'appState': appState,
        'sessionInfo': sessionInfo,
        'pendingChanges': Map<String, dynamic>.from(_pendingChanges),
      };
    } catch (e) {
      debugPrint('AppStateManager: 创建状态快照失败 - $e');
      return {};
    }
  }

  /// 从状态快照恢复
  Future<bool> restoreFromSnapshot(Map<String, dynamic> snapshot) async {
    try {
      if (!snapshot.containsKey('appState')) {
        return false;
      }

      final appState = snapshot['appState'] as Map<String, dynamic>;
      await _persistenceService.saveData(_appStateKey, appState);

      _pendingChanges.clear();

      debugPrint('AppStateManager: 从快照恢复成功');
      return true;
    } catch (e) {
      debugPrint('AppStateManager: 从快照恢复失败 - $e');
      return false;
    }
  }
}
