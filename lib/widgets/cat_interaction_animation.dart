import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 互动动画类型
enum InteractionAnimationType {
  pet, // 抚摸
  feed, // 喂食
  play, // 玩耍
  groom, // 洗澡/梳理
  train, // 训练
}

/// 猫咪互动动画组件
class CatInteractionAnimation extends StatefulWidget {
  final InteractionAnimationType type;
  final double size;
  final VoidCallback? onComplete;

  const CatInteractionAnimation({
    super.key,
    required this.type,
    this.size = 100,
    this.onComplete,
  });

  @override
  State<CatInteractionAnimation> createState() =>
      _CatInteractionAnimationState();
}

class _CatInteractionAnimationState extends State<CatInteractionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: _buildAnimationContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimationContent() {
    switch (widget.type) {
      case InteractionAnimationType.pet:
        return _buildPetAnimation();
      case InteractionAnimationType.feed:
        return _buildFeedAnimation();
      case InteractionAnimationType.play:
        return _buildPlayAnimation();
      case InteractionAnimationType.groom:
        return _buildGroomAnimation();
      case InteractionAnimationType.train:
        return _buildTrainAnimation();
    }
  }

  Widget _buildPetAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 主要爱心图标
        Icon(
          Icons.favorite,
          color: Colors.pink.withOpacity(0.8),
          size: 30 * (1 + _controller.value * 0.3),
        ),
        // 浮动的小爱心
        Positioned(
          top: -5 - (_controller.value * 10),
          right: -5,
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: Text(
              '💕',
              style: TextStyle(
                fontSize: 16 * (1 + _controller.value * 0.5),
              ),
            ),
          ),
        ),
        // 额外的心形粒子效果
        Positioned(
          top: -8 - (_controller.value * 15),
          left: -8,
          child: Opacity(
            opacity: 0.8 - _controller.value,
            child: Text(
              '💖',
              style: TextStyle(
                fontSize: 12 * (1 + _controller.value * 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 主要餐具图标
        Icon(
          Icons.restaurant,
          color: Colors.orange.withOpacity(0.8),
          size: 30 * (1 + _controller.value * 0.3),
        ),
        // 美味表情
        Positioned(
          top: -8 - (_controller.value * 12),
          right: -8,
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: Text(
              '😋',
              style: TextStyle(
                fontSize: 18 * (1 + _controller.value * 0.4),
              ),
            ),
          ),
        ),
        // 食物emoji
        Positioned(
          top: -5 - (_controller.value * 8),
          left: -10,
          child: Opacity(
            opacity: 0.9 - _controller.value,
            child: Text(
              '🍽️',
              style: TextStyle(
                fontSize: 14 * (1 + _controller.value * 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 旋转的玩具图标
        Transform.rotate(
          angle: _controller.value * math.pi * 2,
          child: Icon(
            Icons.toys,
            color: Colors.purple.withOpacity(0.8),
            size: 30 * (1 + _controller.value * 0.3),
          ),
        ),
        // 弹跳的球
        Positioned(
          top: -5 - (_controller.value * 10),
          left: -5,
          child: Transform.scale(
            scale: 1.0 + (_controller.value * 0.5),
            child: Opacity(
              opacity: 1.0 - _controller.value,
              child: Text(
                '🎾',
                style: TextStyle(
                  fontSize: 16 * (1 + _controller.value * 0.6),
                ),
              ),
            ),
          ),
        ),
        // 玩耍粒子
        Positioned(
          top: -8 - (_controller.value * 15),
          right: -8,
          child: Opacity(
            opacity: 0.8 - _controller.value,
            child: Text(
              '🎯',
              style: TextStyle(
                fontSize: 12 * (1 + _controller.value * 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroomAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 主要清洁图标
        Icon(
          Icons.shower,
          color: Colors.blue.withOpacity(0.8),
          size: 30 * (1 + _controller.value * 0.3),
        ),
        // 闪亮效果
        Positioned(
          top: -8 - (_controller.value * 12),
          right: -8,
          child: Transform.rotate(
            angle: _controller.value * math.pi,
            child: Opacity(
              opacity: 1.0 - _controller.value,
              child: Text(
                '✨',
                style: TextStyle(
                  fontSize: 18 * (1 + _controller.value * 0.5),
                ),
              ),
            ),
          ),
        ),
        // 清洁泡泡
        Positioned(
          top: -5 - (_controller.value * 8),
          left: -10,
          child: Opacity(
            opacity: 0.9 - _controller.value,
            child: Text(
              '🧼',
              style: TextStyle(
                fontSize: 14 * (1 + _controller.value * 0.3),
              ),
            ),
          ),
        ),
        // 额外的星星
        Positioned(
          bottom: -5 - (_controller.value * 10),
          left: -5,
          child: Opacity(
            opacity: 0.7 - _controller.value,
            child: Text(
              '🌟',
              style: TextStyle(
                fontSize: 12 * (1 + _controller.value * 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrainAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 主要星星图标
        Transform.rotate(
          angle: _controller.value * math.pi * 0.5,
          child: Icon(
            Icons.stars,
            color: Colors.amber.withOpacity(0.8),
            size: 30 * (1 + _controller.value * 0.5),
          ),
        ),
        // 魔法效果
        Transform.scale(
          scale: 1.0 + (_controller.value * 0.8),
          child: Icon(
            Icons.auto_awesome,
            color:
                Colors.yellow.withOpacity(0.9 - _controller.value * 0.3),
            size: 20 * (1 + _controller.value),
          ),
        ),
        // 成就星星
        Positioned(
          top: -10 - (_controller.value * 15),
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: Text(
              '🌟',
              style: TextStyle(
                fontSize: 20 * (1 + _controller.value * 0.4),
              ),
            ),
          ),
        ),
        // 学习帽子
        Positioned(
          top: -8 - (_controller.value * 10),
          right: -10,
          child: Opacity(
            opacity: 0.8 - _controller.value,
            child: Text(
              '🎓',
              style: TextStyle(
                fontSize: 16 * (1 + _controller.value * 0.3),
              ),
            ),
          ),
        ),
        // 奖杯
        Positioned(
          bottom: -5 - (_controller.value * 8),
          left: -8,
          child: Opacity(
            opacity: 0.7 - _controller.value,
            child: Text(
              '🏆',
              style: TextStyle(
                fontSize: 14 * (1 + _controller.value * 0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
