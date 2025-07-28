import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 手绘风格加载指示器
class HandDrawnLoading extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;
  final HandDrawnLoadingStyle style;

  const HandDrawnLoading({
    super.key,
    this.size = 50.0,
    this.color,
    this.message,
    this.style = HandDrawnLoadingStyle.spinner,
  });

  @override
  State<HandDrawnLoading> createState() => _HandDrawnLoadingState();
}

class _HandDrawnLoadingState extends State<HandDrawnLoading>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late Animation<double> _spinAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _spinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _spinController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLoadingIndicator(),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    switch (widget.style) {
      case HandDrawnLoadingStyle.spinner:
        return _buildSpinner();
      case HandDrawnLoadingStyle.dots:
        return _buildDots();
      case HandDrawnLoadingStyle.emoji:
        return _buildEmojiLoader();
      case HandDrawnLoadingStyle.cat:
        return _buildCatLoader();
    }
  }

  Widget _buildSpinner() {
    return AnimatedBuilder(
      animation: _spinAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _spinAnimation.value * 2 * 3.14159,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  widget.color ?? AppTheme.primaryColor,
                  (widget.color ?? AppTheme.primaryColor).withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.backgroundColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_pulseController.value + delay) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2));
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        widget.color ?? AppTheme.primaryColor,
                        (widget.color ?? AppTheme.primaryColor).withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.color ?? AppTheme.primaryColor).withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildEmojiLoader() {
    const emojis = ['🌟', '✨', '💫', '⭐'];
    
    return AnimatedBuilder(
      animation: _spinAnimation,
      builder: (context, child) {
        final currentIndex = (_spinAnimation.value * emojis.length).floor() % emojis.length;
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Text(
                emojis[currentIndex],
                style: TextStyle(fontSize: widget.size * 0.6),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCatLoader() {
    const catEmojis = ['🐱', '😸', '😺', '😻'];
    
    return AnimatedBuilder(
      animation: _spinAnimation,
      builder: (context, child) {
        final currentIndex = (_spinAnimation.value * catEmojis.length).floor() % catEmojis.length;
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Text(
                catEmojis[currentIndex],
                style: TextStyle(fontSize: widget.size * 0.8),
              ),
            );
          },
        );
      },
    );
  }
}

enum HandDrawnLoadingStyle {
  spinner,
  dots,
  emoji,
  cat,
}

/// 手绘风格全屏加载覆盖层
class HandDrawnLoadingOverlay extends StatelessWidget {
  final String? message;
  final HandDrawnLoadingStyle style;
  final bool isVisible;

  const HandDrawnLoadingOverlay({
    super.key,
    this.message,
    this.style = HandDrawnLoadingStyle.cat,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingXLarge),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.surfaceColor,
                AppTheme.backgroundColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: AppTheme.elevatedShadow,
          ),
          child: HandDrawnLoading(
            size: 60,
            message: message ?? '加载中...',
            style: style,
          ),
        ),
      ),
    );
  }
}
