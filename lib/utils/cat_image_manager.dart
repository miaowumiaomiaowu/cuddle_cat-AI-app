import 'package:flutter/material.dart';

/// 猫咪图片管理器 - 管理不同品种的猫咪图片
class CatImageManager {
  // 猫咪品种枚举
  static const Map<String, String> catBreeds = {
    'bengal': 'assets/base/cat_bengal_idle.png',
    'maine_coon': 'assets/base/cat_maine_coon_idle.png',
    'persian': 'assets/base/cat_persian_idle.png',
    'ragdoll': 'assets/base/cat_ragdoll_idle.png',
    'siamese': 'assets/base/cat_siamese_idle.png',
  };

  // 猫咪品种中文名称
  static const Map<String, String> catBreedNames = {
    'bengal': '孟加拉猫',
    'maine_coon': '缅因猫',
    'persian': '波斯猫',
    'ragdoll': '布偶猫',
    'siamese': '暹罗猫',
  };

  // 猫咪品种描述
  static const Map<String, String> catBreedDescriptions = {
    'bengal': '活泼好动，充满野性魅力的孟加拉猫',
    'maine_coon': '温和友善，体型庞大的缅因猫',
    'persian': '优雅高贵，毛发飘逸的波斯猫',
    'ragdoll': '温顺可爱，如布偶般柔软的布偶猫',
    'siamese': '聪明伶俐，善于交流的暹罗猫',
  };

  /// 获取猫咪图片路径
  static String getCatImagePath(String breed) {
    return catBreeds[breed] ?? catBreeds['ragdoll']!; // 默认使用布偶猫
  }

  /// 获取猫咪品种中文名称
  static String getCatBreedName(String breed) {
    return catBreedNames[breed] ?? '未知品种';
  }

  /// 获取猫咪品种描述
  static String getCatBreedDescription(String breed) {
    return catBreedDescriptions[breed] ?? '一只可爱的猫咪';
  }

  /// 获取所有可用的猫咪品种
  static List<String> getAllBreeds() {
    return catBreeds.keys.toList();
  }

  /// 获取随机猫咪品种
  static String getRandomBreed() {
    final breeds = getAllBreeds();
    breeds.shuffle();
    return breeds.first;
  }

  /// 根据心情获取推荐的猫咪品种
  static String getBreedByMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'playful':
      case '顽皮':
        return 'bengal'; // 孟加拉猫适合顽皮心情
      case 'calm':
      case '平静':
        return 'persian'; // 波斯猫适合平静心情
      case 'sleepy':
      case '困倦':
        return 'ragdoll'; // 布偶猫适合困倦心情
      case 'happy':
      case '开心':
        return 'maine_coon'; // 缅因猫适合开心心情
      case 'sad':
      case '伤心':
        return 'siamese'; // 暹罗猫适合需要陪伴的时候
      default:
        return getRandomBreed();
    }
  }

  /// 创建猫咪图片Widget - 带有手绘风格效果
  static Widget buildCatImage({
    required String breed,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool withShadow = true,
    bool withBorder = false,
  }) {
    final imagePath = getCatImagePath(breed);
    
    Widget imageWidget = Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // 如果图片加载失败，显示默认的猫咪emoji
        return Container(
          width: width ?? 100,
          height: height ?? 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              '🐱',
              style: TextStyle(fontSize: 48),
            ),
          ),
        );
      },
    );

    // 添加手绘风格效果
    if (withShadow || withBorder) {
      imageWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: withBorder ? Border.all(
            color: Colors.brown.shade300,
            width: 2,
          ) : null,
          boxShadow: withShadow ? [
            BoxShadow(
              color: Colors.brown.shade200.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(2, 4),
            ),
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: imageWidget,
        ),
      );
    }

    return imageWidget;
  }

  /// 创建猫咪品种选择卡片
  static Widget buildBreedCard({
    required String breed,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.orange.shade300 : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildCatImage(
              breed: breed,
              width: 80,
              height: 80,
              withShadow: false,
            ),
            const SizedBox(height: 8),
            Text(
              getCatBreedName(breed),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.orange.shade700 : Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              getCatBreedDescription(breed),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
