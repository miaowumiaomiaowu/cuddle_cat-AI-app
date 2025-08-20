import 'package:flutter/material.dart';
// ignore_for_file: prefer_const_constructors

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppTheme.gap16), this.margin, this.onTap, this.gradient});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? AppTheme.cardColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.12), width: 1),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: content,
      ),
    );
  }
}

