import 'package:flutter/material.dart';
import '../models/dialogue.dart';
import 'package:intl/intl.dart';

/// 聊天气泡组件
class ChatBubble extends StatelessWidget {
  final DialogueMessage message;
  
  /// 构造函数
  const ChatBubble({
    Key? key,
    required this.message,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final bool isUserMessage = message.sender == MessageSender.user;
    final timeFormat = DateFormat('HH:mm');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) _buildAvatar(context),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: isUserMessage 
                        ? Theme.of(context).primaryColor.withOpacity(0.8)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      if (message.emotionType != EmotionType.neutral && !isUserMessage)
                        _buildEmotionIndicator(context),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                  child: Text(
                    timeFormat.format(message.timestamp),
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
    );
  }
  
  /// 构建猫咪头像
  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.orange[200],
      child: const Icon(
        Icons.pets,
        color: Colors.white,
        size: 24,
      ),
    );
  }
  
  /// 构建用户头像
  Widget _buildUserAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 24,
      ),
    );
  }
  
  /// 构建情感指示器
  Widget _buildEmotionIndicator(BuildContext context) {
    IconData iconData;
    Color iconColor;
    
    switch (message.emotionType) {
      case EmotionType.happy:
        iconData = Icons.sentiment_very_satisfied;
        iconColor = Colors.yellow[700]!;
        break;
      case EmotionType.sad:
        iconData = Icons.sentiment_very_dissatisfied;
        iconColor = Colors.blue[300]!;
        break;
      case EmotionType.angry:
        iconData = Icons.sentiment_very_dissatisfied;
        iconColor = Colors.red[400]!;
        break;
      case EmotionType.anxious:
        iconData = Icons.sentiment_dissatisfied;
        iconColor = Colors.purple[300]!;
        break;
      case EmotionType.confused:
        iconData = Icons.sentiment_neutral;
        iconColor = Colors.orange[400]!;
        break;
      case EmotionType.surprised:
        iconData = Icons.sentiment_satisfied_alt;
        iconColor = Colors.teal[400]!;
        break;
      case EmotionType.loving:
        iconData = Icons.favorite;
        iconColor = Colors.pink[400]!;
        break;
      default:
        iconData = Icons.sentiment_neutral;
        iconColor = Colors.grey[600]!;
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            message.emotionType.toString().split('.').last,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
} 