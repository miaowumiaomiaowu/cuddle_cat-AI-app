import 'package:flutter/material.dart';
import '../models/travel_record_model.dart';

/// 旅行统计卡片组件
class TravelStatsCard extends StatelessWidget {
  final TravelStats stats;

  const TravelStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '旅行统计',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 基础统计
            Row(
              children: [
                _buildStatItem(
                  context,
                  '📍',
                  '${stats.totalRecords}',
                  '记录总数',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatItem(
                  context,
                  '🏙️',
                  '${stats.totalPlaces}',
                  '去过的地方',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildStatItem(
                  context,
                  '😊',
                  _translateMood(stats.mostCommonMood),
                  '常见心情',
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 最常去的地方
            if (stats.mostVisitedPlaces.isNotEmpty) ...[
              const Text(
                '最常去的地方',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: stats.mostVisitedPlaces
                    .map((place) => Chip(
                          label: Text(
                            place,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue.shade100,
                          padding: const EdgeInsets.all(4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],

            // 常用标签
            if (stats.mostUsedTags.isNotEmpty) ...[
              const Text(
                '常用标签',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: stats.mostUsedTags
                    .map((tag) => Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.green.shade100,
                          padding: const EdgeInsets.all(4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String emoji,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
        return '�� 平静';
    }
  }
}
