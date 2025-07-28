import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/travel.dart';
import '../providers/travel_provider.dart';
import '../services/share_service.dart';
import '../utils/animation_utils.dart';
import 'package:provider/provider.dart';

/// 旅行记录卡片组件
class TravelRecordCard extends StatelessWidget {
  final Travel record;

  const TravelRecordCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy年MM月dd日');

    return HandDrawnAnimatedWidget(
      animationType: AnimationType.fadeIn,
      delay: Duration(milliseconds: 100 + (record.hashCode % 500)),
      child: Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFAF5),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(3, 5),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 6,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 照片预览
          if (record.photos.isNotEmpty)
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: PageView.builder(
                  itemCount: record.photos.length,
                  itemBuilder: (context, index) {
                    return Image.file(
                      File(record.photos[index]),
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),

          // 内容区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题和收藏按钮
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Consumer<TravelProvider>(
                      builder: (context, provider, child) {
                        return IconButton(
                          icon: Icon(
                            record.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: record.isFavorite ? Colors.red : null,
                          ),
                          onPressed: () {
                            provider.toggleFavorite(record.id);
                          },
                        );
                      },
                    ),
                  ],
                ),

                // 位置和日期
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        record.locationName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormatter.format(record.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                // 心情
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Chip(
                    label: Text(_translateMood(record.mood)),
                    backgroundColor: _getMoodColor(record.mood),
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: const EdgeInsets.all(0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                // 描述
                if (record.description.isNotEmpty) ...[
                  Text(
                    record.description,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // 标签
                if (record.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: record.tags
                        .map((tag) => Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.blue.shade50,
                              padding: const EdgeInsets.all(0),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),

          // 操作按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('分享'),
                  onPressed: () => _showShareDialog(context),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('编辑'),
                  onPressed: () {
                    // TODO: 实现编辑功能
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('删除'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () {
                    _confirmDelete(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${record.title}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (result == true) {
      // ignore: use_build_context_synchronously
      final provider = Provider.of<TravelProvider>(context, listen: false);
      provider.deleteRecord(record.id);
    }
  }

  /// 显示分享对话框
  Future<void> _showShareDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分享旅行记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('分享文字'),
              subtitle: const Text('复制文字内容到剪贴板'),
              onTap: () async {
                Navigator.of(context).pop();
                await _shareText(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('生成分享卡片'),
              subtitle: const Text('生成精美的分享图片'),
              onTap: () async {
                Navigator.of(context).pop();
                await _shareImage(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('完整分享'),
              subtitle: const Text('分享文字和图片'),
              onTap: () async {
                Navigator.of(context).pop();
                await _shareComplete(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 分享文字
  Future<void> _shareText(BuildContext context) async {
    try {
      final shareService = ShareService();
      final shareText = shareService.generateShareText(record);
      final success = await shareService.copyToClipboard(shareText);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '文字已复制到剪贴板' : '复制失败'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 分享图片
  Future<void> _shareImage(BuildContext context) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在生成分享卡片...'),
          ],
        ),
      ),
    );

    try {
      final shareService = ShareService();
      final imagePath = await shareService.generateShareCard(record);

      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (imagePath != null) {
        // 显示预览对话框
        if (context.mounted) {
          _showImagePreview(context, imagePath);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('生成分享卡片失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成分享卡片失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示图片预览
  void _showImagePreview(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分享卡片预览'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              File(imagePath),
              width: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: const Text('保存'),
                  onPressed: () async {
                    final shareService = ShareService();
                    final success =
                        await shareService.saveImageToGallery(imagePath);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '图片已保存到相册' : '保存失败'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('分享'),
                  onPressed: () async {
                    final shareService = ShareService();
                    final shareContent = ShareContent(
                      text: shareService.generateShareText(record),
                      imagePath: imagePath,
                      type: ShareContentType.combined,
                    );
                    final success =
                        await shareService.shareToSystem(shareContent);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '分享成功' : '分享失败'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 完整分享
  Future<void> _shareComplete(BuildContext context) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在准备分享内容...'),
          ],
        ),
      ),
    );

    try {
      final shareService = ShareService();
      final shareContent = await shareService.generateShareContent(record);

      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      final success = await shareService.shareToSystem(shareContent);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '分享成功' : '分享失败'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
