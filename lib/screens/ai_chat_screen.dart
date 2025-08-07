import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/artistic_theme.dart';
import '../services/ai_psychology_service.dart';
import '../providers/mood_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/hand_drawn_card.dart';
import '../models/mood_record.dart';

/// AI心理支持聊天页面
class AIChatScreen extends StatefulWidget {
  static const String routeName = '/ai_chat';

  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIPsychologyService _aiService = AIPsychologyService();
  
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _fadeController.forward();
    
    // 添加欢迎消息
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userName = userProvider.displayName;
    
    setState(() {
      _messages.add(ChatMessage(
        text: '你好，$userName！我是你的AI心理支持助手小暖。我在这里倾听你的感受，提供情绪支持和建议。你今天感觉怎么样？',
        isUser: false,
        timestamp: DateTime.now(),
        avatar: '🤖',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisticTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ArtisticTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI小暖',
                  style: ArtisticTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '心理支持助手',
                  style: ArtisticTheme.caption.copyWith(
                    color: ArtisticTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: _showInsightDialog,
            tooltip: '心理洞察',
          ),
          IconButton(
            icon: const Icon(Icons.self_improvement),
            onPressed: _showMeditationDialog,
            tooltip: '冥想指导',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: _buildMessageList(),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ArtisticTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(message.avatar, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: ArtisticTheme.spacingMedium,
                vertical: ArtisticTheme.spacingSmall,
              ),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? ArtisticTheme.primaryColor 
                    : ArtisticTheme.surfaceColor,
                borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                boxShadow: ArtisticTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: ArtisticTheme.bodyMedium.copyWith(
                      color: message.isUser 
                          ? Colors.white 
                          : ArtisticTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: ArtisticTheme.caption.copyWith(
                      color: message.isUser 
                          ? Colors.white70 
                          : ArtisticTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ArtisticTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(message.avatar, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ArtisticTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ArtisticTheme.surfaceColor,
              borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
              boxShadow: ArtisticTheme.softShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = ((value + delay) % 1.0);
        final opacity = (animValue < 0.5) ? animValue * 2 : (1 - animValue) * 2;
        
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: ArtisticTheme.primaryColor.withOpacity(opacity),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
      decoration: BoxDecoration(
        color: ArtisticTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '输入你的感受或问题...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ArtisticTheme.radiusLarge),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: ArtisticTheme.backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ArtisticTheme.spacingMedium,
                    vertical: ArtisticTheme.spacingSmall,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: ArtisticTheme.primaryColor,
                borderRadius: BorderRadius.circular(ArtisticTheme.radiusLarge),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _isTyping ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    
    // 添加用户消息
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        avatar: '😊',
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // 获取当前心情和历史记录
      final recentEntries = moodProvider.moodEntries.take(10).toList();
      final currentMood = recentEntries.isNotEmpty 
          ? recentEntries.first.mood 
          : MoodType.neutral;

      // 获取AI回复
      final response = await _aiService.getChatResponse(text, currentMood, recentEntries);

      // 添加AI回复
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          avatar: '🤖',
        ));
        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '抱歉，我现在有点忙，请稍后再试。但请记住，你的感受很重要，我会一直在这里支持你。',
          isUser: false,
          timestamp: DateTime.now(),
          avatar: '🤖',
        ));
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showInsightDialog() async {
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (moodProvider.moodEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要更多心情记录才能提供洞察分析')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💡 心理洞察'),
        content: const Text('正在分析你的心情模式...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );

    try {
      final insight = await _aiService.analyzeMoodPattern(
        moodProvider.moodEntries, 
        userProvider.currentUser!,
      );

      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('💡 心理洞察'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(insight.mainInsight),
                  const SizedBox(height: 16),
                  const Text('建议：', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...insight.recommendations.map((rec) => 
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• $rec'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('健康评分: ${(insight.wellnessScore * 100).toInt()}/100'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分析失败，请稍后再试')),
        );
      }
    }
  }

  Future<void> _showMeditationDialog() async {
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final currentMood = moodProvider.moodEntries.isNotEmpty 
        ? moodProvider.moodEntries.first.mood 
        : MoodType.neutral;
    
    final meditations = await _aiService.recommendMeditation(currentMood, 5);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🧘‍♀️ 冥想指导'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: meditations.map((meditation) => 
                ListTile(
                  leading: const Icon(Icons.self_improvement),
                  title: Text(meditation.title),
                  subtitle: Text('${meditation.duration}分钟 - ${meditation.description}'),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('开始${meditation.title}')),
                    );
                  },
                ),
              ).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }
  }
}

/// 聊天消息模型
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String avatar;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.avatar,
  });
}
