import 'package:flutter/material.dart';
import '../models/dialogue.dart';
import 'chat_bubble.dart';

/// 对话历史组件
class DialogueHistory extends StatefulWidget {
  final DialogueSession? session;
  final ScrollController? scrollController;
  final bool showTypingEffect;

  /// 构造函数
  const DialogueHistory({
    super.key,
    this.session,
    this.scrollController,
    this.showTypingEffect = false,
  });

  @override
  State<DialogueHistory> createState() => _DialogueHistoryState();
}

class _DialogueHistoryState extends State<DialogueHistory> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(DialogueHistory oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.session?.messages.length != widget.session?.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  /// 滚动到底部
  void _scrollToBottom() {
    if (_scrollController.hasClients &&
        widget.session != null &&
        widget.session!.messages.isNotEmpty) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session == null || widget.session!.messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      itemCount: widget.session!.messages.length,
      itemBuilder: (context, index) {
        final message = widget.session!.messages[index];
        final isLastMessage = index == widget.session!.messages.length - 1;
        final shouldShowTyping = widget.showTypingEffect &&
            isLastMessage &&
            message.sender == MessageSender.cat;

        return ChatBubble(
          message: message,
          showTypingEffect: shouldShowTyping,
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '开始与你的猫咪聊天吧',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '分享你的心情，获得治愈',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
