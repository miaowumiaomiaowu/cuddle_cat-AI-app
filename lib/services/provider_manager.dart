import 'package:flutter/widgets.dart';
import '../providers/base_provider.dart';
import 'app_state_manager.dart';
import 'data_persistence_service.dart';

/// Provider管理器 - 负责协调所有Provider的初始化和生命周期管理
class ProviderManager {
  static final ProviderManager _instance = ProviderManager._internal();
  factory ProviderManager() => _instance;
  ProviderManager._internal();

  final AppStateManager _stateManager = AppStateManager();
  final DataPersistenceService _persistenceService = DataPersistenceService.getInstance();

  final List<BaseProvider> _providers = [];
  bool _isInitialized = false;

  /// 初始化所有Provider
  Future<void> initializeProviders(List<BaseProvider> providers) async {
    if (_isInitialized) return;

    try {
      debugPrint('ProviderManager: 开始初始化所有Provider...');

      // 初始化核心服务
      await _stateManager.initialize();
      await _persistenceService.initialize();

      _providers.addAll(providers);

      // 顺序初始化所有Provider（避免内存压力）
      for (final provider in providers) {
        await _initializeProvider(provider);
        // 添加小延迟，让GC有机会清理
        await Future.delayed(const Duration(milliseconds: 50));
      }

      _isInitialized = true;
      debugPrint('ProviderManager: 所有Provider初始化完成');
    } catch (e) {
      debugPrint('ProviderManager: Provider初始化失败 - $e');
      rethrow;
    }
  }

  /// 初始化单个Provider
  Future<void> _initializeProvider(BaseProvider provider) async {
    try {
      await provider.initialize();
      debugPrint('ProviderManager: ${provider.runtimeType} 初始化成功');
    } catch (e) {
      debugPrint('ProviderManager: ${provider.runtimeType} 初始化失败 - $e');
      // 不抛出异常，允许其他Provider继续初始化
    }
  }

  /// 保存所有Provider数据
  Future<void> saveAllProviderData({bool immediate = false}) async {
    if (!_isInitialized) return;

    try {
      final saveFutures = _providers.map((provider) =>
          provider.saveData(immediate: immediate).catchError((e) {
            debugPrint('ProviderManager: 保存${provider.runtimeType}数据失败 - $e');
          }));

      await Future.wait(saveFutures);
      debugPrint('ProviderManager: 所有Provider数据保存完成');
    } catch (e) {
      debugPrint('ProviderManager: 保存Provider数据失败 - $e');
    }
  }

  /// 重新加载所有Provider数据
  Future<void> reloadAllProviderData() async {
    if (!_isInitialized) return;

    try {
      final reloadFutures =
          _providers.map((provider) => provider.reloadData().catchError((e) {
                debugPrint(
                    'ProviderManager: 重新加载${provider.runtimeType}数据失败 - $e');
              }));

      await Future.wait(reloadFutures);
      debugPrint('ProviderManager: 所有Provider数据重新加载完成');
    } catch (e) {
      debugPrint('ProviderManager: 重新加载Provider数据失败 - $e');
    }
  }

  /// 清除所有Provider数据
  Future<void> clearAllProviderData() async {
    if (!_isInitialized) return;

    try {
      final clearFutures =
          _providers.map((provider) => provider.clearData().catchError((e) {
                debugPrint(
                    'ProviderManager: 清除${provider.runtimeType}数据失败 - $e');
              }));

      await Future.wait(clearFutures);
      debugPrint('ProviderManager: 所有Provider数据清除完成');
    } catch (e) {
      debugPrint('ProviderManager: 清除Provider数据失败 - $e');
    }
  }

  /// 重置所有Provider
  Future<void> resetAllProviders() async {
    if (!_isInitialized) return;

    try {
      final resetFutures =
          _providers.map((provider) => provider.reset().catchError((e) {
                debugPrint('ProviderManager: 重置${provider.runtimeType}失败 - $e');
              }));

      await Future.wait(resetFutures);
      debugPrint('ProviderManager: 所有Provider重置完成');
    } catch (e) {
      debugPrint('ProviderManager: 重置Provider失败 - $e');
    }
  }

