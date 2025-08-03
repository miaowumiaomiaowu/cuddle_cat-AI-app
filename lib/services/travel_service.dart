import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/travel_record_model.dart';
import 'location_service.dart';

/// 旅行记录服务类 - 增强版
class TravelService {
  static TravelService? _instance;
  static TravelService get instance => _instance ??= TravelService._();

  TravelService._();

  static const String _recordsKey = 'travel_records_v2'; // 使用新版本key
  static const String _statsKey = 'travel_stats_v2';

  late SharedPreferences _prefs;
  late Directory _appDir;
  final ImagePicker _imagePicker = ImagePicker();
  bool _initialized = false;

  /// 初始化服务
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _appDir = await getApplicationDocumentsDirectory();

    // 创建媒体文件存储目录
    final mediaDir = Directory('${_appDir.path}/travel_media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    _initialized = true;
  }

  /// 获取所有旅行记录
  Future<List<TravelRecord>> getAllRecords() async {
    await initialize();
    try {
      final recordsJson = _prefs.getStringList(_recordsKey) ?? [];
      return recordsJson
          .map((json) => TravelRecord.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 按时间倒序
    } catch (e) {
      debugPrint('获取旅行记录失败: $e');
      return [];
    }
  }

  /// 根据ID获取记录
  Future<TravelRecord?> getRecordById(String id) async {
    final records = await getAllRecords();
    try {
      return records.firstWhere((record) => record.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 保存旅行记录
  Future<bool> saveRecord(TravelRecord record) async {
    await initialize();
    try {
      final records = await getAllRecords();

      // 检查是否是更新现有记录
      final existingIndex = records.indexWhere((r) => r.id == record.id);
      if (existingIndex != -1) {
        records[existingIndex] = record;
      } else {
        records.add(record);
      }

      // 保存到本地存储
      final recordsJson = records
          .map((record) => jsonEncode(record.toJson()))
          .toList();

      await _prefs.setStringList(_recordsKey, recordsJson);

      // 更新统计数据
      await _updateStats();

      return true;
    } catch (e) {
      debugPrint('保存旅行记录失败: $e');
      return false;
    }
  }

  /// 删除旅行记录
  Future<bool> deleteRecord(String id) async {
    await initialize();
    try {
      final records = await getAllRecords();
      final record = records.firstWhere((r) => r.id == id);

      // 删除关联的媒体文件
      for (final media in record.mediaItems) {
        await _deleteMediaFile(media.path);
        if (media.thumbnail != null) {
          await _deleteMediaFile(media.thumbnail!);
        }
      }

      // 从列表中移除
      records.removeWhere((r) => r.id == id);

      // 保存更新后的列表
      final recordsJson = records
          .map((record) => jsonEncode(record.toJson()))
          .toList();

      await _prefs.setStringList(_recordsKey, recordsJson);

      // 更新统计数据
      await _updateStats();

      return true;
    } catch (e) {
      debugPrint('删除旅行记录失败: $e');
      return false;
    }
  }

  /// 按条件筛选记录
  Future<List<TravelRecord>> filterRecords({
    String? city,
    String? province,
    String? mood,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    bool? isPrivate,
  }) async {
    final allRecords = await getAllRecords();

    return allRecords.where((record) {
      // 城市筛选
      if (city != null && record.location.city != city) {
        return false;
      }

      // 省份筛选
      if (province != null && record.location.province != province) {
        return false;
      }

      // 心情筛选
      if (mood != null && record.mood != mood) {
        return false;
      }

      // 标签筛选
      if (tags != null && tags.isNotEmpty) {
        final hasMatchingTag = tags.any((tag) => record.tags.contains(tag));
        if (!hasMatchingTag) return false;
      }

      // 日期范围筛选
      if (startDate != null && record.createdAt.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && record.createdAt.isAfter(endDate)) {
        return false;
      }

      // 隐私筛选
      if (isPrivate != null && record.isPrivate != isPrivate) {
        return false;
      }

      return true;
    }).toList();
  }

  /// 搜索记录
  Future<List<TravelRecord>> searchRecords(String keyword) async {
    if (keyword.isEmpty) return getAllRecords();

    final allRecords = await getAllRecords();
    final lowerKeyword = keyword.toLowerCase();

    return allRecords.where((record) {
      return record.title.toLowerCase().contains(lowerKeyword) ||
             record.description.toLowerCase().contains(lowerKeyword) ||
             record.location.address.toLowerCase().contains(lowerKeyword) ||
             record.location.city?.toLowerCase().contains(lowerKeyword) == true ||
             record.tags.any((tag) => tag.toLowerCase().contains(lowerKeyword));
    }).toList();
  }

  /// 获取旅行统计数据
  Future<TravelStats> getStats() async {
    await initialize();
    final statsJson = _prefs.getString(_statsKey);
    if (statsJson != null) {
      try {
        return TravelStats.fromJson(jsonDecode(statsJson));
      } catch (e) {
        debugPrint('解析统计数据失败: $e');
      }
    }

    // 如果没有缓存的统计数据，重新计算
    return await _calculateStats();
  }

  /// 添加媒体文件从相机
  Future<MediaItem?> addMediaFromCamera({
    required MediaType type,
    String? caption,
  }) async {
    await initialize();
    try {
      XFile? file;

      switch (type) {
        case MediaType.image:
          file = await _imagePicker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          break;
        case MediaType.video:
          file = await _imagePicker.pickVideo(
            source: ImageSource.camera,
            maxDuration: const Duration(minutes: 5),
          );
          break;
        default:
          return null;
      }

      if (file == null) return null;

      return await _processMediaFile(file, type, caption);
    } catch (e) {
      debugPrint('从相机添加媒体失败: $e');
      return null;
    }
  }

  /// 添加媒体文件从相册
  Future<MediaItem?> addMediaFromGallery({
    required MediaType type,
    String? caption,
  }) async {
    await initialize();
    try {
      XFile? file;

      switch (type) {
        case MediaType.image:
          file = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          break;
        case MediaType.video:
          file = await _imagePicker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 10),
          );
          break;
        default:
          return null;
      }

      if (file == null) return null;

      return await _processMediaFile(file, type, caption);
    } catch (e) {
      debugPrint('从相册添加媒体失败: $e');
      return null;
    }
  }

  /// 处理媒体文件
  Future<MediaItem> _processMediaFile(
    XFile file,
    MediaType type,
    String? caption
  ) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final targetPath = '${_appDir.path}/travel_media/$fileName';

    String? thumbnailPath;
    double? fileSize;
    int? duration;

    // 复制文件到应用目录
    await File(file.path).copy(targetPath);

    // 获取文件大小
    final fileStats = await File(targetPath).stat();
    fileSize = fileStats.size / (1024 * 1024); // 转换为MB

    // 根据类型处理
    switch (type) {
      case MediaType.image:
        // 压缩图片并生成缩略图
        thumbnailPath = await _generateImageThumbnail(targetPath);
        break;
      case MediaType.video:
        // 生成视频缩略图
        thumbnailPath = await _generateVideoThumbnail(targetPath);
        // TODO: 获取视频时长
        break;
      default:
        break;
    }

    return MediaItem(
      type: type,
      path: targetPath,
      thumbnail: thumbnailPath,
      caption: caption,
      duration: duration,
      fileSize: fileSize,
    );
  }

  /// 生成图片缩略图
  Future<String?> _generateImageThumbnail(String imagePath) async {
    try {
      final thumbnailPath = imagePath.replaceAll('.', '_thumb.');

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        thumbnailPath,
        quality: 70,
        minWidth: 200,
        minHeight: 200,
      );

      return compressedFile?.path;
    } catch (e) {
      debugPrint('生成图片缩略图失败: $e');
      return null;
    }
  }

