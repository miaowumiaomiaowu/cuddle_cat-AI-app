import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled; // true: primary filled; false: outlined
  final bool useGradient;
  final EdgeInsetsGeometry padding;
  final bool loading;

  const AppButton.primary(
    this.label, {
    super.key,
    this.onPressed,
    this.useGradient = false,
    this.padding = const EdgeInsets.symmetric(vertical: AppTheme.gap12, horizontal: AppTheme.gap24),
    this.loading = false,
  }) : filled = true;

  const AppButton.outlined(
    this.label, {
    super.key,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: AppTheme.gap12, horizontal: AppTheme.gap24),
    this.loading = false,
  })  : filled = false,
        useGradient = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusMedium);

    final text = Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: filled ? Theme.of(context).colorScheme.onPrimary : AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ) ??
          TextStyle(color: filled ? Theme.of(context).colorScheme.onPrimary : AppTheme.primaryColor),
    );

    final loader = SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: filled ? Theme.of(context).colorScheme.onPrimary : AppTheme.primaryColor,
      ),
    );

    final content = AnimatedScale(
      duration: AppTheme.motionShort,
      curve: AppTheme.easeStandard,
      scale: 1.0,
      child: Container(
        padding: padding,
        decoration: filled
            ? BoxDecoration(
                color: useGradient ? null : AppTheme.primaryColor,
                gradient: useGradient ? AppTheme.fieldGreenGradient : null,
                borderRadius: radius,
                boxShadow: AppTheme.cardShadow,
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: radius,
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5), width: 1.5),
              ),
        child: Center(child: loading ? loader : text),
      ),
    );

    if (onPressed == null || loading) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return AppTheme.primaryColor.withValues(alpha: AppTheme.opacityPressed);
          if (states.contains(WidgetState.hovered)) return AppTheme.primaryColor.withValues(alpha: AppTheme.opacityHover);
          if (states.contains(WidgetState.focused)) return AppTheme.primaryColor.withValues(alpha: AppTheme.opacityFocus);
          return null;
        }),
        child: content,
      ),
    );
  }
}

