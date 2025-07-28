import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_performance_service.dart';
import 'image_cache_service.dart';

/// 应用启动优化服务
class StartupOptimizationService {
  static final StartupOptimizationService _instance =
      StartupOptimizationService._internal();
  factory StartupOptimizationService() => _instance;
  StartupOptimizationService._internal();

  final AppPerformanceService _performanceService = AppPerformanceService();
  final ImageCacheService _imageCacheService = ImageCacheService();

  bool _isInitialized = false;
  final List<Future<void>> _initializationTasks = [];
  final Map<String, bool> _serviceStatus = {};

  /// 初始化启动优化
  Future<void> initialize() async {
    if (_isInitialized) return;

    _performanceService.startOperation('startup_optimization');

    try {
      // 并行初始化核心服务
      await _initializeCoreServices();

      // 预热关键组件
      await _warmupComponents();

      // 后台初始化非关键服务
      _initializeBackgroundServices();

      _isInitialized = true;
      debugPrint('StartupOptimizationService: 初始化完成');
    } catch (e) {
      debugPrint('StartupOptimizationService: 初始化失败 - $e');
      rethrow;
    } finally {
      _performanceService.endOperation('startup_optimization');
    }
  }

  /// 初始化核心服务
  Future<void> _initializeCoreServices() async {
    _performanceService.startOperation('core_services_init');

    try {
      final futures = <Future<void>>[];

      // 性能监控服务
      futures.add(_initializeService('performance', () async {
        _performanceService.initialize();
      }));

      // 图片缓存服务
      futures.add(_initializeService('image_cache', () async {
        await _imageCacheService.initialize();
      }));

      // 系统UI优化
      futures.add(_initializeService('system_ui', () async {
        await _optimizeSystemUI();
      }));

      // 等待所有核心服务初始化完成
      await Future.wait(futures);
    } finally {
      _performanceService.endOperation('core_services_init');
    }
  }

  /// 预热关键组件
  Future<void> _warmupComponents() async {
    _performanceService.startOperation('component_warmup');

    try {
      final futures = <Future<void>>[];

      // 预热Flutter引擎
      futures.add(_warmupFlutterEngine());

      // 预加载关键资源
      futures.add(_preloadCriticalAssets());

      // 预热网络连接
      futures.add(_warmupNetworkConnection());

      await Future.wait(futures, eagerError: false);
    } finally {
      _performanceService.endOperation('component_warmup');
    }
  }

  /// 后台初始化非关键服务
  void _initializeBackgroundServices() {
    // 使用微任务在下一个事件循环中执行
    scheduleMicrotask(() async {
      _performanceService.startOperation('background_services_init');

      try {
        // 预加载非关键图片
        await _preloadNonCriticalAssets();

        // 清理过期缓存
        await _cleanupExpiredData();

        // 优化内存使用
        await _optimizeMemoryUsage();
      } catch (e) {
        debugPrint('StartupOptimizationService: 后台服务初始化失败 - $e');
      } finally {
        _performanceService.endOperation('background_services_init');
      }
    });
  }

  /// 初始化单个服务
  Future<void> _initializeService(
      String serviceName, Future<void> Function() initializer) async {
    try {
      await initializer();
      _serviceStatus[serviceName] = true;
      debugPrint('StartupOptimizationService: $serviceName 初始化成功');
    } catch (e) {
      _serviceStatus[serviceName] = false;
      debugPrint('StartupOptimizationService: $serviceName 初始化失败 - $e');
      rethrow;
    }
  }

