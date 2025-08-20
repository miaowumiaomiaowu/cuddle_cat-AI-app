import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'package:provider/provider.dart';
import '../theme/artistic_theme.dart';
import '../providers/mood_provider.dart';

import '../widgets/hand_drawn_card.dart';
import '../models/mood_record.dart';

import 'dart:math' as math;

/// 心情地图页面 - 显示不同地点的心情记录
class MoodMapScreen extends StatefulWidget {
  static const String routeName = '/mood_map';

  const MoodMapScreen({super.key});

  @override
  State<MoodMapScreen> createState() => _MoodMapScreenState();
}

class _MoodMapScreenState extends State<MoodMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;
  String _selectedTimeRange = 'all'; // all, week, month, year
  MoodType? _selectedMoodFilter;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisticTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '心情地图',
          style: ArtisticTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部时间')),
              const PopupMenuItem(value: 'week', child: Text('本周')),
              const PopupMenuItem(value: 'month', child: Text('本月')),
              const PopupMenuItem(value: 'year', child: Text('本年')),
            ],
          ),
          PopupMenuButton<MoodType?>(
            icon: const Icon(Icons.mood),
            onSelected: (value) {
              setState(() {
                _selectedMoodFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('全部心情')),
              ...MoodTypeConfig.getAllMoodTypes().map((mood) =>
                PopupMenuItem(
                  value: mood,
                  child: Row(
                    children: [
                      Text(MoodTypeConfig.getMoodEmoji(mood)),
                      const SizedBox(width: 8),
                      Text(MoodTypeConfig.getMoodName(mood)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildStatsBar(),
            Expanded(
              child: _buildMoodMap(),
            ),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        final filteredEntries = _getFilteredEntries(moodProvider);
        final positiveCount = filteredEntries.where((e) => e.isPositive).length;
        final negativeCount = filteredEntries.where((e) => e.isNegative).length;
        final neutralCount = filteredEntries.length - positiveCount - negativeCount;

        return Container(
          margin: const EdgeInsets.all(ArtisticTheme.spacingMedium),
          child: HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '积极',
                      positiveCount.toString(),
                      ArtisticTheme.successColor,
                      '😊',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '中性',
                      neutralCount.toString(),
                      ArtisticTheme.textSecondary,
                      '😐',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '消极',
                      negativeCount.toString(),
                      ArtisticTheme.warningColor,
                      '😔',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '总计',
                      filteredEntries.length.toString(),
                      ArtisticTheme.primaryColor,
                      '📍',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: ArtisticTheme.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: ArtisticTheme.caption,
        ),
      ],
    );
  }

  Widget _buildMoodMap() {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        final filteredEntries = _getFilteredEntries(moodProvider);
        final locationGroups = _groupEntriesByLocation(filteredEntries);

        if (locationGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: ArtisticTheme.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无心情地图数据',
                  style: ArtisticTheme.bodyLarge.copyWith(
                    color: ArtisticTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '开始记录带有位置信息的心情吧！',
                  style: ArtisticTheme.bodyMedium.copyWith(
                    color: ArtisticTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onScaleUpdate: (details) {
            setState(() {
              _zoomLevel = (_zoomLevel * details.scale).clamp(0.5, 3.0);
              _panOffset += details.focalPointDelta;
            });
          },
          child: Transform(
            transform: Matrix4.identity()
              ..translate(_panOffset.dx, _panOffset.dy)
              ..scale(_zoomLevel),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ArtisticTheme.backgroundColor,
                    ArtisticTheme.surfaceColor.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: MoodMapPainter(locationGroups, _zoomLevel),
                child: Stack(
                  children: locationGroups.entries.map((entry) {
                    return _buildLocationMarker(entry.key, entry.value);
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationMarker(String location, List<MoodEntry> entries) {
    final dominantMood = _getDominantMood(entries);
    final color = MoodTypeConfig.getMoodColor(dominantMood);
    final emoji = MoodTypeConfig.getMoodEmoji(dominantMood);

    // 简化的位置计算（实际项目中应该使用真实的地理坐标）
    final position = _calculateMarkerPosition(location, entries);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: () => _showLocationDetails(location, entries),
        child: Container(
          width: 60 + (entries.length * 2).toDouble().clamp(0, 20),
          height: 60 + (entries.length * 2).toDouble().clamp(0, 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              Text(
                '${entries.length}',
                style: ArtisticTheme.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
      decoration: BoxDecoration(
        color: ArtisticTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '图例',
            style: ArtisticTheme.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('😊', '积极心情', ArtisticTheme.successColor),
              _buildLegendItem('😐', '中性心情', ArtisticTheme.textSecondary),
              _buildLegendItem('😔', '消极心情', ArtisticTheme.warningColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '圆圈大小表示记录数量，点击查看详情',
            style: ArtisticTheme.caption.copyWith(
              color: ArtisticTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String emoji, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 4),
        Text(emoji),
        const SizedBox(width: 4),
        Text(
          label,
          style: ArtisticTheme.caption,
        ),
      ],
    );
  }

  List<MoodEntry> _getFilteredEntries(MoodProvider moodProvider) {
    var entries = moodProvider.moodEntries.where((entry) => entry.locationName != null).toList();

    // 时间过滤
    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        entries = entries.where((e) => e.timestamp.isAfter(weekAgo)).toList();
        break;
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        entries = entries.where((e) => e.timestamp.isAfter(monthAgo)).toList();
        break;
      case 'year':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        entries = entries.where((e) => e.timestamp.isAfter(yearAgo)).toList();
        break;
    }

    // 心情过滤
    if (_selectedMoodFilter != null) {
      entries = entries.where((e) => e.mood == _selectedMoodFilter).toList();
    }

    return entries;
  }

  Map<String, List<MoodEntry>> _groupEntriesByLocation(List<MoodEntry> entries) {
    final Map<String, List<MoodEntry>> groups = {};

    for (final entry in entries) {
      if (entry.locationName != null) {
        final location = entry.locationName!;
        groups[location] = groups[location] ?? [];
        groups[location]!.add(entry);
      }
    }

    return groups;
  }

  MoodType _getDominantMood(List<MoodEntry> entries) {
    if (entries.isEmpty) return MoodType.neutral;

    final moodCounts = <MoodType, int>{};
    for (final entry in entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }

    return moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Offset _calculateMarkerPosition(String location, List<MoodEntry> entries) {
    // 简化的位置计算（实际项目中应该使用真实的地理坐标转换）
    final hash = location.hashCode;
    final random = math.Random(hash);

    return Offset(
      50 + random.nextDouble() * 250,
      50 + random.nextDouble() * 300,
    );
  }

  void _showLocationDetails(String location, List<MoodEntry> entries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final routeAnim = ModalRoute.of(context)!.animation!;
        return AnimatedBuilder(
          animation: routeAnim,
          builder: (ctx, child) {
            final curved = CurvedAnimation(parent: routeAnim, curve: AppTheme.easeStandard);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
                child: child!,
              ),
            );
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: ArtisticTheme.surfaceColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: ArtisticTheme.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: ArtisticTheme.primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location,
                                  style: ArtisticTheme.headlineSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${entries.length} 条心情记录',
                            style: ArtisticTheme.bodyMedium.copyWith(
                              color: ArtisticTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: ArtisticTheme.spacingLarge),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Text(
                                entry.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(MoodTypeConfig.getMoodName(entry.mood)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (entry.description != null) Text(entry.description!),
                                  Text(
                                    '${entry.timestamp.month}/${entry.timestamp.day} ${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: ArtisticTheme.caption,
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: MoodTypeConfig.getMoodColor(entry.mood).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${entry.intensity}/10',
                                  style: ArtisticTheme.caption.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// 心情地图绘制器
class MoodMapPainter extends CustomPainter {
  final Map<String, List<MoodEntry>> locationGroups;
  final double zoomLevel;

  MoodMapPainter(this.locationGroups, this.zoomLevel);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景网格
    final paint = Paint()
      ..color = ArtisticTheme.textSecondary.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (int i = 0; i < size.width; i += 50) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    for (int i = 0; i < size.height; i += 50) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
