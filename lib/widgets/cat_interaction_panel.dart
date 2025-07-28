import 'package:cuddle_cat/models/cat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../utils/cat_emoji_expressions.dart';
import '../utils/animation_utils.dart';
import 'cat_interaction_animation.dart';
import 'animated_hand_drawn_button.dart';

class CatInteractionPanel extends StatefulWidget {
  final VoidCallback? onPetCat;

  const CatInteractionPanel({
    super.key,
    this.onPetCat,
  });

  @override
  State<CatInteractionPanel> createState() => _CatInteractionPanelState();
}

class _CatInteractionPanelState extends State<CatInteractionPanel>
    with TickerProviderStateMixin {
  InteractionAnimationType? _currentAnimation;
  Offset? _animationPosition;
  String? _currentEmoji;
  String? _moodEmoji;
  late AnimationController _emojiController;
  late AnimationController _moodController;
  late Animation<double> _emojiScaleAnimation;
  late Animation<double> _emojiOpacityAnimation;
  late Animation<double> _emojiFloatAnimation;
  late Animation<double> _moodPulseAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化emoji反馈动画控制器
    _emojiController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 初始化心情脉冲动画控制器
    _moodController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 设置emoji动画 - 增强弹性效果
    _emojiScaleAnimation = Tween<double>(begin: 0.3, end: 1.4).animate(
      CurvedAnimation(
        parent: _emojiController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _emojiOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _emojiController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // 添加浮动动画
    _emojiFloatAnimation = Tween<double>(begin: 0.0, end: -30.0).animate(
      CurvedAnimation(
        parent: _emojiController,
        curve: Curves.easeOut,
      ),
    );

    // 设置心情脉冲动画
    _moodPulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _moodController,
        curve: Curves.easeInOut,
      ),
    );

    // 启动心情脉冲动画循环
    _moodController.repeat(reverse: true);

    // 监听emoji动画完成
    _emojiController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentEmoji = null;
        });
        _emojiController.reset();
      }
    });

    // 定期更新状态（每30秒）
    Future.delayed(const Duration(seconds: 30), _periodicUpdate);
  }

  void _periodicUpdate() {
    if (mounted) {
      setState(() {
        // 触发重建以更新冷却时间和心情
      });
      // 安排下次更新
      Future.delayed(const Duration(seconds: 30), _periodicUpdate);
    }
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  void _showInteractionAnimation(
      InteractionAnimationType type, Offset position) {
    setState(() {
      _currentAnimation = type;
      _animationPosition = position;
    });
  }

  void _showEmojiReaction(
      InteractionAnimationType type, CatProvider catProvider) {
    if (catProvider.cat != null) {
      final cat = catProvider.cat!;
      // 使用动态emoji表达系统，提供更丰富的反馈
      final emoji = CatEmojiExpressions.getDynamicInteractionEmoji(type, cat);

      setState(() {
        _currentEmoji = emoji;
      });
      _emojiController.forward();

      // 根据连击数量调整触觉反馈强度
      if (cat.interactionCombo >= 5) {
        HapticFeedback.heavyImpact();
      } else if (cat.interactionCombo >= 3) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _updateMoodEmoji(CatProvider catProvider) {
    if (catProvider.cat != null) {
      final cat = catProvider.cat!;
      String newMoodEmoji;

      // 检查是否有心情变化，显示过渡表情
      if (cat.previousMood != null && cat.previousMood != cat.mood) {
        newMoodEmoji = CatEmojiExpressions.getMoodTransitionEmoji(
            cat.previousMood!, cat.mood);
      }
      // 根据不同状态组合选择emoji
      else if (cat.happiness > 80 && cat.energyLevel > 70) {
        newMoodEmoji = CatEmojiExpressions.getRandomHappyEmoji();
      } else if (cat.happiness < 30) {
        newMoodEmoji = CatEmojiExpressions.getRandomCareEmoji();
      } else {
        newMoodEmoji = CatEmojiExpressions.getFrequencyBasedEmoji(cat);
      }

      if (_moodEmoji != newMoodEmoji) {
        // 使用addPostFrameCallback避免在build期间调用setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _moodEmoji = newMoodEmoji;
            });
            // 重启脉冲动画以突出变化
            _moodController.reset();
            _moodController.repeat(reverse: true);
          }
        });
      }
    }
  }

  void _onAnimationComplete() {
    setState(() {
      _currentAnimation = null;
      _animationPosition = null;
    });
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
    required bool isEnabled,
    required String cooldownText,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: Matrix4.identity()..scale(isEnabled ? 1.0 : 0.95),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isEnabled ? 1.0 : 0.6,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: AnimatedScale(
                    scale: isEnabled ? 1.0 : 0.9,
                    duration: const Duration(milliseconds: 200),
                    child: MaterialButton(
                      onPressed: isEnabled
                          ? () {
                              // 添加按压动画效果和缩放反馈
                              HapticFeedback.mediumImpact();

                              // 创建临时的缩放动画
                              final controller = AnimationController(
                                duration: const Duration(milliseconds: 150),
                                vsync: this,
                              );

                              controller.forward().then((_) {
                                controller.reverse();
                                controller.dispose();
                              });

                              onPressed();
                            }
                          : null,
                      color: color.withOpacity(0.2),
                      shape: const CircleBorder(),
                      elevation: isEnabled ? 3 : 0,
                      animationDuration: const Duration(milliseconds: 150),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          icon,
                          color: color,
                          size: 24,
                          key: ValueKey('$icon-$isEnabled'),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isEnabled)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withOpacity(0.4),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 42,
                          height: 42,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _getCooldownProgress(cooldownText),
                                strokeWidth: 4,
                                backgroundColor:
                                    Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getCooldownProgress(cooldownText) > 0.8
                                      ? Colors.green.withOpacity(0.8)
                                      : _getCooldownProgress(cooldownText) > 0.5
                                          ? Colors.orange.withOpacity(0.8)
                                          : Colors.red.withOpacity(0.8),
                                ),
                              ),
                              // 添加脉冲效果
                              if (_getCooldownProgress(cooldownText) > 0.9)
                                AnimatedBuilder(
                                  animation: _moodController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 1.0 +
                                          (_moodPulseAnimation.value - 1.0) *
                                              0.1,
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.green
                                                .withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _getCooldownProgress(cooldownText) > 0.9
                                ? '✨'
                                : _getCooldownProgress(cooldownText) > 0.7
                                    ? '🔄'
                                    : '⏰',
                            key: ValueKey(
                                (_getCooldownProgress(cooldownText) * 10)
                                    .round()),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isEnabled ? FontWeight.normal : FontWeight.w300,
                color: isEnabled ? Colors.black87 : Colors.black45,
              ),
            ),
            if (!isEnabled && cooldownText.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCooldownProgress(cooldownText) > 0.8
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getCooldownProgress(cooldownText) > 0.8
                        ? Colors.green.withOpacity(0.4)
                        : Colors.orange.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _getCooldownProgress(cooldownText) > 0.9
                            ? '✨'
                            : _getCooldownProgress(cooldownText) > 0.7
                                ? '🔄'
                                : '⏰',
                        key: ValueKey(
                            (_getCooldownProgress(cooldownText) * 10).round()),
                        style: const TextStyle(fontSize: 8),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      cooldownText.replaceAll('冷却中 ', ''),
                      style: TextStyle(
                        fontSize: 9,
                        color: _getCooldownProgress(cooldownText) > 0.8
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCooldown(int seconds) {
    if (seconds < 60) {
      return '$seconds秒';
    }
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '$minutes分钟';
    }
    final hours = minutes ~/ 60;
    return '$hours小时';
  }

  double _getCooldownProgress(String cooldownText) {
    if (cooldownText.isEmpty) return 1.0;

    // 简化的进度计算，基于冷却文本
    if (cooldownText.contains('秒')) {
      final seconds =
          int.tryParse(cooldownText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return 1.0 - (seconds / 60.0); // 假设最大60秒
    } else if (cooldownText.contains('分钟')) {
      final minutes =
          int.tryParse(cooldownText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return 1.0 - (minutes / 60.0); // 假设最大60分钟
    } else if (cooldownText.contains('小时')) {
      final hours =
          int.tryParse(cooldownText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return 1.0 - (hours / 24.0); // 假设最大24小时
    }

    return 0.5; // 默认50%进度
  }

  Color _getMoodColor(CatMoodState mood) {
    switch (mood) {
      case CatMoodState.happy:
        return Colors.green;
      case CatMoodState.normal:
        return Colors.blue;
      case CatMoodState.hungry:
        return Colors.orange;
      case CatMoodState.tired:
        return Colors.purple;
      case CatMoodState.bored:
        return Colors.grey;
    }
  }

  // 特殊的拥抱效果
  void _showSpecialHugEffect() {
    // 显示爱心粒子效果
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _showFloatingEmoji('💖', Offset(
            (i - 2) * 30.0,
            -60.0 - (i * 10),
          ));
        }
      });
    }

    // 触觉反馈
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
  }

  // 显示浮动emoji效果
  void _showFloatingEmoji(String emoji, Offset position) {
    setState(() {
      _currentEmoji = emoji;
      _animationPosition = position;
    });

    _emojiController.reset();
    _emojiController.forward();
  }

  Widget _buildStatusBar(String emoji, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Container(
          width: 40,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100.0,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$value%',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CatProvider>(
      builder: (context, catProvider, child) {
        if (!catProvider.hasCat) {
          return const SizedBox.shrink();
        }

        // 更新心情emoji
        _updateMoodEmoji(catProvider);

        return Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                // 猫咪心情状态显示 - 增强视觉效果
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getMoodColor(catProvider.cat!.mood)
                            .withOpacity(0.1),
                        _getMoodColor(catProvider.cat!.mood)
                            .withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getMoodColor(catProvider.cat!.mood)
                          .withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _moodPulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _moodPulseAnimation.value,
                                child: Text(
                                  _moodEmoji ?? '😺',
                                  style: const TextStyle(fontSize: 28),
                                ),
                              );
                            },
                          ),
                          // 添加时间相关的小装饰
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Text(
                              CatEmojiExpressions.getTimeBasedEmoji(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${catProvider.cat!.name} 现在${catProvider.cat!.moodText}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // 显示连击信息
                                if (catProvider.cat!.interactionCombo >= 2)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange
                                            .withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          CatEmojiExpressions
                                              .getInteractionComboEmoji(
                                                  catProvider
                                                      .cat!.interactionCombo),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${catProvider.cat!.interactionCombo}连击',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                _buildStatusBar('❤️',
                                    catProvider.cat!.happiness, Colors.red),
                                const SizedBox(width: 8),
                                _buildStatusBar(
                                    '⚡',
                                    catProvider.cat!.energyLevel,
                                    Colors.orange),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 互动按钮
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInteractionButton(
                        icon: Icons.pets,
                        color: Colors.pink,
                        label: '抚摸',
                        onPressed: () {
                          catProvider.petCat();
                          widget.onPetCat?.call();
                          _showInteractionAnimation(
                            InteractionAnimationType.pet,
                            const Offset(0, -50),
                          );
                          _showEmojiReaction(
                              InteractionAnimationType.pet, catProvider);
                        },
                        isEnabled: true,
                        cooldownText: '',
                      ),
                      _buildInteractionButton(
                        icon: Icons.restaurant,
                        color: Colors.orange,
                        label: '喂食',
                        onPressed: () {
                          catProvider.feedCat();
                          _showInteractionAnimation(
                            InteractionAnimationType.feed,
                            const Offset(0, -50),
                          );
                          _showEmojiReaction(
                              InteractionAnimationType.feed, catProvider);
                        },
                        isEnabled: catProvider.canFeedCat(),
                        cooldownText: catProvider.canFeedCat()
                            ? ''
                            : '冷却中 ${_formatCooldown(catProvider.getFeedCooldown())}',
                      ),
                      _buildInteractionButton(
                        icon: Icons.toys,
                        color: Colors.purple,
                        label: '玩耍',
                        onPressed: () {
                          catProvider.playWithCat();
                          _showInteractionAnimation(
                            InteractionAnimationType.play,
                            const Offset(0, -50),
                          );
                          _showEmojiReaction(
                              InteractionAnimationType.play, catProvider);
                        },
                        isEnabled: catProvider.canPlayWithCat(),
                        cooldownText: catProvider.canPlayWithCat()
                            ? ''
                            : '冷却中 ${_formatCooldown(catProvider.getPlayCooldown())}',
                      ),
                      _buildInteractionButton(
                        icon: Icons.shower,
                        color: Colors.blue,
                        label: '梳理',
                        onPressed: () {
                          catProvider.groomCat();
                          _showInteractionAnimation(
                            InteractionAnimationType.groom,
                            const Offset(0, -50),
                          );
                          _showEmojiReaction(
                              InteractionAnimationType.groom, catProvider);
                        },
                        isEnabled: catProvider.canGroomCat(),
                        cooldownText: catProvider.canGroomCat()
                            ? ''
                            : '冷却中 ${_formatCooldown(catProvider.getGroomCooldown())}',
                      ),
                      // 新增互动方式：拥抱
                      _buildInteractionButton(
                        icon: Icons.favorite,
                        color: Colors.pink,
                        label: '拥抱',
                        onPressed: () {
                          catProvider.hugCat();
                          _showInteractionAnimation(
                            InteractionAnimationType.pet,
                            const Offset(0, -30),
                          );
                          _showEmojiReaction(
                              InteractionAnimationType.pet, catProvider);
                          // 特殊的拥抱效果
                          _showSpecialHugEffect();
                        },
                        isEnabled: true,
                        cooldownText: '',
                      ),
                      _buildInteractionButton(
                        icon: Icons.school,
                        color: Colors.amber,
                        label: '训练',
                        onPressed: () {
                          catProvider.trainCat();
                          _showInteractionAnimation(
                            InteractionAnimationType.train,
                            const Offset(0, -50),
                          );
                          _showEmojiReaction(
                              InteractionAnimationType.train, catProvider);
                        },
                        isEnabled: catProvider.canTrainCat(),
                        cooldownText: catProvider.canTrainCat()
                            ? ''
                            : '冷却中 ${_formatCooldown(catProvider.getTrainCooldown())}',
                      ),
                      _buildInteractionButton(
                        icon: Icons.chat_bubble_outline,
                        color: Colors.teal,
                        label: '对话',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('对话功能即将开放！')));
                        },
                        isEnabled: true,
                        cooldownText: '',
                      ),
                    ],
                  ),
                ),
              ],
                ),
              ),
            // 互动动画
            if (_currentAnimation != null && _animationPosition != null)
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 25,
                top: MediaQuery.of(context).size.height / 2 +
                    _animationPosition!.dy,
                child: CatInteractionAnimation(
                  type: _currentAnimation!,
                  size: 50,
                  onComplete: _onAnimationComplete,
                ),
              ),
            // Emoji反馈显示 - 增强动画效果
            if (_currentEmoji != null)
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 30,
                top: 50,
                child: AnimatedBuilder(
                  animation: _emojiController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _emojiFloatAnimation.value),
                      child: Opacity(
                        opacity: _emojiOpacityAnimation.value,
                        child: Transform.scale(
                          scale: _emojiScaleAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getMoodColor(catProvider.cat!.mood)
                                    .withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getMoodColor(catProvider.cat!.mood)
                                      .withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentEmoji!,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+${catProvider.cat!.interactionCombo}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getMoodColor(catProvider.cat!.mood),
                                  ),
                                ),
                                Text(
                                  _currentEmoji!,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                // 如果有连击，显示连击特效
                                if (catProvider.cat!.interactionCombo >= 3)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          CatEmojiExpressions
                                              .getInteractionComboEmoji(
                                                  catProvider
                                                      .cat!.interactionCombo),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          '${catProvider.cat!.interactionCombo}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getMoodColor(
                                                catProvider.cat!.mood),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