  /// 优化系统UI
  Future<void> _optimizeSystemUI() async {
    try {
      // 设置系统UI样式
      await SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      // 设置首选方向
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // 启用硬件加速
      if (!kIsWeb) {
        // 移动端特定优化
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
        );
      }
    } catch (e) {
      debugPrint('StartupOptimizationService: 系统UI优化失败 - $e');
    }
  }

  /// 预热Flutter引擎
  Future<void> _warmupFlutterEngine() async {
    try {
      // 预热绘制系统
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 触发第一次绘制
        WidgetsBinding.instance.ensureVisualUpdate();
      });

      // 预热图片解码器
      await _warmupImageDecoder();
    } catch (e) {
      debugPrint('StartupOptimizationService: Flutter引擎预热失败 - $e');
    }
  }

  /// 预热图片解码器
  Future<void> _warmupImageDecoder() async {
    try {
      // 创建一个小的测试图片来预热解码器
      const testImageData = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 pixel
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0x00, 0x00, 0x00,
        0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x37,
        0x6E, 0xF9, 0x24, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ];

      final codec =
          await instantiateImageCodec(Uint8List.fromList(testImageData));
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } catch (e) {
      debugPrint('StartupOptimizationService: 图片解码器预热失败 - $e');
    }
  }

  /// 预加载关键资源
  Future<void> _preloadCriticalAssets() async {
    try {
      // 预加载关键图标和图片
      final criticalAssets = [
        'assets/icons/app_icon.png',
        'assets/images/cat_default.png',
        // 添加更多关键资源
      ];

      final futures = criticalAssets.map((asset) async {
        try {
          await rootBundle.load(asset);
        } catch (e) {
          // 忽略不存在的资源
          debugPrint('StartupOptimizationService: 资源不存在 - $asset');
        }
      });

      await Future.wait(futures, eagerError: false);
    } catch (e) {
      debugPrint('StartupOptimizationService: 预加载关键资源失败 - $e');
    }
  }

  /// 预加载非关键资源
  Future<void> _preloadNonCriticalAssets() async {
    try {
      // 预加载装饰性图片和动画
      final nonCriticalAssets = [
        'assets/images/background.png',
        'assets/svgs/decorations/',
        // 添加更多非关键资源
      ];

      for (final asset in nonCriticalAssets) {
        try {
          await rootBundle.load(asset);
          // 添加小延迟避免阻塞主线程
          await Future.delayed(const Duration(milliseconds: 10));
        } catch (e) {
          // 忽略错误，继续处理下一个资源
        }
      }
    } catch (e) {
      debugPrint('StartupOptimizationService: 预加载非关键资源失败 - $e');
    }
  }

  /// 预热网络连接
  Future<void> _warmupNetworkConnection() async {
    try {
      // 这里可以添加网络连接预热逻辑
      // 例如：预连接到API服务器
    } catch (e) {
      debugPrint('StartupOptimizationService: 网络连接预热失败 - $e');
    }
  }

  /// 清理过期数据
  Future<void> _cleanupExpiredData() async {
    try {
      // 清理图片缓存中的过期项
      // 这个操作在ImageCacheService中实现

      // 清理其他过期数据
      await _performanceService.optimizePerformance();
    } catch (e) {
      debugPrint('StartupOptimizationService: 清理过期数据失败 - $e');
    }
  }

  /// 优化内存使用
  Future<void> _optimizeMemoryUsage() async {
    try {
      // 设置图片缓存大小限制
      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes =
          50 * 1024 * 1024; // 50MB

      // 清理不必要的资源
      if (kDebugMode) {
        // 在调试模式下可以进行更激进的清理
      }
    } catch (e) {
      debugPrint('StartupOptimizationService: 内存优化失败 - $e');
    }
  }

  /// 获取启动状态
  StartupStatus getStartupStatus() {
    return StartupStatus(
      isInitialized: _isInitialized,
      serviceStatus: Map.from(_serviceStatus),
      completedTasks: _initializationTasks.length,
    );
  }

  /// 等待所有初始化任务完成
  Future<void> waitForInitialization() async {
    if (_initializationTasks.isNotEmpty) {
      await Future.wait(_initializationTasks, eagerError: false);
    }
  }

  /// 重置启动优化服务
  void reset() {
    _isInitialized = false;
    _initializationTasks.clear();
    _serviceStatus.clear();
    debugPrint('StartupOptimizationService: 已重置');
  }
}

/// 启动状态
class StartupStatus {
  final bool isInitialized;
  final Map<String, bool> serviceStatus;
  final int completedTasks;

  StartupStatus({
    required this.isInitialized,
    required this.serviceStatus,
    required this.completedTasks,
  });

  bool get allServicesReady => serviceStatus.values.every((status) => status);

  List<String> get failedServices => serviceStatus.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toList();
}
