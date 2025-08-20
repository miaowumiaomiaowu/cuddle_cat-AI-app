import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'dart:math' as math;

class SmartLoadingWidget extends StatefulWidget {
  final String? message;
  final LoadingType type;
  final Color? color;
  final double size;
  final Duration duration;
  final bool showProgress;
  final double? progress; // 0.0 to 1.0

  const SmartLoadingWidget({
    Key? key,
    this.message,
    this.type = LoadingType.adaptive,
    this.color,
    this.size = 50.0,
    this.duration = const Duration(milliseconds: 1500),
    this.showProgress = false,
    this.progress,
  }) : super(key: key);

  @override
  State<SmartLoadingWidget> createState() => _SmartLoadingWidgetState();
}

class _SmartLoadingWidgetState extends State<SmartLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _messageController;
  late Animation<double> _animation;
  late Animation<double> _messageAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _messageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _messageAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _messageController,
      curve: Curves.easeOut,
    ));

    _controller.repeat();
    if (widget.message != null) {
      _messageController.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: _buildLoadingIndicator(color),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _messageAnimation,
            child: Text(
              widget.message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingIndicator(Color color) {
    switch (widget.type) {
      case LoadingType.circular:
        return _buildCircularIndicator(color);
      case LoadingType.dots:
        return _buildDotsIndicator(color);
      case LoadingType.pulse:
        return _buildPulseIndicator(color);
      case LoadingType.wave:
        return _buildWaveIndicator(color);
      case LoadingType.cat:
        return _buildCatIndicator(color);
      case LoadingType.adaptive:
        return _buildAdaptiveIndicator(color);
    }
  }

  Widget _buildCircularIndicator(Color color) {
    if (widget.showProgress && widget.progress != null) {
      return CircularProgressIndicator(
        value: widget.progress,
        color: color,
        strokeWidth: 3.0,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: CircularLoadingPainter(
              color: color,
              progress: _animation.value,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDotsIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_animation.value + delay) % 1.0;
            final scale = math.sin(animationValue * math.pi) * 0.5 + 0.5;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: 0.5 + scale * 0.5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.5 + scale * 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPulseIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = math.sin(_animation.value * math.pi) * 0.3 + 0.7;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: WaveLoadingPainter(
            color: color,
            progress: _animation.value,
          ),
        );
      },
    );
  }

  Widget _buildCatIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final bounce = math.sin(_animation.value * 2 * math.pi) * 0.1 + 0.9;
        return Transform.scale(
          scale: bounce,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(widget.size * 0.3),
            ),
            child: Center(
              child: Text(
                '🐱',
                style: TextStyle(fontSize: widget.size * 0.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdaptiveIndicator(Color color) {
    // 根据平台和上下文选择最合适的加载指示器
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return _buildCircularIndicator(color);
    } else if (widget.message?.contains('猫') == true) {
      return _buildCatIndicator(color);
    } else {
      return _buildDotsIndicator(color);
    }
  }
}

class CircularLoadingPainter extends CustomPainter {
  final Color color;
  final double progress;

  CircularLoadingPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // 背景圆
    paint.color = color.withValues(alpha: 0.2);
    canvas.drawCircle(center, radius, paint);

    // 进度弧
    paint.color = color;
    const startAngle = -math.pi / 2;
    final sweepAngle = progress * 2 * math.pi * 0.8; // 80% 的圆

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WaveLoadingPainter extends CustomPainter {
  final Color color;
  final double progress;

  WaveLoadingPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.1;
    final waveLength = size.width;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height / 2 +
          math.sin((x / waveLength * 2 * math.pi) + (progress * 2 * math.pi)) * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum LoadingType {
  circular,
  dots,
  pulse,
  wave,
  cat,
  adaptive,
}

// 便捷的加载对话框
class SmartLoadingDialog {
  static void show(
    BuildContext context, {
    String? message,
    LoadingType type = LoadingType.adaptive,
    bool barrierDismissible = false,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'loading',
      transitionDuration: AppTheme.motionShort,
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: AppTheme.easeStandard);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SmartLoadingWidget(
            message: message,
            type: type,
          ),
        ),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
