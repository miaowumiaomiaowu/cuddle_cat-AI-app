import 'package:flutter/material.dart';
import '../theme/artistic_theme.dart';
import '../screens/immersive_chat_home_screen.dart';

/// 沉浸式聊天组件
class ImmersiveChatWidget extends StatefulWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final bool isTyping;

  const ImmersiveChatWidget({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isTyping,
  });

  @override
  State<ImmersiveChatWidget> createState() => _ImmersiveChatWidgetState();
}

class _ImmersiveChatWidgetState extends State<ImmersiveChatWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));
    
    _typingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: widget.messages.length + (widget.isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.messages.length && widget.isTyping) {
            return _buildTypingIndicator();
          }
          
          final message = widget.messages[index];
          return _buildMessageBubble(message, index);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.isUser;
    final isWelcome = message.messageType == ChatMessageType.welcome;
    final isPsychology = message.messageType == ChatMessageType.psychology;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatar(message.avatar, isWelcome || isPsychology),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxBubbleWidth = constraints.maxWidth * 0.78; // 留出头像/间距
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getBubbleColor(message),
                      borderRadius: _getBubbleBorderRadius(isUser),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isWelcome || isPsychology)
                          _buildMessageTypeIndicator(message.messageType),

                        Text(
                          message.text,
                          style: ArtisticTheme.bodyStyle.copyWith(
                            color: isUser
                                ? Colors.white
                                : ArtisticTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _formatTime(message.timestamp),
                          style: ArtisticTheme.bodyStyle.copyWith(
                            fontSize: 10,
                            color: isUser
                                ? Colors.white70
                                : ArtisticTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(message.avatar, false),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String emoji, bool isSpecial) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isSpecial 
            ? ArtisticTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: isSpecial 
            ? Border.all(
                color: ArtisticTheme.primaryColor.withValues(alpha: 0.3),
                width: 2,
              )
            : null,
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildMessageTypeIndicator(ChatMessageType type) {
    String label;
    Color color;
    IconData icon;
    
    switch (type) {
      case ChatMessageType.welcome:
        label = '欢迎消息';
        color = Colors.green;
        icon = Icons.waving_hand;
        break;
      case ChatMessageType.psychology:
        label = '心理支持';
        color = Colors.purple;
        icon = Icons.psychology;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: ArtisticTheme.bodyStyle.copyWith(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _buildAvatar('🤖', true),
          const SizedBox(width: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '正在输入',
                  style: ArtisticTheme.bodyStyle.copyWith(
                    color: ArtisticTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                
                AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final delay = index * 0.3;
                        final animationValue = (_typingAnimation.value + delay) % 1.0;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          child: Transform.translate(
                            offset: Offset(0, -4 * (1 - (animationValue * 2 - 1).abs())),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: ArtisticTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBubbleColor(ChatMessage message) {
    if (message.isUser) {
      return ArtisticTheme.primaryColor;
    }
    
    switch (message.messageType) {
      case ChatMessageType.welcome:
        return Colors.green.withValues(alpha: 0.1);
      case ChatMessageType.psychology:
        return Colors.purple.withValues(alpha: 0.1);
      case ChatMessageType.system:
        return Colors.orange.withValues(alpha: 0.1);
      default:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }

  BorderRadius _getBubbleBorderRadius(bool isUser) {
    if (isUser) {
      return const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(4),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(20),
      );
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
