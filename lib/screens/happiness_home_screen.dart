import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/happiness_provider.dart';
import '../providers/mood_provider.dart';
import '../theme/artistic_theme.dart';
import 'happiness_task_edit_screen.dart';
import '../widgets/happiness_gift_view.dart';
import '../widgets/memory_review_card.dart';
import '../services/memory_service.dart';

class HappinessHomeScreen extends StatefulWidget {
  const HappinessHomeScreen({super.key});

  @override
  State<HappinessHomeScreen> createState() => _HappinessHomeScreenState();
}

class _HappinessHomeScreenState extends State<HappinessHomeScreen> {
  final MemoryService _memoryService = MemoryService();
  List<MemoryEvent> _recentMemories = [];
  bool _showMemoryReview = false;

  @override
  void initState() {
    super.initState();
    _checkMemoryReview();
  }

  Future<void> _checkMemoryReview() async {
    final shouldShow = await _memoryService.shouldShowReview();
    if (shouldShow) {
      final memories = await _memoryService.getRecentBreakthroughs();
      if (memories.isNotEmpty) {
        setState(() {
          _recentMemories = memories;
          _showMemoryReview = true;
        });
      }
    }
  }

  void _dismissMemoryReview() async {
    await _memoryService.markReviewShown();
    setState(() {
      _showMemoryReview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HappinessProvider, MoodProvider>(
      builder: (context, hp, mp, _) {
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () => hp.refreshAIRecommendations(force: true),
            child: Stack(
              children: [
                const HappinessGiftView(),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: _buildHeader(context, hp),
                ),
                if (_showMemoryReview)
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: MemoryReviewCard(
                      memories: _recentMemories,
                      onDismiss: _dismissMemoryReview,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, HappinessProvider hp) {
    final stats = hp.stats;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtisticTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ArtisticTheme.softShadow,
      ),
      child: Row(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日幸福清单', style: ArtisticTheme.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(stats == null
                    ? '和我一起做一件小幸福事吧'
                    : '连续: ${stats.currentStreak} 天 · 近7天完成率: ${(stats.completionRate7d*100).toStringAsFixed(0)}%'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(HappinessTaskEditScreen.routeName),
            icon: const Icon(Icons.add),
            label: const Text('新建任务'),
          ),
        ],
      ),
    );
  }

  // 推荐列表不再作为主 UI 展示，保留顶部卡片与礼物体验

}

