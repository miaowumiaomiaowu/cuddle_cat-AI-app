import 'dart:io';

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 图片缓存服务 - 优化图片加载和内存管理
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // 内存缓存
  final Map<String, ui.Image> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // 缓存配置
  static const int maxMemoryCacheSize = 50; // 最大内存缓存数量
  static const Duration cacheExpiration = Duration(hours: 24); // 缓存过期时间
  static const int maxDiskCacheSize = 100 * 1024 * 1024; // 100MB磁盘缓存限制

  String? _cacheDirectory;

  /// 初始化缓存服务
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = path.join(appDir.path, 'image_cache');

      final cacheDir = Directory(_cacheDirectory!);
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // 清理过期缓存
      await _cleanExpiredCache();

      debugPrint('ImageCacheService: 初始化完成');
    } catch (e) {
      debugPrint('ImageCacheService: 初始化失败 - $e');
    }
  }

  /// 获取缓存的图片
  Future<ui.Image?> getCachedImage(String key) async {
    try {
      // 检查内存缓存
      if (_memoryCache.containsKey(key)) {
        final timestamp = _cacheTimestamps[key];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < cacheExpiration) {
          return _memoryCache[key];
        } else {
          // 过期，移除
          _memoryCache.remove(key);
          _cacheTimestamps.remove(key);
        }
      }

      // 检查磁盘缓存
      final cachedFile = await _getCachedFile(key);
      if (cachedFile != null && await cachedFile.exists()) {
        final bytes = await cachedFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();

        // 存入内存缓存
        await _addToMemoryCache(key, frame.image);

        return frame.image;
      }

      return null;
    } catch (e) {
      debugPrint('ImageCacheService: 获取缓存图片失败 - $e');
      return null;
    }
  }

  /// 缓存图片
  Future<void> cacheImage(String key, ui.Image image) async {
    try {
      // 添加到内存缓存
      await _addToMemoryCache(key, image);

      // 保存到磁盘缓存
      await _saveToDiskCache(key, image);
    } catch (e) {
      debugPrint('ImageCacheService: 缓存图片失败 - $e');
    }
  }

  /// 从文件路径加载并缓存图片
  Future<ui.Image?> loadAndCacheImage(String filePath) async {
    try {
      final key = _generateCacheKey(filePath);

      // 先检查缓存
      final cachedImage = await getCachedImage(key);
      if (cachedImage != null) {
        return cachedImage;
      }

      // 加载原始图片
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      // 缓存图片
      await cacheImage(key, frame.image);

      return frame.image;
    } catch (e) {
      debugPrint('ImageCacheService: 加载图片失败 - $e');
      return null;
    }
  }

  /// 预加载图片列表
  Future<void> preloadImages(List<String> imagePaths) async {
    final futures = imagePaths.map((path) => loadAndCacheImage(path));
    await Future.wait(futures, eagerError: false);
  }

  /// 添加到内存缓存
  Future<void> _addToMemoryCache(String key, ui.Image image) async {
    // 检查缓存大小限制
    if (_memoryCache.length >= maxMemoryCacheSize) {
      await _evictOldestFromMemory();
    }

    _memoryCache[key] = image;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// 从内存缓存中移除最旧的项
  Future<void> _evictOldestFromMemory() async {
    if (_cacheTimestamps.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cacheTimestamps.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
  }

  /// 保存到磁盘缓存
  Future<void> _saveToDiskCache(String key, ui.Image image) async {
    if (_cacheDirectory == null) return;

    try {
      final file = File(path.join(_cacheDirectory!, '$key.png'));
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('ImageCacheService: 保存磁盘缓存失败 - $e');
    }
  }

  /// 获取缓存文件
  Future<File?> _getCachedFile(String key) async {
    if (_cacheDirectory == null) return null;
    return File(path.join(_cacheDirectory!, '$key.png'));
  }

  /// 生成缓存键
  String _generateCacheKey(String filePath) {
    return filePath.hashCode.toString();
  }

  /// 清理过期缓存
  Future<void> _cleanExpiredCache() async {
    if (_cacheDirectory == null) return;

    try {
      final cacheDir = Directory(_cacheDirectory!);
      final files = await cacheDir.list().toList();

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (DateTime.now().difference(stat.modified) > cacheExpiration) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('ImageCacheService: 清理过期缓存失败 - $e');
    }
  }

  /// 清理所有缓存
  Future<void> clearAllCache() async {
    try {
      // 清理内存缓存
      _memoryCache.clear();
      _cacheTimestamps.clear();

      // 清理磁盘缓存
      if (_cacheDirectory != null) {
        final cacheDir = Directory(_cacheDirectory!);
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
          await cacheDir.create(recursive: true);
        }
      }

      debugPrint('ImageCacheService: 所有缓存已清理');
    } catch (e) {
      debugPrint('ImageCacheService: 清理缓存失败 - $e');
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    int diskCacheSize = 0;
    int diskCacheCount = 0;

    if (_cacheDirectory != null) {
      try {
        final cacheDir = Directory(_cacheDirectory!);
        if (await cacheDir.exists()) {
          final files = await cacheDir.list().toList();
          diskCacheCount = files.length;

          for (final file in files) {
            if (file is File) {
              final stat = await file.stat();
              diskCacheSize += stat.size;
            }
          }
        }
      } catch (e) {
        debugPrint('ImageCacheService: 获取缓存统计失败 - $e');
      }
    }

    return {
      'memoryCacheCount': _memoryCache.length,
      'memoryCacheLimit': maxMemoryCacheSize,
      'diskCacheCount': diskCacheCount,
      'diskCacheSize': diskCacheSize,
      'diskCacheSizeFormatted': _formatFileSize(diskCacheSize),
      'diskCacheLimit': maxDiskCacheSize,
      'diskCacheLimitFormatted': _formatFileSize(maxDiskCacheSize),
    };
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
