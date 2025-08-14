import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../theme/artistic_theme.dart';
import '../utils/cat_image_manager.dart';

/// 悬浮猫咪助手组件
class FloatingCatAssistant extends StatefulWidget {
  final Animation<double> animation;
  final VoidCallback onTap;
  final bool showNotification;

  const FloatingCatAssistant({
    super.key,
    required this.animation,
    required this.onTap,
    this.showNotification = false,
  });

  @override
  State<FloatingCatAssistant> createState() => _FloatingCatAssistantState();
}

class _FloatingCatAssistantState extends State<FloatingCatAssistant>
    with TickerProviderStateMixin {
  
  late AnimationController _notificationController;
  late Animation<double> _notificationAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // 通知动画
    _notificationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _notificationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _notificationController,
      curve: Curves.elasticOut,
    ));

    // 光晕动画
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    _glowController.repeat(reverse: true);

    // 如果需要显示通知，启动动画
    if (widget.showNotification) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _notificationController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _notificationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CatProvider>(
      builder: (context, catProvider, child) {
        final cat = catProvider.cat;
        
        return GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 主猫咪按钮
              AnimatedBuilder(
                animation: widget.animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.animation.value,
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                ArtisticTheme.primaryColor.withValues(alpha: 0.8),
                                ArtisticTheme.primaryColor.withValues(alpha: 0.6),
                                ArtisticTheme.primaryColor.withValues(alpha: 0.3),
                              ],
                              stops: [0.0, 0.7, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ArtisticTheme.primaryColor.withValues(alpha: 
                                  0.3 * _glowAnimation.value,
                                ),
                                blurRadius: 20 * _glowAnimation.value,
                                spreadRadius: 5 * _glowAnimation.value,
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: ArtisticTheme.elevatedShadow,
                            ),
                            child: _buildCatAvatar(cat),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // 通知气泡
              if (widget.showNotification)
                Positioned(
                  top: -10,
                  right: -10,
                  child: ScaleTransition(
                    scale: _notificationAnimation,
                    child: _buildNotificationBubble(),
                  ),
                ),

              // 功能提示
              if (widget.showNotification)
                Positioned(
                  bottom: -50,
                  left: -20,
                  right: -20,
                  child: FadeTransition(
                    opacity: _notificationAnimation,
                    child: _buildFunctionHint(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCatAvatar(cat) {
    if (cat == null) {
      return const Icon(
        Icons.pets,
        size: 40,
        color: ArtisticTheme.primaryColor,
      );
    }

    // 获取猫咪图片（传入字符串品种名）
    final catImagePath = CatImageManager.getCatImagePath(cat.breedString);

    return ClipOval(
      child: Image.asset(
        catImagePath,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  ArtisticTheme.primaryColor.withValues(alpha: 0.3),
                  ArtisticTheme.primaryColor.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.pets,
              size: 32,
              color: ArtisticTheme.primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationBubble() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.notifications,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFunctionHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '点击我查看更多功能 ✨',
        style: ArtisticTheme.bodyStyle.copyWith(
          color: Colors.white,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 悬浮猫咪状态指示器
class CatStatusIndicator extends StatelessWidget {
  final String status;
  final Color color;

  const CatStatusIndicator({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
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
}
