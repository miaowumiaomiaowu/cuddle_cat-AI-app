import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/artistic_theme.dart';
import '../services/ai_service.dart';
import '../services/ai_psychology_service.dart';
import '../services/chat_reply_api_client.dart';
import '../services/feedback_api_client.dart';
import '../providers/mood_provider.dart';
import '../providers/user_provider.dart';

import '../models/mood_record.dart';
import '../models/cat.dart';
import '../models/dialogue.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/reminders_api_client.dart';
import '../services/reminder_service.dart';

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
  final AIService _aiService = AIService();
  final AIPsychologyService _psychService = AIPsychologyService();
  final ChatReplyApiClient _chatApi = ChatReplyApiClient();
  final RemindersApiClient _remindersApi = RemindersApiClient();
  final ReminderService _reminderService = ReminderService();
  bool _useServerChat = false; // feature flag


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
                color: ArtisticTheme.primaryColor.withValues(alpha: 0.1),
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
            icon: Icon(_useServerChat ? Icons.cloud_done : Icons.cloud_off),
            onPressed: () => setState(() => _useServerChat = !_useServerChat),
            tooltip: _useServerChat ? '使用服务器聊天(开)' : '使用服务器聊天(关)',
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
                color: ArtisticTheme.primaryColor.withValues(alpha: 0.1),
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
                      if (!message.isUser) ...[
                        const SizedBox(height: 8),
                        _buildAssistantExtras(message),
                      ],
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
                color: ArtisticTheme.accentColor.withValues(alpha: 0.1),
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
              color: ArtisticTheme.primaryColor.withValues(alpha: 0.1),
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
            color: ArtisticTheme.primaryColor.withValues(alpha: opacity),
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
            color: Colors.black.withValues(alpha: 0.05),
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
      String response;
      Map<String, dynamic>? serverData;
      if (_useServerChat) {
        serverData = await _chatApi.reply(
          messages: _messages
              .map((m) => {"role": m.isUser ? "user" : "assistant", "content": m.text})
              .toList()
            ..add({"role": "user", "content": text}),
          topK: 3,
        );
        response = (serverData != null ? (serverData["text"] as String? ?? "") : "").trim();
        // 智能目标识别 -> 用户确认 -> 安排提醒
        try {
          final extracted = (serverData != null ? (serverData['extracted_goals'] as List? ?? []) : [])
              .cast<Map<String, dynamic>>();
          if (extracted.isNotEmpty) {
            final goalText = (extracted.first['content'] as String?)?.trim();
            if (goalText != null && goalText.isNotEmpty) {
              final confirm = await _showReminderConfirm(context, goalText);
              if (!mounted) return;
              if (confirm == true) {
                // 取建议文案
                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('user_id') ?? 'anonymous';
                final suggestions = await _remindersApi.getSuggestions(userId: userId, limit: 3);
                final message = suggestions.isNotEmpty ? suggestions.first : '给自己一点耐心，迈出小小一步。';
                // 默认时间 9:00 与每日频率
                final defaults = await _reminderService.getDefaultSettings();
                final plan = ReminderPlan(
                  id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
                  goalText: goalText,
                  message: message,
                  hour: defaults.hour,
                  minute: defaults.minute,
                  frequency: defaults.frequency,
                );
                await _reminderService.initialize();
                await _reminderService.schedulePlan(plan);
                final plans = await _reminderService.loadPlans();
                plans.add(plan);
                await _reminderService.savePlans(plans);
              }
            }
          }
        } catch (_) {}

        if (response.isEmpty) {
          // 回退本地生成
          final dialogueMessage = DialogueMessage.fromUser(text: text);
          final aiReply = await _aiService.generateCatReply(
            userMessage: dialogueMessage,
            cat: Cat(name: '小暖', breed: CatBreed.random),
            conversationHistory: _messages
                .map((m) => m.isUser ? DialogueMessage.fromUser(text: m.text) : DialogueMessage.fromCat(text: m.text))
                .toList(),
          );
          response = aiReply.text;
        }
      } else {
        // 本地原有逻辑
        final dialogueMessage = DialogueMessage.fromUser(text: text);
        final aiReply = await _aiService.generateCatReply(
          userMessage: dialogueMessage,
          cat: Cat(name: '小暖', breed: CatBreed.random),
          conversationHistory: _messages
              .map((m) => m.isUser ? DialogueMessage.fromUser(text: m.text) : DialogueMessage.fromCat(text: m.text))
              .toList(),
        );
        response = aiReply.text;
      }

      // 添加AI回复
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          avatar: '🤖',
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          usedMemories: (_useServerChat && (serverData != null)) ? (serverData['used_memories'] as List?)?.cast<Map<String, dynamic>>() : null,
          profile: (_useServerChat && (serverData != null)) ? (serverData['profile'] as Map<String, dynamic>?) : null,
          references: (_useServerChat && (serverData != null)) ? (serverData['references'] as List?)?.cast<String>() : null,
        ));
        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '当前网络不可用或服务异常，请检查网络连接后重试。',
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
      final insight = await _psychService.analyzeMoodPattern(
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

    final meditations = await _psychService.recommendMeditation(currentMood, 5);


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

  Widget _buildAssistantExtras(ChatMessage message) {
    // 展示“依据的记忆/画像”参考与反馈按钮
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          collapsedIconColor: ArtisticTheme.textSecondary,
          iconColor: ArtisticTheme.textSecondary,
          title: Text('参考与反馈', style: ArtisticTheme.caption.copyWith(color: ArtisticTheme.textSecondary)),
          childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          children: [
            // 参考信息（当前最小版：提示说明；后续可接 /chat/reply 的 used_memories/profile）
            Text('本次建议基于你的历史偏好与记忆检索结果生成。', style: ArtisticTheme.caption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFeedbackChip('👍 喜欢', 'like'),
                _buildFeedbackChip('✅ 有用', 'useful'),
              if (message.usedMemories != null && message.usedMemories!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('参考记忆：', style: ArtisticTheme.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...message.usedMemories!.take(3).map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('- ${m['text'] ?? ''}', style: ArtisticTheme.caption),
                    )),
              ],
              if (message.profile != null && (message.profile!['top_categories'] is List) && (message.profile!['top_categories'] as List).isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('画像Top类别：${(message.profile!['top_categories'] as List).take(3).join(', ')}', style: ArtisticTheme.caption),
              ],
              if ((message.profile?['references'] is List) && (message.profile!['references'] as List).isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('参考摘要：${(message.profile!['references'] as List).join(', ')}', style: ArtisticTheme.caption),
              if (message.references != null && message.references!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('参考摘要：${message.references!.join(', ')}', style: ArtisticTheme.caption),
              ],
              ],
              _buildFeedbackChip('👍 喜欢', 'like', targetId: message.id),
              _buildFeedbackChip('✅ 有用', 'useful', targetId: message.id),
              _buildFeedbackChip('⏭ 跳过', 'skip', targetId: message.id),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackChip(String label, String type, {String? targetId}) {
    bool busy = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return ActionChip(
          label: Text(label, style: ArtisticTheme.caption),

          onPressed: busy
              ? null
              : () async {
                  try {
                    setState(() => busy = true);
                    final ok = await FeedbackApiClient().postFeedback(
                      feedbackType: type,
                      targetType: 'chat',
                      targetId: targetId,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? '已记录你的反馈' : '反馈失败，请稍后再试')),
                    );
                  } catch (_) {
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
        );
      },
    );
  }

  Future<bool?> _showReminderConfirm(BuildContext context, String goalText) async {
    if (!mounted) return false;
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('设置目标提醒'),
          content: Text('检测到你的目标："$goalText"\n是否为你在每天上午9:00添加一个温暖提醒？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('暂不')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('好的')),
          ],
        );
      },
    );
  }
}

/// 聊天消息模型
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String avatar;
  final String? id; // 用于反馈归因
  final List<Map<String, dynamic>>? usedMemories; // 服务端返回的参考记忆
  final Map<String, dynamic>? profile; // 服务端返回的画像片段
  final List<String>? references; // 服务端返回的参考摘要

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.avatar,
    this.id,
    this.usedMemories,
    this.profile,
    this.references,
  });
}
