import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dialogue_provider.dart';
import '../providers/cat_provider.dart';
import '../widgets/dialogue_history.dart';
import '../widgets/dialogue_input.dart';
import '../widgets/cat_animation.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

/// 对话聊天屏幕
class DialogueScreen extends StatefulWidget {
  /// 路由名称
  static const routeName = '/dialogue';

  /// 构造函数
  const DialogueScreen({super.key});

  @override
  State<DialogueScreen> createState() => _DialogueScreenState();
}

class _DialogueScreenState extends State<DialogueScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dialogueProvider =
          Provider.of<DialogueProvider>(context, listen: false);
      if (dialogueProvider.activeSession == null) {
        dialogueProvider.createNewSession();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 发送消息
  void _handleSendMessage(String message) {
    final dialogueProvider =
        Provider.of<DialogueProvider>(context, listen: false);
    final catProvider = Provider.of<CatProvider>(context, listen: false);

    if (catProvider.hasCat) {
      dialogueProvider.sendUserMessage(message, catProvider.cat!);
    }

    // 播放猫咪动画
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '与猫咪对话',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          Consumer<DialogueProvider>(
            builder: (context, provider, child) {
              return Container(
                margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
                child: IconButton(
                  icon: Icon(
                    provider.useAI ? Icons.smart_toy : Icons.chat_bubble,
                  ),
                  onPressed: () {
                    provider.toggleAIMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              provider.useAI
                                  ? Icons.smart_toy
                                  : Icons.chat_bubble,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Text(provider.useAI ? 'AI模式已开启' : 'AI模式已关闭'),
                          ],
                        ),
                        backgroundColor: provider.useAI
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: provider.useAI ? '使用AI聊天(已开启)' : '使用模板聊天(AI已关闭)',
                  style: IconButton.styleFrom(
                    backgroundColor: provider.useAI
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : AppTheme.warningColor.withValues(alpha: 0.1),
                    foregroundColor: provider.useAI
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Text('ℹ️', style: TextStyle(fontSize: 20)),
            onPressed: () => _showApiInfoDialog(context),
            tooltip: 'API调试信息',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.infoColor.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          IconButton(
            icon: const Text('🔄', style: TextStyle(fontSize: 20)),
            onPressed: () {
              Provider.of<DialogueProvider>(context, listen: false)
                  .createNewSession();
            },
            tooltip: '开始新对话',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
        ],
      ),
      body: Consumer2<DialogueProvider, CatProvider>(
        builder: (context, dialogueProvider, catProvider, child) {
          if (!catProvider.hasCat) {
            return _buildNoCatState();
          }

          return ResponsiveContainer(
            child: Column(
              children: [
                // 猫咪动画区域
                Container(
                  margin: const EdgeInsets.all(AppTheme.spacingMedium),
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  height: ResponsiveUtils.getResponsiveValue(
                    context,
                    mobile: 140.0,
                    tablet: 160.0,
                    desktop: 180.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: CatAnimation(
                    cat: catProvider.cat!,
                    size: ResponsiveUtils.getResponsiveValue(
                      context,
                      mobile: 120.0,
                      tablet: 140.0,
                      desktop: 160.0,
                    ),
                    showMood: true,
                    onTap: () {
                      catProvider.petCat();
                    },
                  ),
                ),

                // AI模式状态指示
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: dialogueProvider.useAI
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: dialogueProvider.useAI
                          ? AppTheme.successColor.withValues(alpha: 0.3)
                          : AppTheme.warningColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        dialogueProvider.useAI
                            ? Icons.smart_toy
                            : Icons.chat_bubble,
                        size: 16,
                        color: dialogueProvider.useAI
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        dialogueProvider.useAI ? 'AI智能对话模式' : '模板对话模式',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: dialogueProvider.useAI
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),

                // 错误提示
                if (dialogueProvider.errorMessage != null)
                  InlineErrorWidget(
                    message: dialogueProvider.errorMessage!,
                    onDismiss: () {
                      setState(() {});
                    },
                  ),

                // 对话历史
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: dialogueProvider.isLoading
                        ? _buildThinkingIndicator()
                        : DialogueHistory(
                            session: dialogueProvider.activeSession,
                            scrollController: _scrollController,
                            showTypingEffect: true,
                          ),
                  ),
                ),

                // 输入框
                Container(
                  margin: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: DialogueInput(
                    onSendMessage: _handleSendMessage,
                    isLoading: dialogueProvider.isLoading,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建思考指示器
  Widget _buildThinkingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 动画猫咪emoji序列
          _buildThinkingEmojiAnimation(),
          const SizedBox(height: AppTheme.spacingLarge),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLarge,
              vertical: AppTheme.spacingMedium,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingWidget(
                  size: 20,
                  color: AppTheme.primaryColor,
                  showMessage: false,
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Text(
                  '猫咪正在思考',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                _buildTypingDots(),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            _getRandomThinkingText(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textHint,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建思考emoji动画
  Widget _buildThinkingEmojiAnimation() {
    final thinkingEmojis = ['🤔', '💭', '🧠', '💡', '😸'];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        final emojiIndex =
            (value * thinkingEmojis.length).floor() % thinkingEmojis.length;
        final scale = 0.8 + 0.4 * (0.5 + 0.5 * math.sin(value * 2 * math.pi));

        return Transform.scale(
          scale: scale,
          child: Text(
            thinkingEmojis[emojiIndex],
            style: const TextStyle(fontSize: 48),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  /// 构建打字点动画
  Widget _buildTypingDots() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final opacity = (math.sin((value + delay) * 2 * math.pi) + 1) / 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Opacity(
                opacity: opacity,
                child: const Text(
                  '.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  /// 获取随机思考文本
  String _getRandomThinkingText() {
    final thinkingTexts = [
      '正在组织语言...',
      '思考如何回复...',
      '寻找合适的词汇...',
      '准备温暖的回应...',
      '整理思绪中...',
    ];
    thinkingTexts.shuffle();
    return thinkingTexts.first;
  }

  /// 构建无猫状态
  Widget _buildNoCatState() {
    return EmptyStateWidget(
      title: '你还没有猫咪',
      message: '请先领养一只猫咪再开始对话',
      icon: null, // 将使用emoji替代
      actionText: '返回首页',
      onAction: () {
        Navigator.of(context).pop();
      },
    );
  }

  /// 显示API信息对话框
  void _showApiInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              'ℹ️',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            const Text('API状态信息'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<DialogueProvider>(
                builder: (ctx, provider, _) {
                  return Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    decoration: BoxDecoration(
                      color: provider.useAI
                          ? AppTheme.successColor.withValues(alpha: 0.1)
                          : AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                        color: provider.useAI
                            ? AppTheme.successColor.withValues(alpha: 0.3)
                            : AppTheme.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          provider.useAI ? Icons.smart_toy : Icons.chat_bubble,
                          color: provider.useAI
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          'AI模式: ${provider.useAI ? "开启" : "关闭"}',
                          style: TextStyle(
                            color: provider.useAI
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: AppTheme.infoColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '调试提示：',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.infoColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    ...const [
                      '1. 确保.env文件已正确配置',
                      '2. 确保API密钥有效',
                      '3. 检查网络连接',
                      '4. 如果仍有问题，查看控制台日志',
                    ].map((text) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            text,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/api-debug');
            },
            child: const Text('打开调试工具'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
