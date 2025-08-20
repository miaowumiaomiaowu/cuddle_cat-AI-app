import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A simple reusable gradient button consistent with AppTheme gradients.
class GradientButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Gradient gradient;
  final bool expand;

  const GradientButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: AppTheme.gap24, vertical: AppTheme.gap12),
    this.borderRadius = AppTheme.radiusLarge,
    this.gradient = AppTheme.mistSkyGradient,
    this.expand = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final btn = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
        child: Center(child: widget.child),
      ),
    );

    final scaled = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: AppTheme.motionShort,
      curve: AppTheme.easeStandard,
      child: btn,
    );

    if (widget.onPressed == null) return scaled;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onTap: widget.onPressed,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: scaled,
      ),
    );
  }
}

