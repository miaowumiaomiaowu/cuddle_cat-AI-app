import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/travel_record_model.dart';
import 'package:intl/intl.dart';

/// 分享内容类型
enum ShareContentType {
  text,
  image,
  combined,
}

/// 分享内容类
class ShareContent {
  final String text;
  final String? imagePath;
  final ShareContentType type;

  ShareContent({
    required this.text,
    this.imagePath,
    required this.type,
  });
}

/// 分享服务类
class ShareService {
  static final ShareService _instance = ShareService._internal();

  factory ShareService() => _instance;

  ShareService._internal();

  /// 生成旅行记录的分享文本
  String generateShareText(TravelRecord record) {
    final dateFormatter = DateFormat('yyyy年MM月dd日');
    final buffer = StringBuffer();

    buffer.writeln('🌟 ${record.title}');
    buffer.writeln('📍 ${record.location.address}');
    buffer.writeln('📅 ${dateFormatter.format(record.createdAt)}');
    buffer.writeln('😊 ${_translateMood(record.mood)}');

    if (record.description.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('💭 ${record.description}');
    }

    if (record.tags.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('🏷️ ${record.tags.join(' #')}');
    }

    buffer.writeln();
    buffer.writeln('📱 来自暖猫旅行记录');

    return buffer.toString();
  }

  /// 生成分享卡片图片
  Future<String?> generateShareCard(TravelRecord record) async {
    try {
      // 创建分享卡片的Widget
      final Widget shareCard = _buildShareCardWidget(record);

      // 将Widget转换为图片
      final String? imagePath = await _widgetToImage(shareCard);

      return imagePath;
    } catch (e) {
      debugPrint('生成分享卡片失败: $e');
      return null;
    }
  }

  /// 构建分享卡片Widget
  Widget _buildShareCardWidget(TravelRecord record) {
    final dateFormatter = DateFormat('yyyy年MM月dd日');

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Text(
            record.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // 位置和日期
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.location.address,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                dateFormatter.format(record.createdAt),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 心情
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getMoodColor(record.mood),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _translateMood(record.mood),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 描述
          if (record.description.isNotEmpty) ...[
            Text(
              record.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],

          // 标签
          if (record.tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: record.tags
                  .take(4)
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // 底部品牌信息
          const Divider(),
          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '暖猫旅行记录',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 将Widget转换为图片
  Future<String?> _widgetToImage(Widget widget) async {
    try {
      // 创建RepaintBoundary
      final GlobalKey repaintBoundaryKey = GlobalKey();

      // 包装Widget
      final Widget wrappedWidget = RepaintBoundary(
        key: repaintBoundaryKey,
        child: Material(
          color: Colors.transparent,
          child: widget,
        ),
      );

      // 创建临时的OverlayEntry来渲染Widget
      final OverlayEntry overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -1000, // 移出屏幕
          top: -1000,
          child: wrappedWidget,
        ),
      );

      // 获取当前的Overlay
      final NavigatorState? navigator =
          Navigator.maybeOf(WidgetsBinding.instance.rootElement!);

      if (navigator == null) {
        debugPrint('无法获取Navigator');
        return null;
      }

      final OverlayState? overlay = navigator.overlay;
      if (overlay == null) {
        debugPrint('无法获取Overlay');
        return null;
      }

      // 插入OverlayEntry
      overlay.insert(overlayEntry);

      // 等待一帧以确保Widget被渲染
      await WidgetsBinding.instance.endOfFrame;

      // 获取RenderRepaintBoundary
      final RenderRepaintBoundary? boundary = repaintBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        overlayEntry.remove();
        debugPrint('无法获取RenderRepaintBoundary');
        return null;
      }

      // 转换为图片
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      // 移除OverlayEntry
      overlayEntry.remove();

      if (byteData == null) {
        debugPrint('无法获取图片数据');
        return null;
      }

      // 保存图片到临时目录
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'share_card_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = path.join(tempDir.path, fileName);

      final File file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return filePath;
    } catch (e) {
      debugPrint('Widget转图片失败: $e');
      return null;
    }
  }

  /// 生成完整的分享内容
  Future<ShareContent> generateShareContent(TravelRecord record) async {
    final String shareText = generateShareText(record);
    final String? shareImagePath = await generateShareCard(record);

    return ShareContent(
      text: shareText,
      imagePath: shareImagePath,
      type: shareImagePath != null
          ? ShareContentType.combined
          : ShareContentType.text,
    );
  }

  /// 模拟分享到系统
  Future<bool> shareToSystem(ShareContent content) async {
    try {
      // 这里应该调用系统分享API，比如 share_plus 包
      // 由于当前项目没有该依赖，我们模拟分享过程

      debugPrint('=== 模拟系统分享 ===');
      debugPrint('分享类型: ${content.type}');
      debugPrint('分享文本:');
      debugPrint(content.text);

      if (content.imagePath != null) {
        debugPrint('分享图片: ${content.imagePath}');
      }

      // 模拟分享延迟
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('分享完成');
      return true;
    } catch (e) {
      debugPrint('分享失败: $e');
      return false;
    }
  }

  /// 复制分享文本到剪贴板
  Future<bool> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      debugPrint('复制到剪贴板失败: $e');
      return false;
    }
  }

  /// 保存分享图片到相册
  Future<bool> saveImageToGallery(String imagePath) async {
    try {
      // 这里应该调用保存到相册的API，比如 image_gallery_saver 包
      // 由于当前项目没有该依赖，我们模拟保存过程

      debugPrint('模拟保存图片到相册: $imagePath');

      // 模拟保存延迟
      await Future.delayed(const Duration(milliseconds: 300));

      return true;
    } catch (e) {
      debugPrint('保存图片到相册失败: $e');
      return false;
    }
  }

  /// 翻译心情
  String _translateMood(String mood) {
    switch (mood) {
      case 'happy':
        return '😄 开心';
      case 'relaxed':
        return '😌 放松';
      case 'excited':
        return '🤩 兴奋';
      case 'romantic':
        return '💑 浪漫';
      case 'tired':
        return '😪 疲惫';
      case 'bored':
        return '😒 无聊';
      default:
        return '😐 平静';
    }
  }

  /// 获取心情颜色
  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy':
        return Colors.yellow.shade100;
      case 'relaxed':
        return Colors.green.shade100;
      case 'excited':
        return Colors.orange.shade100;
      case 'romantic':
        return Colors.pink.shade100;
      case 'tired':
        return Colors.indigo.shade100;
      case 'bored':
        return Colors.grey.shade200;
      default:
        return Colors.blue.shade50;
    }
  }
}
