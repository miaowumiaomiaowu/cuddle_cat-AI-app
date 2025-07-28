import 'package:flutter/material.dart';
import '../models/dialogue.dart';
import 'package:intl/intl.dart';

/// 聊天气泡组件
class ChatBubble extends StatefulWidget {
  final DialogueMessage message;
  final bool showTypingEffect;

  /// 构造函数
  const ChatBubble({
    super.key,
    required this.message,
    this.showTypingEffect = false,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _emojiAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _emojiPulseAnimation;
  String _displayedText = '';
  int _currentIndex = 0;
  bool _isTypingComplete = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _emojiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _emojiPulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
          parent: _emojiAnimationController, curve: Curves.easeInOut),
    );

    if (widget.showTypingEffect && widget.message.sender == MessageSender.cat) {
      _startTypingEffect();
    } else {
      _displayedText = widget.message.text;
      _isTypingComplete = true;
      _animationController.forward();
      _startEmojiAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emojiAnimationController.dispose();
    super.dispose();
  }

  void _startTypingEffect() {
    _displayedText = '';
    _currentIndex = 0;
    _isTypingComplete = false;
    _animationController.forward();

    const duration = Duration(milliseconds: 30); // 更快的打字速度
    Future.doWhile(() async {
      await Future.delayed(duration);
      if (_currentIndex < widget.message.text.length && mounted) {
        setState(() {
          _displayedText = widget.message.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
        return true;
      } else {
        if (mounted) {
          setState(() {
            _isTypingComplete = true;
          });
          _startEmojiAnimation();
        }
        return false;
      }
    });
  }

  void _startEmojiAnimation() {
    if (widget.message.sender == MessageSender.cat &&
        widget.message.emotionType != EmotionType.neutral) {
      _emojiAnimationController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUserMessage = widget.message.sender == MessageSender.user;
    final timeFormat = DateFormat('HH:mm');

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUserMessage) _buildCatAvatar(context),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: isUserMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        gradient: isUserMessage
                            ? LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
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
                          topLeft: const Radius.circular(24),
                          topRight: const Radius.circular(24),
                          bottomLeft: isUserMessage
                              ? const Radius.circular(24)
                              : const Radius.circular(8),
                          bottomRight: isUserMessage
                              ? const Radius.circular(8)
                              : const Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isUserMessage
                                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
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
                        border: !isUserMessage
                            ? Border.all(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUserMessage) _buildCatEmojiHeader(),
                          widget.showTypingEffect && !_isTypingComplete
                              ? _buildTypingText(isUserMessage)
                              : _buildNormalText(isUserMessage),
                          if (!isUserMessage &&
                              widget.message.emotionType !=
                                  EmotionType.neutral &&
                              _isTypingComplete)
                            _buildEnhancedEmotionIndicator(context),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 4.0, left: 4.0, right: 4.0),
                      child: Text(
                        timeFormat.format(widget.message.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isUserMessage) _buildUserAvatar(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建猫咪头像
  Widget _buildCatAvatar(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.orange.shade300, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.pets,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  /// 构建用户头像
  Widget _buildUserAvatar(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  /// 构建猫咪emoji头部
  Widget _buildCatEmojiHeader() {
    final emoji = _getEmotionEmoji(widget.message.emotionType);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _emojiPulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _emojiPulseAnimation.value,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: _getEmotionColor(widget.message.emotionType)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getEmotionText(widget.message.emotionType),
              style: TextStyle(
                fontSize: 11,
                color: _getEmotionColor(widget.message.emotionType),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建打字机效果文本
  Widget _buildTypingText(bool isUserMessage) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: _displayedText,
            style: TextStyle(
              color: isUserMessage ? Colors.white : Colors.black87,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          if (_currentIndex < widget.message.text.length)
            WidgetSpan(
              child: AnimatedOpacity(
                opacity: DateTime.now().millisecond % 1000 < 500 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: 2,
                  height: 20,
                  color: isUserMessage ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建普通文本
  Widget _buildNormalText(bool isUserMessage) {
    return Text(
      widget.message.text,
      style: TextStyle(
        color: isUserMessage ? Colors.white : Colors.black87,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }

  /// 构建增强的情感指示器
  Widget _buildEnhancedEmotionIndicator(BuildContext context) {
    final emoji = _getEmotionEmoji(widget.message.emotionType);
    final color = _getEmotionColor(widget.message.emotionType);
    final emotionScore = widget.message.emotionScore;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _emojiAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 +
                      (emotionScore * 0.3 * _emojiPulseAnimation.value - 1.0),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getEmotionText(widget.message.emotionType),
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (emotionScore != 0.5)
                  Container(
                    width: 30,
                    height: 2,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      color: Colors.grey.shade300,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: emotionScore,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          color: color,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 根据情感类型获取emoji
  String _getEmotionEmoji(EmotionType emotionType) {
    switch (emotionType) {
      case EmotionType.happy:
        return '😸';
      case EmotionType.sad:
        return '😿';
      case EmotionType.angry:
        return '😾';
      case EmotionType.anxious:
        return '😰';
      case EmotionType.confused:
        return '🤔';
      case EmotionType.surprised:
        return '😲';
      case EmotionType.loving:
        return '😻';
      case EmotionType.neutral:
        return '😺';
    }
  }

  /// 根据情感类型获取文本描述
  String _getEmotionText(EmotionType emotionType) {
    switch (emotionType) {
      case EmotionType.happy:
        return '开心';
      case EmotionType.sad:
        return '难过';
      case EmotionType.angry:
        return '生气';
      case EmotionType.anxious:
        return '焦虑';
      case EmotionType.confused:
        return '困惑';
      case EmotionType.surprised:
        return '惊讶';
      case EmotionType.loving:
        return '关爱';
      case EmotionType.neutral:
        return '平静';
    }
  }

  /// 根据情感类型获取颜色
  Color _getEmotionColor(EmotionType emotionType) {
    switch (emotionType) {
      case EmotionType.happy:
        return Colors.yellow.shade700;
      case EmotionType.sad:
        return Colors.blue.shade300;
      case EmotionType.angry:
        return Colors.red.shade400;
      case EmotionType.anxious:
        return Colors.orange.shade400;
      case EmotionType.confused:
        return Colors.purple.shade300;
      case EmotionType.surprised:
        return Colors.pink.shade300;
      case EmotionType.loving:
        return Colors.pink.shade400;
      case EmotionType.neutral:
        return Colors.grey.shade600;
    }
  }
}
