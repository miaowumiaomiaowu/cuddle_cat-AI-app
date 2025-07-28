import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/artistic_theme.dart';

/// 艺术感图表组件 - 参考现代数据可视化设计
class ArtisticChart extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final String label;
  final IconData icon;
  final Color color;
  final double size;
  final bool showAnimation;

  const ArtisticChart({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.size = 120,
    this.showAnimation = true,
  });

  @override
  State<ArtisticChart> createState() => _ArtisticChartState();
}

class _ArtisticChartState extends State<ArtisticChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.showAnimation) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ArtisticChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景圆环
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _BackgroundRingPainter(),
          ),
          // 进度圆环
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressRingPainter(
                  progress: _animation.value,
                  color: widget.color,
                ),
              );
            },
          ),
          // 中心内容
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: widget.size * 0.25,
                color: widget.color,
              ),
              const SizedBox(height: 4),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Text(
                    '${(_animation.value * 100).round()}%',
                    style: ArtisticTheme.titleMedium.copyWith(
                      color: widget.color,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
              Text(
                widget.label,
                style: ArtisticTheme.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          // 装饰性光点
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GlowDotPainter(
                  progress: _animation.value,
                  color: widget.color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 背景圆环画笔
class _BackgroundRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final strokeWidth = size.width * 0.08;

    final paint = Paint()
      ..color = ArtisticTheme.textHint.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 进度圆环画笔
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final strokeWidth = size.width * 0.08;

    // 渐变画笔
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + math.max(0.01, 2 * math.pi * progress), // 确保角度大于0
      colors: [
        color.withOpacity(0.3),
        color,
        color.withOpacity(0.8),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// 发光点画笔
class _GlowDotPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GlowDotPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final angle = -math.pi / 2 + 2 * math.pi * progress;

    final dotCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    // 外层光晕
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(dotCenter, 12, glowPaint);

    // 内层亮点
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(dotCenter, 6, dotPaint);

    // 中心高光
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(dotCenter, 2, highlightPaint);
  }

  @override
  bool shouldRepaint(_GlowDotPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// 艺术感状态卡片
class ArtisticStatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const ArtisticStatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
        decoration: ArtisticTheme.artisticCard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(ArtisticTheme.spacingSmall),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ArtisticTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingSmall),
            Text(
              value,
              style: ArtisticTheme.headlineMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: ArtisticTheme.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
