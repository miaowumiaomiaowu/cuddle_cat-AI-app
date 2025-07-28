import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../widgets/cat_animation.dart';
import '../widgets/cat_interaction_panel.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/hand_drawn_card.dart';
import '../widgets/hand_drawn_button.dart';
import '../widgets/animated_hand_drawn_button.dart';
import '../utils/animation_utils.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../utils/responsive_utils.dart';
import '../utils/cat_image_manager.dart';
import '../theme/artistic_theme.dart';
import '../widgets/artistic_chart.dart';
import '../widgets/artistic_button.dart';
import 'adopt_cat_screen.dart';
import 'dialogue_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CatHomeScreen extends StatefulWidget {
  const CatHomeScreen({super.key});

  @override
  State<CatHomeScreen> createState() => _CatHomeScreenState();
}

class _CatHomeScreenState extends State<CatHomeScreen> {
  int _petCount = 0;

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
                          color: ArtisticTheme.joyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(
                            color: ArtisticTheme.joyColor.withOpacity(0.2),
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
                  // 艺术感猫咪状态面板
                  Container(
                    margin: const EdgeInsets.all(ArtisticTheme.spacingMedium),
                    padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
                    decoration: ArtisticTheme.artisticCard,
                    child: Column(
                      children: [
                        // 猫咪名称和品种
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(ArtisticTheme.spacingSmall),
                              decoration: BoxDecoration(
                                color: ArtisticTheme.getMoodColor(cat.mood.toString()).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(ArtisticTheme.radiusSmall),
                              ),
                              child: const Text('🐾', style: TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: ArtisticTheme.spacingMedium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: ArtisticTheme.headlineMedium,
                                  ),
                                  Text(
                                    CatImageManager.getCatBreedName(cat.breedString),
                                    style: ArtisticTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: ArtisticTheme.spacingLarge),
                        // 简化的状态显示
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ArtisticStatusCard(
                                title: '快乐度',
                                value: '${cat.happiness}%',
                                icon: Icons.favorite,
                                color: ArtisticTheme.joyColor,
                              ),
                            ),
                            const SizedBox(width: ArtisticTheme.spacingMedium),
                            Expanded(
                              child: ArtisticStatusCard(
                                title: '能量值',
                                value: '${cat.energyLevel}%',
                                icon: Icons.flash_on,
                                color: ArtisticTheme.energyColor,
                              ),
                            ),
                            const SizedBox(width: ArtisticTheme.spacingMedium),
                            Expanded(
                              child: ArtisticStatusCard(
                                title: '心情',
                                value: cat.moodText,
                                icon: Icons.mood,
                                color: ArtisticTheme.getMoodColor(cat.mood.toString()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 艺术感猫咪显示区域
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
                          // 艺术装饰元素
                          Positioned(
                            top: 30,
                            right: 30,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: ArtisticTheme.joyColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: ArtisticTheme.joyColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Text('✨', style: TextStyle(fontSize: 24)),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 40,
                            left: 30,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: ArtisticTheme.energyColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: ArtisticTheme.energyColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Text('🌸', style: TextStyle(fontSize: 20)),
                              ),
                            ),
                          ),
                          // 猫咪主体
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(ArtisticTheme.radiusXXLarge),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ArtisticTheme.getMoodColor(cat.mood.toString()).withOpacity(0.2),
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
                                    onTap: () {
                                      setState(() {
                                        _petCount++;
                                      });
                                      catProvider.petCat();
                                    },
                                  ),
                                ),
                                const SizedBox(height: ArtisticTheme.spacingLarge),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ArtisticTheme.spacingLarge,
                                    vertical: ArtisticTheme.spacingMedium,
                                  ),
                                  decoration: ArtisticTheme.glassEffect,
                                  child: Text(
                                    '轻触猫咪来抚摸它 🐾',
                                    style: ArtisticTheme.bodyMedium.copyWith(
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 猫咪互动面板
                  CatInteractionPanel(
                    onPetCat: () {
                      setState(() {
                        _petCount++;
                      });
                    },
                  ),

                  // 艺术感抚摸计数器
                  Container(
                    margin: const EdgeInsets.all(ArtisticTheme.spacingMedium),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ArtisticTheme.spacingLarge,
                            vertical: ArtisticTheme.spacingMedium,
                          ),
                          decoration: ArtisticTheme.glassEffect,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(ArtisticTheme.spacingSmall),
                                decoration: BoxDecoration(
                                  color: ArtisticTheme.loveColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(ArtisticTheme.radiusSmall),
                                ),
                                child: Icon(
                                  Icons.pets,
                                  size: 18,
                                  color: ArtisticTheme.loveColor,
                                ),
                              ),
                              const SizedBox(width: ArtisticTheme.spacingMedium),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '今日互动',
                                    style: ArtisticTheme.caption,
                                  ),
                                  Text(
                                    '$_petCount 次',
                                    style: ArtisticTheme.titleMedium.copyWith(
                                      color: ArtisticTheme.loveColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
