import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/cat.dart';
import 'svg_cat_image.dart';
import 'cat_interaction_animation.dart';

class CatAnimation extends StatefulWidget {
  final Cat cat;
  final double size;
  final bool showMood;
  final String? action;
  final VoidCallback? onTap;

  const CatAnimation({
    super.key,
    required this.cat,
    this.size = 200,
    this.showMood = true,
    this.action,
    this.onTap,
  });

  @override
  State<CatAnimation> createState() => _CatAnimationState();
}

class _CatAnimationState extends State<CatAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = false;
  CatMoodState? _temporaryMood;
  bool _showInteractionAnimation = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playAnimation() {
    if (!_isPlaying) {
      setState(() {
        _isPlaying = true;
        if (widget.cat.mood != CatMoodState.happy) {
          _temporaryMood = CatMoodState.happy;
        }
        _showInteractionAnimation = true;
      });

      _controller.forward().then((_) {
        _controller.reverse().then((_) {
          setState(() {
            _isPlaying = false;
            _temporaryMood = null;
          });
        });
      });
    }
  }

  void _onInteractionAnimationComplete() {
    setState(() {
      _showInteractionAnimation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _playAnimation();
        widget.onTap?.call();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 猫咪背景光环
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.cat.breedColor.withOpacity(0.1),
            ),
          ),
          
          // 猫咪 SVG
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_controller.value * 0.1),
                child: child,
              );
            },
            child: SvgCatImage(
              cat: widget.cat,
              size: widget.size * 0.8,
              action: widget.action,
              overrideMood: _temporaryMood,
            ),
          ),
          
          // 心情表情（如果启用）
          if (widget.showMood && (widget.cat.mood == CatMoodState.happy || _temporaryMood == CatMoodState.happy))
            ...List.generate(
              5,
              (index) => Positioned(
                left: widget.size * 0.5 + (index - 2) * 15,
                top: widget.size * 0.3 + (index % 3) * 10,
                child: Icon(
                  Icons.favorite,
                  color: Colors.pink.withOpacity(0.7),
                  size: 16,
                ),
              ),
            ),
            
          // 互动动画
          if (_showInteractionAnimation)
            Positioned(
              top: widget.size * 0.2,
              child: CatInteractionAnimation(
                type: InteractionAnimationType.pet,
                size: 50,
                onComplete: _onInteractionAnimationComplete,
              ),
            ),
        ],
      ),
    );
  }
} 