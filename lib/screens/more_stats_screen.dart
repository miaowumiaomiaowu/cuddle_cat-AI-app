import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/mood_provider.dart';
import '../providers/dialogue_provider.dart';
import '../models/mood_record.dart';
import '../widgets/artistic_chart.dart';

class MoreStatsScreen extends StatelessWidget {
  static const routeName = '/more_stats';
  const MoreStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的统计')),
      body: Consumer2<MoodProvider, DialogueProvider>(
        builder: (context, mood, dialogue, _) {
          final entries = mood.moodEntries;
          final analytics = MoodAnalytics.fromEntries(entries);
          final sessions = dialogue.historySessions;
          final totalMessages = sessions.fold<int>(0, (sum, s) => sum + s.messages.length);
          final chatSessions = sessions.length;

          // 简单使用时长估算：会话持续时间合计（分钟）
          final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationInMinutes);

          final positiveRatio = analytics.positiveRatio;
          final negativeRatio = analytics.negativeRatio;
          final neutralRatio = 1.0 - positiveRatio - negativeRatio;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('关键指标', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacingMedium),
                _kpiRow([
                  _KpiCard(label: '心情记录', value: analytics.totalEntries.toString(), icon: Icons.edit_note),
                  _KpiCard(label: '聊天条数', value: totalMessages.toString(), icon: Icons.forum),
                  _KpiCard(label: '聊天会话', value: chatSessions.toString(), icon: Icons.chat_bubble_outline),
                  _KpiCard(label: '使用时长', value: '${(totalMinutes / 60).toStringAsFixed(1)}h', icon: Icons.timer),
                ]),

                const SizedBox(height: AppTheme.spacingLarge),
                Text('情绪概览', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacingMedium),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ArtisticChart(
                        value: positiveRatio.clamp(0.0, 1.0),
                        label: '积极占比',
                        icon: Icons.sentiment_satisfied_alt,
                        color: const Color(0xFF34D399),
                        size: 140,
                      ),
                      const SizedBox(width: 16),
                      ArtisticChart(
                        value: neutralRatio.clamp(0.0, 1.0),
                        label: '中性占比',
                        icon: Icons.sentiment_neutral,
                        color: Colors.blueGrey,
                        size: 140,
                      ),
                      const SizedBox(width: 16),
                      ArtisticChart(
                        value: negativeRatio.clamp(0.0, 1.0),
                        label: '消极占比',
                        icon: Icons.sentiment_dissatisfied,
                        color: const Color(0xFFF87171),
                        size: 140,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLarge),
                Text('近7日趋势', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacingMedium),
                _TrendMiniChart(points: analytics.dailyTrend),

                const SizedBox(height: AppTheme.spacingLarge),
                Text('Top 情绪词', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacingSmall),
                _moodDistributionChips(analytics.moodDistribution),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

Widget _kpiRow(List<Widget> cards) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: cards),
  );
}

class _TrendMiniChart extends StatelessWidget {
  final List<MoodTrendPoint> points;
  const _TrendMiniChart({required this.points});
  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text('暂无数据'),
      );
    }
    final maxY = points.map((e) => e.averageIntensity as num).fold<double>(0, (a, b) => a > b ? a : b.toDouble());
    final minY = points.map((e) => e.averageIntensity as num).fold<double>(999, (a, b) => a < b ? a : b.toDouble());
    final span = (maxY - minY).abs() < 1e-6 ? 1.0 : (maxY - minY);
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _TrendPainter(points: points, minY: minY, maxY: maxY, span: span),
        child: Container(),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<MoodTrendPoint> points;
  final double minY;
  final double maxY;
  final double span;
  _TrendPainter({required this.points, required this.minY, required this.maxY, required this.span});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1).clamp(1, 999));
      final norm = ((points[i].averageIntensity) - minY) / span;
      final y = size.height - norm * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Widget _moodDistributionChips(Map<MoodType, int> dist) {
  if (dist.isEmpty) return const Text('暂无心情记录');
  final sorted = dist.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final e in sorted.take(10))
        Chip(label: Text('${e.key.name} · ${e.value}')),
    ],
  );
}

