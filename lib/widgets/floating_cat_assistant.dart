import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../theme/artistic_theme.dart';
import '../utils/cat_image_manager.dart';

/// 悬浮猫咪助手组件（无气泡、无边框，保留柔和光晕）
class FloatingCatAssistant extends StatefulWidget {
  final Animation<double> animation;
  final VoidCallback onTap;
  final bool showNotification; // 保留字段，不再显示气泡

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
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
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
          child: AnimatedBuilder(
            animation: Listenable.merge([widget.animation, _glowAnimation]),
            builder: (context, _) {
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
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ArtisticTheme.primaryColor
                          .withValues(alpha: 0.3 * _glowAnimation.value),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildCatAvatar(cat),
                ),
              );
            },
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
    final catImagePath = CatImageManager.getCatImagePath(cat.breedString);
    return ClipOval(
      child: Image.asset(
        catImagePath,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.pets,
          size: 40,
          color: ArtisticTheme.primaryColor,
        ),
      ),
    );
  }
}