  /// 生成视频缩略图
  Future<String?> _generateVideoThumbnail(String videoPath) async {
    // TODO: 实现视频缩略图生成
    // 可以使用 video_thumbnail 包
    return null;
  }

  /// 删除媒体文件
  Future<void> _deleteMediaFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('删除媒体文件失败: $e');
    }
  }

  /// 更新统计数据
  Future<void> _updateStats() async {
    final stats = await _calculateStats();
    await _prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  /// 计算统计数据
  Future<TravelStats> _calculateStats() async {
    final records = await getAllRecords();

    if (records.isEmpty) {
      return TravelStats(
        totalRecords: 0,
        totalCities: 0,
        totalProvinces: 0,
        totalDistance: 0,
        totalDays: 0,
        moodDistribution: {},
        monthlyDistribution: {},
        topCities: [],
        topTags: [],
      );
    }

    // 计算各项统计数据
    final cities = <String>{};
    final provinces = <String>{};
    final moodCount = <String, int>{};
    final monthlyCount = <String, int>{};
    final cityCount = <String, int>{};
    final tagCount = <String, int>{};

    double totalDistance = 0;
    DateTime? firstDate;
    DateTime? lastDate;

    for (int i = 0; i < records.length; i++) {
      final record = records[i];

      // 城市和省份统计
      if (record.location.city != null) {
        cities.add(record.location.city!);
        cityCount[record.location.city!] =
            (cityCount[record.location.city!] ?? 0) + 1;
      }
      if (record.location.province != null) {
        provinces.add(record.location.province!);
      }

      // 心情分布
      moodCount[record.mood] = (moodCount[record.mood] ?? 0) + 1;

      // 月度分布
      final monthKey = '${record.createdAt.year}-${record.createdAt.month.toString().padLeft(2, '0')}';
      monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;

      // 标签统计
      for (final tag in record.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }

      // 距离计算
      if (i > 0) {
        final prevRecord = records[i - 1];
        final distance = LocationService.instance.calculateDistance(
          prevRecord.location.latitude,
          prevRecord.location.longitude,
          record.location.latitude,
          record.location.longitude,
        );
        totalDistance += distance;
      }

      // 日期范围
      if (firstDate == null || record.createdAt.isBefore(firstDate)) {
        firstDate = record.createdAt;
      }
      if (lastDate == null || record.createdAt.isAfter(lastDate)) {
        lastDate = record.createdAt;
      }
    }

    // 计算总天数
    final totalDays = firstDate != null && lastDate != null
        ? lastDate.difference(firstDate).inDays + 1
        : 0;

    // 获取Top城市和标签
    final topCities = cityCount.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = tagCount.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return TravelStats(
      totalRecords: records.length,
      totalCities: cities.length,
      totalProvinces: provinces.length,
      totalDistance: totalDistance,
      totalDays: totalDays,
      moodDistribution: moodCount,
      monthlyDistribution: monthlyCount,
      topCities: topCities.take(10).map((e) => e.key).toList(),
      topTags: topTags.take(10).map((e) => e.key).toList(),
    );
  }

  /// 清空所有数据
  Future<void> clearAllData() async {
    await initialize();
    await _prefs.remove(_recordsKey);
    await _prefs.remove(_statsKey);

    // 删除所有媒体文件
    final mediaDir = Directory('${_appDir.path}/travel_media');
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
      await mediaDir.create();
    }
  }
}
