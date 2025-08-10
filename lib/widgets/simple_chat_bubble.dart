import 'package:flutter/material.dart';
import '../theme/artistic_theme.dart';

/// 简单的聊天气泡组件，用于猫咪交互反馈
class SimpleChatBubble extends StatelessWidget {
  final String message;
  final String emoji;
  final bool isUser;

  const SimpleChatBubble({
    super.key,
    required this.message,
    required this.emoji,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ArtisticTheme.spacingMedium,
        vertical: ArtisticTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(
                colors: [
                  ArtisticTheme.primaryColor,
                  ArtisticTheme.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xFFFFFAF5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(ArtisticTheme.radiusLarge),
          topRight: const Radius.circular(ArtisticTheme.radiusLarge),
          bottomLeft: isUser
              ? const Radius.circular(ArtisticTheme.radiusLarge)
              : const Radius.circular(ArtisticTheme.radiusSmall),
          bottomRight: isUser
              ? const Radius.circular(ArtisticTheme.radiusSmall)
              : const Radius.circular(ArtisticTheme.radiusLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? ArtisticTheme.primaryColor.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(2, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 6,
            offset: const Offset(-1, -2),
          ),
        ],
        border: !isUser
            ? Border.all(
                color: ArtisticTheme.primaryColor.withValues(alpha: 0.2),
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: ArtisticTheme.spacingSmall),
          
          // 消息文本
          Flexible(
            child: Text(
              message,
              style: ArtisticTheme.bodyMedium.copyWith(
                color: isUser ? Colors.white : ArtisticTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
