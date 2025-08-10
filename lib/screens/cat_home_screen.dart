import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../widgets/cat_animation.dart';
import '../widgets/common/loading_widget.dart';

import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../utils/responsive_utils.dart';
import '../utils/cat_image_manager.dart';
import '../theme/artistic_theme.dart';
import '../widgets/artistic_button.dart';
import '../widgets/simple_chat_bubble.dart';
import 'adopt_cat_screen.dart';
import 'dialogue_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CatHomeScreen extends StatefulWidget {
  const CatHomeScreen({super.key});

  @override
  State<CatHomeScreen> createState() => _CatHomeScreenState();
}

class _CatHomeScreenState extends State<CatHomeScreen>
    with TickerProviderStateMixin {
  int _petCount = 0;

  // 手势识别相关
  int _tapCount = 0;
  DateTime? _lastTapTime;
  static const Duration _tapTimeout = Duration(milliseconds: 500);

  // 动画控制器
  late AnimationController _bubbleController;
  late AnimationController _catScaleController;
  late Animation<double> _bubbleAnimation;
  late Animation<double> _catScaleAnimation;

  // 气泡消息
  String _currentBubbleMessage = '';
  String _currentBubbleEmoji = '';
  bool _showBubble = false;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _catScaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bubbleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.elasticOut,
    ));

    _catScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _catScaleController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _catScaleController.dispose();
    super.dispose();
  }

  // 手势识别处理
  void _handleCatInteraction(CatProvider catProvider) {
    final now = DateTime.now();

    // 检查是否在连击时间窗口内
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < _tapTimeout) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }

    _lastTapTime = now;

    // 根据点击次数执行不同的交互
    if (_tapCount == 1) {
      // 单击 - 轻拍
      _performGentlePat(catProvider);
    } else if (_tapCount >= 2 && _tapCount <= 3) {
      // 双击/三击 - 抚摸
      _performPetting(catProvider);
    } else if (_tapCount >= 4) {
      // 多次点击 - 殴打（调皮的互动）
      _performPlayfulHit(catProvider);
    }

    // 延迟重置点击计数
    Future.delayed(_tapTimeout, () {
      if (mounted && _lastTapTime != null &&
          now.difference(_lastTapTime!) >= _tapTimeout) {
        _tapCount = 0;
      }
    });
  }

  // 轻拍交互
  void _performGentlePat(CatProvider catProvider) {
    catProvider.petCat();
    _showCatResponse('😊', '喵~ 轻轻的好舒服呢');
    _triggerCatAnimation();
    HapticFeedback.lightImpact();

    setState(() {
      _petCount++;
    });
  }

  // 抚摸交互
  void _performPetting(CatProvider catProvider) {
    catProvider.petCat();
    final responses = [
      ('😸', '喵喵~ 好喜欢这样'),
      ('🥰', '继续摸摸我吧~'),
      ('😽', '你的手好温暖'),
    ];
    final response = responses[_tapCount % responses.length];
    _showCatResponse(response.$1, response.$2);
    _triggerCatAnimation();
    HapticFeedback.mediumImpact();

    setState(() {
      _petCount += 2;
    });
  }

  // 调皮互动（多次点击）
  void _performPlayfulHit(CatProvider catProvider) {
    catProvider.playWithCat();
    final responses = [
      ('😾', '喵！轻一点啦'),
      ('🙀', '你在干什么呀！'),
      ('😤', '哼，不理你了'),
      ('😼', '想玩是吧，来啊！'),
    ];
    final response = responses[(_tapCount - 4) % responses.length];
    _showCatResponse(response.$1, response.$2);
    _triggerCatAnimation();
    HapticFeedback.heavyImpact();

    setState(() {
      _petCount++;
    });
  }

  // 滑动手势处理
  void _handlePanGesture(DragUpdateDetails details, CatProvider catProvider) {
    // 检测滑动方向和速度
    final velocity = details.delta;
    final speed = velocity.distance;

    if (speed > 2.0) { // 滑动速度阈值
      catProvider.petCat();

      if (velocity.dx.abs() > velocity.dy.abs()) {
        // 水平滑动
        if (velocity.dx > 0) {
          _showCatResponse('😸', '向右摸摸，好舒服~');
        } else {
          _showCatResponse('😊', '向左摸摸，喜欢这样');
        }
      } else {
        // 垂直滑动
        if (velocity.dy > 0) {
          _showCatResponse('🥰', '从上往下摸，好温柔');
        } else {
          _showCatResponse('😽', '轻抚我的头吧~');
        }
      }

      _triggerCatAnimation();
      HapticFeedback.selectionClick();

      setState(() {
        _petCount++;
      });
    }
  }

  // 显示猫咪回应气泡
  void _showCatResponse(String emoji, String message) {
    setState(() {
      _currentBubbleEmoji = emoji;
      _currentBubbleMessage = message;
      _showBubble = true;
    });

    _bubbleController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _bubbleController.reverse().then((_) {
            setState(() {
              _showBubble = false;
            });
          });
        }
      });
    });
  }

  // 触发猫咪动画
  void _triggerCatAnimation() {
    _catScaleController.forward().then((_) {
      _catScaleController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisticTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '暖猫家园',
          style: ArtisticTheme.headlineLarge.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Text('💬', style: TextStyle(fontSize: 20)),
            onPressed: () {
              Navigator.of(context).pushWithSlideUp(const DialogueScreen());
            },
            tooltip: '与猫咪对话',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),

          const SizedBox(width: AppTheme.spacingSmall),
          IconButton(
            icon: const Text('ℹ️', style: TextStyle(fontSize: 20)),
            onPressed: () => _showApiStatusDialog(context),
            tooltip: 'API状态',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.infoColor.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
        ],
      ),
      body: Consumer<CatProvider>(
        builder: (context, catProvider, child) {
          if (catProvider.isLoading) {
            return const PageLoadingWidget(
              message: '正在加载猫咪信息...',
            );
          }

          if (!catProvider.hasCat) {
            return Container(
              decoration: BoxDecoration(
                gradient: ArtisticTheme.backgroundGradient,
              ),
              child: ResponsiveContainer(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: ArtisticTheme.joyColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(
                            color: ArtisticTheme.joyColor.withValues(alpha: 0.2),
                            width: 2,
                          ),
                          boxShadow: ArtisticTheme.softShadow,
                        ),
                        child: const Center(
                          child: Text(
                            '🐱',
                            style: TextStyle(fontSize: 60),
                          ),
                        ),
                      ),
                      const SizedBox(height: ArtisticTheme.spacingXLarge),
                      Text(
                        '还没有猫咪陪伴你',
                        style: ArtisticTheme.headlineLarge.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: ArtisticTheme.spacingMedium),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ArtisticTheme.spacingXLarge,
                        ),
                        child: Text(
                          '领养一只可爱的猫咪\n开始你的暖猫之旅吧！',
                          style: ArtisticTheme.bodyLarge.copyWith(
                            color: ArtisticTheme.textSecondary,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: ArtisticTheme.spacingXXLarge),
                      ArtisticButton(
                        text: '领养猫咪',
                        icon: Icons.pets,
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  const AdoptCatScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        style: ArtisticButtonStyle.primary,
                        width: 200,
                        height: 56,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final cat = catProvider.cat!;

          return ResponsiveContainer(
            child: SafeArea(
              child: Column(
                children: [
                  // 简化的猫咪信息栏
                  Container(
                    margin: const EdgeInsets.all(ArtisticTheme.spacingMedium),
                    padding: const EdgeInsets.symmetric(
                      horizontal: ArtisticTheme.spacingLarge,
                      vertical: ArtisticTheme.spacingMedium,
                    ),
                    decoration: ArtisticTheme.glassEffect,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(ArtisticTheme.spacingSmall),
                          decoration: BoxDecoration(
                            color: ArtisticTheme.getMoodColor(cat.mood.toString()).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(ArtisticTheme.radiusSmall),
                          ),
                          child: Text(
                            cat.moodText,
                            style: ArtisticTheme.bodyMedium.copyWith(
                              color: ArtisticTheme.getMoodColor(cat.mood.toString()),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: ArtisticTheme.spacingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: ArtisticTheme.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                CatImageManager.getCatBreedName(cat.breedString),
                                style: ArtisticTheme.bodySmall.copyWith(
                                  color: ArtisticTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 简化的状态指示器
                        Row(
                          children: [
                            _buildMiniStatusIndicator('❤️', cat.happiness),
                            const SizedBox(width: ArtisticTheme.spacingSmall),
                            _buildMiniStatusIndicator('⚡', cat.energyLevel),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 主要的猫咪交互区域
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(ArtisticTheme.spacingMedium),
                      decoration: BoxDecoration(
                        gradient: ArtisticTheme.backgroundGradient,
                        borderRadius: BorderRadius.circular(ArtisticTheme.radiusXLarge),
                        boxShadow: ArtisticTheme.softShadow,
                      ),
                      child: Stack(
                        children: [
                          // 手势识别区域
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () => _handleCatInteraction(catProvider),
                              onPanUpdate: (details) => _handlePanGesture(details, catProvider),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(ArtisticTheme.radiusXLarge),
                                ),
                              ),
                            ),
                          ),

                          // 猫咪主体
                          Center(
                            child: AnimatedBuilder(
                              animation: _catScaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _catScaleAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(ArtisticTheme.radiusXXLarge),
                                      boxShadow: [
                                        BoxShadow(
                                          color: ArtisticTheme.getMoodColor(cat.mood.toString()).withValues(alpha: 0.2),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: CatAnimation(
                                      cat: cat,
                                      size: ResponsiveUtils.getResponsiveValue(
                                        context,
                                        mobile: 180.0,
                                        tablet: 220.0,
                                        desktop: 260.0,
                                      ),
                                      onTap: () {}, // 禁用CatAnimation内部的点击处理
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // 气泡消息
                          if (_showBubble)
                            Positioned(
                              top: 80,
                              left: 0,
                              right: 0,
                              child: AnimatedBuilder(
                                animation: _bubbleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _bubbleAnimation.value,
                                    child: Opacity(
                                      opacity: _bubbleAnimation.value,
                                      child: Center(
                                        child: SimpleChatBubble(
                                          message: _currentBubbleMessage,
                                          emoji: _currentBubbleEmoji,
                                          isUser: false,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          // 手势提示
                          Positioned(
                            bottom: 30,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: ArtisticTheme.spacingLarge,
                                  vertical: ArtisticTheme.spacingSmall,
                                ),
                                decoration: ArtisticTheme.glassEffect,
                                child: Text(
                                  '点击、滑动与猫咪互动 🐾',
                                  style: ArtisticTheme.bodySmall.copyWith(
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 0.5,
                                    color: ArtisticTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 简洁的互动统计
                  Container(
                    margin: const EdgeInsets.all(ArtisticTheme.spacingMedium),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInteractionStat('🐾', '今日互动', '$_petCount 次'),
                        _buildInteractionStat('😊', '猫咪心情', cat.moodText),
                        _buildInteractionStat('⭐', '亲密度', '${cat.happiness}%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 构建迷你状态指示器
  Widget _buildMiniStatusIndicator(String emoji, int value) {
    Color color = ArtisticTheme.primaryColor;
    if (value > 70) {
      color = ArtisticTheme.successColor;
    } else if (value > 30) {
      color = ArtisticTheme.warningColor;
    } else {
      color = ArtisticTheme.errorColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArtisticTheme.spacingSmall,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ArtisticTheme.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 2),
          Text(
            '$value%',
            style: ArtisticTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 构建互动统计项
  Widget _buildInteractionStat(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
      decoration: ArtisticTheme.glassEffect,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: ArtisticTheme.spacingXSmall),
          Text(
            label,
            style: ArtisticTheme.caption.copyWith(
              color: ArtisticTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: ArtisticTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: ArtisticTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 手绘风格状态项
  Widget _buildHandDrawnStatusItem(String emoji, String label, String value) {
    Color statusColor = AppTheme.primaryColor;

    // 根据状态值设置颜色
    if (label == '心情') {
      statusColor = AppTheme.getMoodColor(value);
    } else if (label == '能量') {
      final energyValue = int.tryParse(value.replaceAll('%', '')) ?? 0;
      if (energyValue > 70) {
        statusColor = AppTheme.successColor;
      } else if (energyValue > 30) {
        statusColor = AppTheme.warningColor;
      } else {
        statusColor = AppTheme.errorColor;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: AppTheme.spacingXSmall),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// 显示API状态对话框
  void _showApiStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              _isApiKeyConfigured() ? '✅' : '❌',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            const Text('API状态'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('API密钥', _isApiKeyConfigured() ? "已配置" : "未配置"),
              const SizedBox(height: AppTheme.spacingSmall),
              _buildInfoRow('密钥信息', _maskApiKey()),
              _buildInfoRow('API端点', _getApiEndpoint()),
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
                      '调试说明:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.infoColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    ...const [
                      '1. 请确保.env文件已正确配置',
                      '2. API密钥格式应为: sk-xxx...',
                      '3. 如无法连接，请检查网络设置',
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // 检查API密钥是否已配置
  bool _isApiKeyConfigured() {
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
    return apiKey != null && apiKey.isNotEmpty && apiKey.startsWith('sk-');
  }

  // 获取并遮盖API密钥
  String _maskApiKey() {
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '未配置';
    if (apiKey.length > 10) {
      return '${apiKey.substring(0, 5)}...${apiKey.substring(apiKey.length - 5)}';
    }
    return apiKey;
  }

  // 获取API端点
  String _getApiEndpoint() {
    return dotenv.env['DEEPSEEK_API_ENDPOINT'] ?? '未配置';
  }
}