  /// 创建所有Provider的快照
  Future<Map<String, dynamic>> createProvidersSnapshot() async {
    if (!_isInitialized) return {};

    try {
      final snapshots = <String, dynamic>{};

      for (final provider in _providers) {
        try {
          final snapshot = await provider.createSnapshot();
          snapshots[provider.providerId] = snapshot;
        } catch (e) {
          debugPrint('ProviderManager: 创建${provider.runtimeType}快照失败 - $e');
        }
      }

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'providers': snapshots,
        'appState': await _stateManager.createStateSnapshot(),
      };
    } catch (e) {
      debugPrint('ProviderManager: 创建Provider快照失败 - $e');
      return {};
    }
  }

  /// 从快照恢复所有Provider
  Future<bool> restoreFromSnapshot(Map<String, dynamic> snapshot) async {
    if (!_isInitialized || !snapshot.containsKey('providers')) return false;

    try {
      final providersSnapshot = snapshot['providers'] as Map<String, dynamic>;
      bool allSuccess = true;

      for (final provider in _providers) {
        if (providersSnapshot.containsKey(provider.providerId)) {
          final providerSnapshot = providersSnapshot[provider.providerId];
          final success = await provider.restoreFromSnapshot(providerSnapshot);
          if (!success) {
            allSuccess = false;
            debugPrint('ProviderManager: 恢复${provider.runtimeType}快照失败');
          }
        }
      }

      // 恢复应用状态
      if (snapshot.containsKey('appState')) {
        await _stateManager.restoreFromSnapshot(snapshot['appState']);
      }

      debugPrint('ProviderManager: Provider快照恢复${allSuccess ? '成功' : '部分成功'}');
      return allSuccess;
    } catch (e) {
      debugPrint('ProviderManager: 恢复Provider快照失败 - $e');
      return false;
    }
  }

  /// 获取所有Provider的统计信息
  Map<String, dynamic> getProvidersStats() {
    if (!_isInitialized) return {};

    final stats = <String, dynamic>{};

    for (final provider in _providers) {
      try {
        stats[provider.providerId] = provider.getStats();
      } catch (e) {
        debugPrint('ProviderManager: 获取${provider.runtimeType}统计失败 - $e');
        stats[provider.providerId] = {'error': e.toString()};
      }
    }

    return {
      'totalProviders': _providers.length,
      'isInitialized': _isInitialized,
      'providers': stats,
    };
  }

  /// 获取特定类型的Provider
  T? getProvider<T extends BaseProvider>() {
    try {
      return _providers.whereType<T>().first;
    } catch (e) {
      debugPrint('ProviderManager: 未找到类型为${T.toString()}的Provider');
      return null;
    }
  }

  /// 检查Provider健康状态
  Future<Map<String, dynamic>> checkProvidersHealth() async {
    if (!_isInitialized) return {'healthy': false, 'reason': 'Not initialized'};

    final healthStatus = <String, dynamic>{};
    bool allHealthy = true;

    for (final provider in _providers) {
      try {
        final stats = provider.getStats();
        final isHealthy =
            stats['isInitialized'] == true && stats['hasError'] != true;

        healthStatus[provider.providerId] = {
          'healthy': isHealthy,
          'initialized': stats['isInitialized'],
          'hasError': stats['hasError'],
          'errorMessage': provider.errorMessage,
          'notificationCount': stats['notificationCount'],
        };

        if (!isHealthy) allHealthy = false;
      } catch (e) {
        healthStatus[provider.providerId] = {
          'healthy': false,
          'error': e.toString(),
        };
        allHealthy = false;
      }
    }

    return {
      'healthy': allHealthy,
      'providers': healthStatus,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 创建数据备份
  Future<bool> createBackup() async {
    try {
      // 先保存所有Provider数据
      await saveAllProviderData(immediate: true);

      // 创建系统备份
      return await _persistenceService.createBackup();
    } catch (e) {
      debugPrint('ProviderManager: 创建备份失败 - $e');
      return false;
    }
  }

  /// 从备份恢复
  Future<bool> restoreFromBackup([String? backupPath]) async {
    try {
      // 恢复系统数据
      final success = await _persistenceService.restoreFromBackup(backupPath);

      if (success) {
        // 重新加载所有Provider数据
        await reloadAllProviderData();
      }

      return success;
    } catch (e) {
      debugPrint('ProviderManager: 从备份恢复失败 - $e');
      return false;
    }
  }

  /// 销毁管理器
  Future<void> dispose() async {
    try {
      // 保存所有数据
      await saveAllProviderData(immediate: true);

      // 销毁所有Provider
      for (final provider in _providers) {
        provider.dispose();
      }

      _providers.clear();
      _isInitialized = false;

      debugPrint('ProviderManager: 已销毁');
    } catch (e) {
      debugPrint('ProviderManager: 销毁失败 - $e');
    }
  }

  /// 监听应用生命周期变化
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        // 应用进入后台，立即保存所有数据
        await saveAllProviderData(immediate: true);
        break;

      case AppLifecycleState.resumed:
        // 应用恢复前台，检查数据完整性
        final health = await checkProvidersHealth();
        if (!health['healthy']) {
          debugPrint('ProviderManager: 检测到Provider健康问题，尝试修复...');
          await reloadAllProviderData();
        }
        break;

      case AppLifecycleState.detached:
        // 应用即将终止，创建备份
        await createBackup();
        await dispose();
        break;

      default:
        break;
    }
  }
}
