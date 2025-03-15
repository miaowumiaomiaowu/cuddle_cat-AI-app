import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 互动动画类型
enum InteractionAnimationType {
  pet,      // 抚摸
  feed,     // 喂食
  play,     // 玩耍
  groom,    // 洗澡/梳理
  train,    // 训练
}

/// 猫咪互动动画组件
class CatInteractionAnimation extends StatefulWidget {
  final InteractionAnimationType type;
  final double size;
  final VoidCallback? onComplete;

  const CatInteractionAnimation({
    Key? key,
    required this.type,
    this.size = 100,
    this.onComplete,
  }) : super(key: key);

  @override
  State<CatInteractionAnimation> createState() => _CatInteractionAnimationState();
}

class _CatInteractionAnimationState extends State<CatInteractionAnimation> with SingleTickerProviderStateMixin {
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
    return const Icon(
      Icons.favorite,
      color: Colors.pink,
      size: 30,
    );
  }
  
  Widget _buildFeedAnimation() {
    return const Icon(
      Icons.restaurant,
      color: Colors.orange,
      size: 30,
    );
  }
  
  Widget _buildPlayAnimation() {
    return Transform.rotate(
      angle: _controller.value * math.pi * 2,
      child: const Icon(
        Icons.toys,
        color: Colors.purple,
        size: 30,
      ),
    );
  }
  
  Widget _buildGroomAnimation() {
    return const Icon(
      Icons.shower,
      color: Colors.blue,
      size: 30,
    );
  }
  
  Widget _buildTrainAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.stars,
          color: Colors.amber,
          size: 30 * (1 + _controller.value * 0.5),
        ),
        Icon(
          Icons.auto_awesome,
          color: Colors.yellow,
          size: 20 * (1 + _controller.value),
        ),
      ],
    );
  }
} 