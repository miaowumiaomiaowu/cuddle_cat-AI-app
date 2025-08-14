import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../models/cat.dart';
import '../theme/artistic_theme.dart';

/// 增强的猫咪互动组件
class EnhancedCatInteraction extends StatefulWidget {
  final VoidCallback? onInteractionComplete;

  const EnhancedCatInteraction({
    super.key,
    this.onInteractionComplete,
  });

  @override
  State<EnhancedCatInteraction> createState() => _EnhancedCatInteractionState();
}

class _EnhancedCatInteractionState extends State<EnhancedCatInteraction>
    with TickerProviderStateMixin {
  
  late AnimationController _catController;
  late AnimationController _heartController;
  late AnimationController _sparkleController;
  
  late Animation<double> _catScaleAnimation;
  late Animation<double> _catRotationAnimation;
  late Animation<double> _heartAnimation;
  late Animation<double> _sparkleAnimation;
  
  List<InteractionEffect> _effects = [];
  String _currentMood = '😊';
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    
    _catController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _catScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _catController,
      curve: Curves.elasticOut,
    ));
    
    _catRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _catController,
      curve: Curves.easeInOut,
    ));
    
    _heartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeOut,
    ));
    
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _catController.dispose();
    _heartController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CatProvider>(
      builder: (context, catProvider, child) {
        final cat = catProvider.cat;
        if (cat == null) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ArtisticTheme.backgroundColor,
                ArtisticTheme.surfaceColor,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // 背景装饰
              _buildBackgroundDecoration(),
              
              // 主猫咪
              Center(
                child: GestureDetector(
                  onTap: () => _handleCatInteraction(cat),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _catController,
                      _heartController,
                      _sparkleController,
                    ]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _catScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _catRotationAnimation.value,
                          child: _buildCatAvatar(cat),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // 互动效果
              ..._effects.map((effect) => _buildEffect(effect)),
              
              // 互动提示
              if (!_isInteracting) _buildInteractionHint(),
              
              // 心情显示
              _buildMoodDisplay(cat),
              
              // 互动按钮
              _buildInteractionButtons(cat),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BackgroundDecorationPainter(
          sparkleAnimation: _sparkleAnimation,
        ),
      ),
    );
  }

  Widget _buildCatAvatar(Cat cat) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            ArtisticTheme.primaryColor.withValues(alpha: 0.2),
            ArtisticTheme.primaryColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ArtisticTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          _currentMood,
          style: const TextStyle(fontSize: 60),
        ),
      ),
    );
  }

  Widget _buildEffect(InteractionEffect effect) {
    return Positioned(
      left: effect.position.dx,
      top: effect.position.dy,
      child: AnimatedBuilder(
        animation: effect.controller,
        builder: (context, child) {
          return Transform.scale(
            scale: effect.scaleAnimation.value,
            child: Opacity(
              opacity: effect.opacityAnimation.value,
              child: Text(
                effect.emoji,
                style: TextStyle(
                  fontSize: 24 + effect.scaleAnimation.value * 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInteractionHint() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '点击猫咪进行互动 🐾',
            style: ArtisticTheme.bodyStyle.copyWith(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodDisplay(Cat cat) {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cat.mood.toString(),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              '${cat.name}的心情',
              style: ArtisticTheme.bodyStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionButtons(Cat cat) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.pets,
            label: '抚摸',
            color: Colors.pink,
            onTap: () => _performAction('pet', cat),
          ),
          _buildActionButton(
            icon: Icons.favorite,
            label: '喂食',
            color: Colors.orange,
            onTap: () => _performAction('feed', cat),
          ),
          _buildActionButton(
            icon: Icons.toys,
            label: '玩耍',
            color: Colors.blue,
            onTap: () => _performAction('play', cat),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: ArtisticTheme.bodyStyle.copyWith(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCatInteraction(Cat cat) {
    if (_isInteracting) return;
    
    setState(() {
      _isInteracting = true;
    });
    
    // 触觉反馈
    HapticFeedback.mediumImpact();
    
    // 播放动画
    _catController.forward().then((_) {
      _catController.reverse();
    });
    
    // 添加互动效果
    _addInteractionEffect();
    
    // 更新心情
    _updateMood(cat);
    
    // 重置状态
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isInteracting = false;
        });
        widget.onInteractionComplete?.call();
      }
    });
  }

  void _performAction(String action, Cat cat) {
    HapticFeedback.lightImpact();
    
    String emoji;
    switch (action) {
      case 'pet':
        emoji = '💕';
        break;
      case 'feed':
        emoji = '🍎';
        break;
      case 'play':
        emoji = '🎾';
        break;
      default:
        emoji = '✨';
    }
    
    _addInteractionEffect(emoji: emoji);
    _handleCatInteraction(cat);
  }

  void _addInteractionEffect({String? emoji}) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final effect = InteractionEffect(
      emoji: emoji ?? ['💖', '✨', '🌟', '💫'][random % 4],
      position: Offset(
        100 + (random % 200).toDouble(),
        150 + (random % 100).toDouble(),
      ),
    );
    
    setState(() {
      _effects.add(effect);
    });
    
    effect.controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _effects.remove(effect);
        });
        effect.dispose();
      }
    });
  }

  void _updateMood(Cat cat) {
    final moods = ['😊', '😸', '🥰', '😻', '😽'];
    final random = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _currentMood = moods[random % moods.length];
    });
  }
}

/// 互动效果类
class InteractionEffect {
  final String emoji;
  final Offset position;
  late AnimationController controller;
  late Animation<double> scaleAnimation;
  late Animation<double> opacityAnimation;

  InteractionEffect({
    required this.emoji,
    required this.position,
  }) {
    // 注释掉有问题的动画控制器，需要正确的TickerProvider
    // controller = AnimationController(
    //   duration: const Duration(milliseconds: 1500),
    //   vsync: NavigatorState(),
    // );
    
    scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
    
    opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
  }

  void dispose() {
    controller.dispose();
  }
}

/// 背景装饰绘制器
class BackgroundDecorationPainter extends CustomPainter {
  final Animation<double> sparkleAnimation;

  BackgroundDecorationPainter({required this.sparkleAnimation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ArtisticTheme.primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // 绘制装饰性的圆点
    for (int i = 0; i < 20; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 43) % size.height;
      final radius = 2 + sparkleAnimation.value * 3;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
