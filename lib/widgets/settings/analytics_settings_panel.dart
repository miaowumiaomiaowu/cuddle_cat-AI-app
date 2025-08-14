import 'package:flutter/material.dart';
import '../../services/feedback_service.dart';
import '../../theme/artistic_theme.dart';

class AnalyticsSettingsPanel extends StatefulWidget {
  const AnalyticsSettingsPanel({super.key});

  @override
  State<AnalyticsSettingsPanel> createState() => _AnalyticsSettingsPanelState();
}

class _AnalyticsSettingsPanelState extends State<AnalyticsSettingsPanel> {
  final FeedbackService _feedbackService = FeedbackService();
  Map<String, int> _feedbackStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _feedbackService.getFeedbackStats();
    setState(() {
      _feedbackStats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('用户反馈统计', style: ArtisticTheme.titleMedium),
        const SizedBox(height: 16),
        if (_feedbackStats.isEmpty)
          const Text('暂无反馈数据')
        else
          ..._buildStatsCards(),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _uploadPendingFeedback,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('上传待同步反馈'),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildStatsCards() {
    final cards = <Widget>[];
    
    _feedbackStats.forEach((type, count) {
      final icon = _getIconForType(type);
      final label = _getLabelForType(type);
      
      cards.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 8),
                Text(label),
                const Spacer(),
                Text(
                  count.toString(),
                  style: ArtisticTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    });
    
    return cards;
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.thumb_up;
      case 'dislike':
        return Icons.thumb_down;
      case 'completed':
        return Icons.check_circle;
      case 'skipped':
        return Icons.skip_next;
      default:
        return Icons.help;
    }
  }

  String _getLabelForType(String type) {
    switch (type) {
      case 'like':
        return '喜欢';
      case 'dislike':
        return '不喜欢';
      case 'completed':
        return '已完成';
      case 'skipped':
        return '跳过';
      default:
        return type;
    }
  }

  Future<void> _uploadPendingFeedback() async {
    try {
      await _feedbackService.uploadPendingFeedback();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('反馈数据上传完成')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败: $e')),
      );
    }
  }
}
