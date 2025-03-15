import 'package:flutter/material.dart';

/// 对话输入组件
class DialogueInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isLoading;
  
  /// 构造函数
  const DialogueInput({
    Key? key,
    required this.onSendMessage,
    this.isLoading = false,
  }) : super(key: key);
  
  @override
  State<DialogueInput> createState() => _DialogueInputState();
}

class _DialogueInputState extends State<DialogueInput> {
  final TextEditingController _textController = TextEditingController();
  bool _hasText = false;
  
  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateHasText);
  }
  
  @override
  void dispose() {
    _textController.removeListener(_updateHasText);
    _textController.dispose();
    super.dispose();
  }
  
  /// 更新文本状态
  void _updateHasText() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }
  
  /// 发送消息
  void _handleSend() {
    if (!_hasText || widget.isLoading) return;
    
    final message = _textController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _textController.clear();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                enabled: !widget.isLoading,
                decoration: InputDecoration(
                  hintText: '与猫咪聊天...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          _buildSendButton(),
        ],
      ),
    );
  }
  
  /// 构建发送按钮
  Widget _buildSendButton() {
    return ClipOval(
      child: Material(
        color: _hasText && !widget.isLoading
            ? Theme.of(context).primaryColor
            : Colors.grey[400],
        child: InkWell(
          onTap: _handleSend,
          child: Container(
            padding: const EdgeInsets.all(10.0),
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }
} 