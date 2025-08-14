import 'package:flutter/material.dart';
import '../services/memory_service.dart';
import '../theme/artistic_theme.dart';

class MemoryReviewCard extends StatelessWidget {
  final List<MemoryEvent> memories;
  final VoidCallback? onDismiss;

  const MemoryReviewCard({
    super.key,
    required this.memories,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber),
                const SizedBox(width: 8),
                Text('回顾你的亮点时刻', style: ArtisticTheme.titleMedium),
                const Spacer(),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '最近你有这些值得庆祝的突破：',
              style: ArtisticTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...memories.take(3).map((memory) => _buildMemoryItem(memory)),
            if (memories.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '还有 ${memories.length - 3} 个精彩时刻...',
                  style: ArtisticTheme.caption,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.favorite),
                  label: const Text('继续加油！'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryItem(MemoryEvent memory) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.summary,
                  style: ArtisticTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (memory.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      children: memory.tags.map((tag) => Chip(
                        label: Text(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ),
                Text(
                  _formatDate(memory.timestamp),
                  style: ArtisticTheme.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff < 7) return '$diff天前';
    if (diff < 30) return '${(diff / 7).floor()}周前';
    return '${date.month}月${date.day}日';
  }
}
