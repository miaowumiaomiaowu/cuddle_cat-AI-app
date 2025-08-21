import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../theme/artistic_theme.dart';
import '../theme/app_theme.dart';

import '../providers/mood_provider.dart';
import '../models/mood_record.dart';

import '../screens/enhanced_mood_entry_screen.dart';
import '../screens/dialogue_screen.dart';
import '../providers/happiness_provider.dart';
import '../screens/happiness_task_edit_screen.dart';



/// 快速记录浮动操作按钮
class QuickRecordFAB extends StatefulWidget {
  const QuickRecordFAB({super.key});

  @override
  State<QuickRecordFAB> createState() => _QuickRecordFABState();
}

class _QuickRecordFABState extends State<QuickRecordFAB>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _menuController;
  late Animation<double> _fabAnimation;
  late Animation<double> _menuAnimation;

  bool _isMenuOpen = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _menuController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fabAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });

    if (_isMenuOpen) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }

    HapticFeedback.lightImpact();
  }

  void _closeMenu() {
    if (_isMenuOpen) {
      setState(() {
        _isMenuOpen = false;
      });
      _menuController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // 背景遮罩
        if (_isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              child: AnimatedBuilder(
                animation: _menuAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.3 * _menuAnimation.value),
                  );
                },
              ),
            ),
          ),

        // 菜单项
        AnimatedBuilder(
          animation: _menuAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // AI聊天
                Transform.translate(
                  offset: Offset(0, -100 * _menuAnimation.value),
                  child: Transform.scale(
                    scale: _menuAnimation.value,
                    child: _buildMenuButton(
                      icon: Icons.psychology,
                      label: 'AI聊天',
                      color: ArtisticTheme.infoColor,
                      onPressed: () => _openAIChat(context),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 详细心情记录
                Transform.translate(
                  offset: Offset(0, -80 * _menuAnimation.value),
                  child: Transform.scale(
                    scale: _menuAnimation.value,
                    child: _buildMenuButton(
                      icon: Icons.edit_note,
                      label: '详细记录',
                      color: ArtisticTheme.joyColor,
                      onPressed: () => _openDetailedMoodEntry(context),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 快速心情记录
                Transform.translate(
                  offset: Offset(0, -60 * _menuAnimation.value),
                  child: Transform.scale(
                    scale: _menuAnimation.value,
                    child: _buildMenuButton(
                      icon: Icons.mood,
                      label: '快速心情',
                      color: ArtisticTheme.accentColor,
                      onPressed: () => _quickAddMood(context),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 幸福打卡
                Transform.translate(
                  offset: Offset(0, -40 * _menuAnimation.value),
                  child: Transform.scale(
                    scale: _menuAnimation.value,
                    child: _buildMenuButton(
                      icon: Icons.favorite,
                      label: '幸福打卡',
                      color: ArtisticTheme.primaryColor,
                      onPressed: () => _quickHappiness(context),
                    ),
                  ),
                ),


                // 添加幸福任务
                Transform.translate(
                  offset: Offset(0, -20 * _menuAnimation.value),
                  child: Transform.scale(
                    scale: _menuAnimation.value,
                    child: _buildMenuButton(
                      icon: Icons.add_task,
                      label: '添加任务',
                      color: ArtisticTheme.accentColor,
                      onPressed: () => _createHappinessTask(context),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 主FAB
                AnimatedBuilder(
                  animation: _fabAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _fabAnimation.value,
                      child: FloatingActionButton(
                        onPressed: _isRecording ? null : _toggleMenu,
                        backgroundColor: _isMenuOpen
                          ? ArtisticTheme.errorColor
                          : ArtisticTheme.primaryColor,
                        child: _isRecording
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : AnimatedRotation(
                              turns: _isMenuOpen ? 0.125 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                _isMenuOpen ? Icons.close : Icons.add,
                                color: Colors.white,
                              ),
                            ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: ArtisticTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ArtisticTheme.softShadow,
          ),
          child: Text(
            label,
            style: ArtisticTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: color,
          heroTag: label,
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }

  Future<void> _quickHappiness(BuildContext context) async {
    _closeMenu();
    setState(() => _isRecording = true);
    try {
      HapticFeedback.mediumImpact();
      final hp = Provider.of<HappinessProvider>(context, listen: false);
      // 默认微幸福：4-7-8呼吸
      await hp.quickMicroHappiness(title: '4-7-8 呼吸', emoji: '🫁', category: 'mind', estimatedMinutes: 3);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🌿 已完成一件小幸福事'),
            backgroundColor: ArtisticTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: ArtisticTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _createHappinessTask(BuildContext context) async {
    _closeMenu();
    await Navigator.of(context).pushNamed(HappinessTaskEditScreen.routeName);
  }

  Future<void> _openAIChat(BuildContext context) async {
    _closeMenu();

    Navigator.pushNamed(context, DialogueScreen.routeName);
  }

  Future<void> _openDetailedMoodEntry(BuildContext context) async {
    _closeMenu();

    Navigator.pushNamed(context, EnhancedMoodEntryScreen.routeName);
  }

  Future<void> _quickAddMood(BuildContext context) async {
    _closeMenu();

    // 显示心情选择对话框
    final selectedMood = await showGeneralDialog<MoodType>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dialog',
      transitionDuration: AppTheme.motionMedium,
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: AppTheme.easeStandard);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: _MoodSelectionDialog(),
          ),
        );
      },
    );

    if (selectedMood != null) {
      if (!mounted || !context.mounted) return;
      final moodProvider = Provider.of<MoodProvider>(context, listen: false);
      await moodProvider.quickAddMood(selectedMood);

      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('😊 心情记录已添加: ${MoodTypeConfig.getMoodName(selectedMood)}'),
            backgroundColor: ArtisticTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

/// 心情选择对话框
class _MoodSelectionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择心情'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: MoodTypeConfig.getAllMoodTypes().length,
          itemBuilder: (context, index) {
            final moodType = MoodTypeConfig.getAllMoodTypes()[index];
            final color = MoodTypeConfig.getMoodColor(moodType);
            final emoji = MoodTypeConfig.getMoodEmoji(moodType);
            final name = MoodTypeConfig.getMoodName(moodType);

            return GestureDetector(
              onTap: () => Navigator.of(context).pop(moodType),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: ArtisticTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


