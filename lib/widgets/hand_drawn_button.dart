import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 手绘风格按钮组件
class HandDrawnButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final String? emoji;
  final bool isLoading;
  final HandDrawnButtonStyle style;

  const HandDrawnButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.emoji,
    this.isLoading = false,
    this.style = HandDrawnButtonStyle.primary,
  });

  @override
  State<HandDrawnButton> createState() => _HandDrawnButtonState();
}

class _HandDrawnButtonState extends State<HandDrawnButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final colors = _getStyleColors();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: isEnabled ? _onTapDown : null,
            onTapUp: isEnabled ? _onTapUp : null,
            onTapCancel: isEnabled ? _onTapCancel : null,
            onTap: isEnabled ? widget.onPressed : null,
            child: Container(
              width: widget.width,
              height: widget.height ?? 50,
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? LinearGradient(
                        colors: [
                          colors.backgroundColor,
                          colors.backgroundColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.shade300,
                          Colors.grey.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: isEnabled
                      ? colors.borderColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
                boxShadow: isEnabled && !_isPressed
                    ? [
                        BoxShadow(
                          color: colors.backgroundColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 4,
                          offset: const Offset(-1, -2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(1, 2),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  onTap: isEnabled ? widget.onPressed : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                      vertical: AppTheme.spacingSmall,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors.textColor,
                              ),
                            ),
                          )
                        else ...[
                          if (widget.emoji != null) ...[
                            Text(
                              widget.emoji!,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: isEnabled
                                  ? colors.textColor
                                  : Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _ButtonColors _getStyleColors() {
    switch (widget.style) {
      case HandDrawnButtonStyle.primary:
        return _ButtonColors(
          backgroundColor: widget.backgroundColor ?? AppTheme.primaryColor,
          textColor: widget.textColor ?? Colors.white,
          borderColor: AppTheme.primaryColor.withValues(alpha: 0.6),
        );
      case HandDrawnButtonStyle.secondary:
        return _ButtonColors(
          backgroundColor: widget.backgroundColor ?? AppTheme.accentColor,
          textColor: widget.textColor ?? Colors.white,
          borderColor: AppTheme.accentColor.withValues(alpha: 0.6),
        );
      case HandDrawnButtonStyle.outline:
        return _ButtonColors(
          backgroundColor: widget.backgroundColor ?? Colors.transparent,
          textColor: widget.textColor ?? AppTheme.primaryColor,
          borderColor: AppTheme.primaryColor,
        );
      case HandDrawnButtonStyle.success:
        return _ButtonColors(
          backgroundColor: widget.backgroundColor ?? AppTheme.successColor,
          textColor: widget.textColor ?? Colors.white,
          borderColor: AppTheme.successColor.withValues(alpha: 0.6),
        );
      case HandDrawnButtonStyle.warning:
        return _ButtonColors(
          backgroundColor: widget.backgroundColor ?? AppTheme.warningColor,
          textColor: widget.textColor ?? Colors.white,
          borderColor: AppTheme.warningColor.withValues(alpha: 0.6),
        );
      case HandDrawnButtonStyle.error:
        return _ButtonColors(
          backgroundColor: widget.backgroundColor ?? AppTheme.errorColor,
          textColor: widget.textColor ?? Colors.white,
          borderColor: AppTheme.errorColor.withValues(alpha: 0.6),
        );
    }
  }
}

enum HandDrawnButtonStyle {
  primary,
  secondary,
  outline,
  success,
  warning,
  error,
}

class _ButtonColors {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  _ButtonColors({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}
