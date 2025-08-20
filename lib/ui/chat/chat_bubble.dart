import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final Widget child;
  final Widget? extras; // actions, suggestions etc.
  final String? timeText;

  const ChatBubble({super.key, required this.isUser, required this.child, this.extras, this.timeText});

  @override
  Widget build(BuildContext context) {
    final bg = isUser ? AppTheme.primaryColor : AppTheme.surfaceColor;
    final fg = isUser ? Theme.of(context).colorScheme.onPrimary : AppTheme.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium, vertical: AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg) ?? TextStyle(color: fg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            if (extras != null) ...[
              const SizedBox(height: 8),
              extras!,
            ],
            if (timeText != null) ...[
              const SizedBox(height: 4),
              Text(
                timeText!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isUser ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7) : AppTheme.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

