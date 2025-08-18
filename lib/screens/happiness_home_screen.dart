import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/happiness_provider.dart';
import '../providers/mood_provider.dart';
import '../theme/artistic_theme.dart';
import '../widgets/happiness_gift_view.dart';
import '../widgets/memory_review_card.dart';
import '../widgets/wellness_plan_card.dart';
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
                // 顶部今日幸福清单栏目已移除，改为说明与自定义入口
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildExplainer(context),
                        const SizedBox(height: 12),
                        const WellnessPlanCard(),
                      ],
                    ),
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

  Widget _buildExplainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtisticTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ArtisticTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '幸福清单基于你的状态由AI分析生成。完整设置与自定义已迁移到“智能分析”。',
                  style: ArtisticTheme.caption,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 推荐列表不再作为主 UI 展示，保留礼物体验
}

