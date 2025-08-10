import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/travel_destinations.dart';
import '../providers/travel_provider.dart';
import '../utils/animation_utils.dart';
import '../widgets/animated_hand_drawn_button.dart';

class QuickTravelWidget extends StatefulWidget {
  const QuickTravelWidget({super.key});

  @override
  State<QuickTravelWidget> createState() => _QuickTravelWidgetState();
}

class _QuickTravelWidgetState extends State<QuickTravelWidget> {
  String? _selectedDestination;
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    return HandDrawnAnimatedWidget(
      animationType: AnimationType.slideIn,
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingMedium),
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentColor.withValues(alpha: 0.1),
              AppTheme.accentColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('✈️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '快速添加旅行',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              '选择一个热门目的地，快速创建旅行记录',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            
            // 目的地选择
            _buildDestinationSelector(),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            // 添加按钮
            if (_selectedDestination != null)
              AnimatedHandDrawnButton(
                text: _isAdding ? '添加中...' : '添加到我的旅行',
                emoji: '➕',
                isPrimary: true,
                isLoading: _isAdding,
                onPressed: _isAdding ? null : () => _addQuickTravel(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationSelector() {
    final destinations = TravelDestinations.destinations.take(8).toList();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: destinations.map((dest) {
        final isSelected = _selectedDestination == dest['name'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDestination = isSelected ? null : dest['name'];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? AppTheme.primaryColor
                    : AppTheme.textHint.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dest['emoji'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  dest['name'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _addQuickTravel({String mood = 'normal'}) async {
    if (_selectedDestination == null) return;

    setState(() {
      _isAdding = true;
    });

    try {
      final travelRecord = TravelDestinations.createQuickTravelRecord(
        _selectedDestination!,
        customTitle: '${TravelDestinations.getDestinationByName(_selectedDestination!)!['emoji']} 探索${_selectedDestination}',
        customDescription: '今天和猫咪一起探索了${_selectedDestination}，留下了美好的回忆！ 🐱',
      );

      final provider = Provider.of<TravelProvider>(context, listen: false);
      await provider.addTravel(travelRecord);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加${_selectedDestination}的旅行记录！ ✨'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        setState(() {
          _selectedDestination = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加失败：$e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }
}

// 旅行推荐组件
class TravelRecommendationWidget extends StatelessWidget {
  final String mood;
  
  const TravelRecommendationWidget({
    super.key,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = TravelDestinations.getRecommendationsByMood(mood);
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return HandDrawnAnimatedWidget(
      animationType: AnimationType.fadeIn,
      delay: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingMedium),
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.primaryColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '为你推荐',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '根据当前心情为你推荐合适的旅行目的地',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.take(5).length,
                itemBuilder: (context, index) {
                  final dest = recommendations[index];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              dest['emoji'],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dest['name'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (dest['tags'] as List<String>).first,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
