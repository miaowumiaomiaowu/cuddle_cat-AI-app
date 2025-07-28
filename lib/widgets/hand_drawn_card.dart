import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 手绘风格卡片组件
class HandDrawnCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final String? title;
  final String? titleEmoji;
  final HandDrawnCardStyle style;

  const HandDrawnCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.boxShadow,
    this.onTap,
    this.title,
    this.titleEmoji,
    this.style = HandDrawnCardStyle.normal,
  });

  @override
  Widget build(BuildContext context) {
    final cardStyle = _getCardStyle();
    
    Widget cardContent = Container(
      margin: margin ?? const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        gradient: cardStyle.gradient,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.radiusLarge,
        ),
        border: Border.all(
          color: borderColor ?? cardStyle.borderColor,
          width: borderWidth ?? 1.5,
        ),
        boxShadow: boxShadow ?? cardStyle.boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppTheme.radiusLarge,
          ),
          onTap: onTap,
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Row(
                    children: [
                      if (titleEmoji != null) ...[
                        Text(
                          titleEmoji!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                      ],
                      Expanded(
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );

    return cardContent;
  }

  _CardStyle _getCardStyle() {
    switch (style) {
      case HandDrawnCardStyle.normal:
        return _CardStyle(
          gradient: LinearGradient(
            colors: [
              backgroundColor ?? AppTheme.cardColor,
              (backgroundColor ?? AppTheme.cardColor).withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: AppTheme.textSecondary.withValues(alpha: 0.2),
          boxShadow: AppTheme.cardShadow,
        );
      case HandDrawnCardStyle.elevated:
        return _CardStyle(
          gradient: LinearGradient(
            colors: [
              backgroundColor ?? AppTheme.surfaceColor,
              (backgroundColor ?? AppTheme.surfaceColor).withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          boxShadow: AppTheme.elevatedShadow,
        );
      case HandDrawnCardStyle.primary:
        return _CardStyle(
          gradient: LinearGradient(
            colors: [
              backgroundColor ?? AppTheme.primaryColor.withValues(alpha: 0.1),
              (backgroundColor ?? AppTheme.primaryColor.withValues(alpha: 0.05)),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: AppTheme.primaryColor.withValues(alpha: 0.4),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(3, 5),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 6,
              offset: const Offset(-2, -2),
            ),
          ],
        );
      case HandDrawnCardStyle.success:
        return _CardStyle(
          gradient: LinearGradient(
            colors: [
              backgroundColor ?? AppTheme.successColor.withValues(alpha: 0.1),
              (backgroundColor ?? AppTheme.successColor.withValues(alpha: 0.05)),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: AppTheme.successColor.withValues(alpha: 0.4),
          boxShadow: [
            BoxShadow(
              color: AppTheme.successColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(3, 5),
              spreadRadius: 1,
            ),
          ],
        );
      case HandDrawnCardStyle.warning:
        return _CardStyle(
          gradient: LinearGradient(
            colors: [
              backgroundColor ?? AppTheme.warningColor.withValues(alpha: 0.1),
              (backgroundColor ?? AppTheme.warningColor.withValues(alpha: 0.05)),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: AppTheme.warningColor.withValues(alpha: 0.4),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warningColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(3, 5),
              spreadRadius: 1,
            ),
          ],
        );
      case HandDrawnCardStyle.error:
        return _CardStyle(
          gradient: LinearGradient(
            colors: [
              backgroundColor ?? AppTheme.errorColor.withValues(alpha: 0.1),
              (backgroundColor ?? AppTheme.errorColor.withValues(alpha: 0.05)),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: AppTheme.errorColor.withValues(alpha: 0.4),
          boxShadow: [
            BoxShadow(
              color: AppTheme.errorColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(3, 5),
              spreadRadius: 1,
            ),
          ],
        );
    }
  }
}

enum HandDrawnCardStyle {
  normal,
  elevated,
  primary,
  success,
  warning,
  error,
}

class _CardStyle {
  final Gradient gradient;
  final Color borderColor;
  final List<BoxShadow> boxShadow;

  _CardStyle({
    required this.gradient,
    required this.borderColor,
    required this.boxShadow,
  });
}
