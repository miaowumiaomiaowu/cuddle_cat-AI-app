import 'package:flutter/material.dart';
import '../theme/artistic_theme.dart';

/// 艺术感按钮组件 - 参考现代交互设计
class ArtisticButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final ArtisticButtonStyle style;
  final double? width;
  final double? height;
  final bool isLoading;
  final double borderRadius;

  const ArtisticButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.color,
    this.style = ArtisticButtonStyle.primary,
    this.width,
    this.height,
    this.isLoading = false,
    this.borderRadius = 12.0,
  });

  @override
  State<ArtisticButton> createState() => _ArtisticButtonState();
}

class _ArtisticButtonState extends State<ArtisticButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final buttonColor = widget.color ?? ArtisticTheme.primaryColor;

    return GestureDetector(
      onTapDown: isEnabled ? _onTapDown : null,
      onTapUp: isEnabled ? _onTapUp : null,
      onTapCancel: isEnabled ? _onTapCancel : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? 48,
              decoration: _getButtonDecoration(buttonColor, isEnabled),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                  onTap: isEnabled ? widget.onPressed : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ArtisticTheme.spacingLarge,
                      vertical: ArtisticTheme.spacingMedium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isLoading) ...[
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getTextColor(isEnabled),
                              ),
                            ),
                          ),
                          const SizedBox(width: ArtisticTheme.spacingSmall),
                        ] else if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: 18,
                            color: _getTextColor(isEnabled),
                          ),
                          const SizedBox(width: ArtisticTheme.spacingSmall),
                        ],
                        Text(
                          widget.text,
                          style: ArtisticTheme.labelLarge.copyWith(
                            color: _getTextColor(isEnabled),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _getButtonDecoration(Color color, bool isEnabled) {
    switch (widget.style) {
      case ArtisticButtonStyle.primary:
        return BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.9),
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isEnabled ? null : ArtisticTheme.textHint.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3 + _glowAnimation.value * 0.2),
                    blurRadius: 12 + _glowAnimation.value * 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ]
              : null,
        );

      case ArtisticButtonStyle.secondary:
        return BoxDecoration(
          color: isEnabled ? color.withValues(alpha: 0.1) : ArtisticTheme.textHint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
          border: Border.all(
            color: isEnabled ? color.withValues(alpha: 0.3) : ArtisticTheme.textHint.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1 + _glowAnimation.value * 0.1),
                    blurRadius: 8 + _glowAnimation.value * 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        );

      case ArtisticButtonStyle.ghost:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
          border: Border.all(
            color: isEnabled ? color.withValues(alpha: 0.5) : ArtisticTheme.textHint.withValues(alpha: 0.3),
            width: 1,
          ),
        );

      case ArtisticButtonStyle.glass:
        return BoxDecoration(
          color: isEnabled
              ? ArtisticTheme.surfaceColor.withValues(alpha: 0.8)
              : ArtisticTheme.textHint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
          border: Border.all(
            color: isEnabled ? color.withValues(alpha: 0.2) : ArtisticTheme.textHint.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(-2, -2),
                  ),
                  BoxShadow(
                    color: ArtisticTheme.textPrimary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(2, 2),
                  ),
                ]
              : null,
        );
      case ArtisticButtonStyle.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: isEnabled ? (widget.color ?? ArtisticTheme.primaryColor) : ArtisticTheme.textHint,
            width: 2,
          ),
        );
    }
  }

  Color _getTextColor(bool isEnabled) {
    if (!isEnabled) return ArtisticTheme.textHint;

    switch (widget.style) {
      case ArtisticButtonStyle.primary:
        return Colors.white;
      case ArtisticButtonStyle.secondary:
      case ArtisticButtonStyle.ghost:
      case ArtisticButtonStyle.glass:
      case ArtisticButtonStyle.outline:
        return widget.color ?? ArtisticTheme.primaryColor;
    }
  }
}

enum ArtisticButtonStyle {
  primary,
  secondary,
  ghost,
  glass,
  outline,
}

/// 艺术感浮动按钮
class ArtisticFloatingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const ArtisticFloatingButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 56,
  });

  @override
  State<ArtisticFloatingButton> createState() => _ArtisticFloatingButtonState();
}

class _ArtisticFloatingButtonState extends State<ArtisticFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? ArtisticTheme.primaryColor;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  gradient: ArtisticTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(widget.size / 2),
                  boxShadow: [
                    BoxShadow(
                      color: buttonColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.size * 0.4,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
