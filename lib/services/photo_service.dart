import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 照片处理服务类
class PhotoService {
  static final PhotoService _instance = PhotoService._internal();

  factory PhotoService() => _instance;

  PhotoService._internal();

  /// 压缩并保存照片
  ///
  /// [imagePath] 原始图片路径
  /// [quality] 压缩质量 (0-100)
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  ///
  /// 返回压缩后的图片路径
  Future<String?> compressAndSavePhoto(
    String imagePath, {
    int quality = 80,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      final File originalFile = File(imagePath);
      if (!await originalFile.exists()) {
        debugPrint('原始文件不存在: $imagePath');
        return null;
      }

      // 获取应用文档目录
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String travelPhotosDir = path.join(appDocDir.path, 'travel_photos');

      // 创建目录（如果不存在）
      final Directory photosDirectory = Directory(travelPhotosDir);
      if (!await photosDirectory.exists()) {
        await photosDirectory.create(recursive: true);
      }

      // 生成新的文件名
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
      final String outputPath = path.join(travelPhotosDir, fileName);

      // 压缩图片
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imagePath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        debugPrint('图片压缩失败');
        return null;
      }

      // 保存压缩后的图片
      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(compressedBytes);

      // 获取文件大小信息用于日志
      final int originalSize = await originalFile.length();
      final int compressedSize = compressedBytes.length;
      final double compressionRatio = (1 - compressedSize / originalSize) * 100;

      debugPrint('图片压缩完成:');
      debugPrint('  原始大小: ${_formatFileSize(originalSize)}');
      debugPrint('  压缩后大小: ${_formatFileSize(compressedSize)}');
      debugPrint('  压缩率: ${compressionRatio.toStringAsFixed(1)}%');

      return outputPath;
    } catch (e) {
      debugPrint('压缩照片失败: $e');
      return null;
    }
  }

  /// 批量压缩照片
  Future<List<String>> compressMultiplePhotos(
    List<String> imagePaths, {
    int quality = 80,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    final List<String> compressedPaths = [];

    for (final String imagePath in imagePaths) {
      final String? compressedPath = await compressAndSavePhoto(
        imagePath,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (compressedPath != null) {
        compressedPaths.add(compressedPath);
      }
    }

    return compressedPaths;
  }

  /// 删除照片文件
  Future<bool> deletePhoto(String photoPath) async {
    try {
      final File file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('删除照片成功: $photoPath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('删除照片失败: $e');
      return false;
    }
  }

  /// 清理旅行照片目录中的孤立文件
  ///
  /// [usedPhotoPaths] 当前使用中的照片路径列表
  Future<void> cleanupOrphanedPhotos(List<String> usedPhotoPaths) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String travelPhotosDir = path.join(appDocDir.path, 'travel_photos');
      final Directory photosDirectory = Directory(travelPhotosDir);

      if (!await photosDirectory.exists()) {
        return;
      }

      final List<FileSystemEntity> files =
          await photosDirectory.list().toList();
      int deletedCount = 0;

      for (final FileSystemEntity entity in files) {
        if (entity is File) {
          final String filePath = entity.path;

          // 如果文件不在使用中的照片列表中，则删除
          if (!usedPhotoPaths.contains(filePath)) {
            await entity.delete();
            deletedCount++;
            debugPrint('删除孤立照片: $filePath');
          }
        }
      }

      debugPrint('清理完成，删除了 $deletedCount 个孤立照片文件');
    } catch (e) {
      debugPrint('清理孤立照片失败: $e');
    }
  }

  /// 获取照片存储目录大小
  Future<int> getPhotoStorageSize() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String travelPhotosDir = path.join(appDocDir.path, 'travel_photos');
      final Directory photosDirectory = Directory(travelPhotosDir);

      if (!await photosDirectory.exists()) {
        return 0;
      }

      int totalSize = 0;
      final List<FileSystemEntity> files =
          await photosDirectory.list().toList();

      for (final FileSystemEntity entity in files) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('获取照片存储大小失败: $e');
      return 0;
    }
  }

  /// 格式化文件大小显示
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 获取格式化的存储大小字符串
  Future<String> getFormattedStorageSize() async {
    final int size = await getPhotoStorageSize();
    return _formatFileSize(size);
  }
}
