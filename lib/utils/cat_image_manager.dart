import 'package:flutter/material.dart';
import '../models/cat.dart';

/// 猫咪图片管理器 - 管理不同品种与性格的猫咪图片
class CatImageManager {
  // 品种 → 图片
  static const Map<String, String> catBreeds = {
    'bengal': 'assets/base/cat_bengal_idle.png',
    'maine_coon': 'assets/base/cat_maine_coon_idle.png',
    'persian': 'assets/base/cat_persian_idle.png',
    'ragdoll': 'assets/base/cat_ragdoll_idle.png',
    'siamese': 'assets/base/cat_siamese_idle.png',
  };

  // 品种中文名
  static const Map<String, String> catBreedNames = {
    'bengal': '孟加拉猫',
    'maine_coon': '缅因猫',
    'persian': '波斯猫',
    'ragdoll': '布偶猫',
    'siamese': '暹罗猫',
  };

  // 品种描述
  static const Map<String, String> catBreedDescriptions = {
    'bengal': '活泼好动，充满野性魅力的孟加拉猫',
    'maine_coon': '温和友善，体型庞大的缅因猫',
    'persian': '优雅高贵，毛发飘逸的波斯猫',
    'ragdoll': '温顺可爱，如布偶般柔软的布偶猫',
    'siamese': '聪明伶俐，善于交流的暹罗猫',
  };

  // 性格 → 图片（现阶段复用现有品种图片作为风格代表，可随资源替换）
  static const Map<CatPersonality, String> personaImages = {
    CatPersonality.playful: 'assets/base/cat_ragdoll_idle.png',      // 阳光/可爱
    CatPersonality.social: 'assets/base/cat_bengal_idle.png',        // 搞笑/外向
    CatPersonality.independent: 'assets/base/cat_siamese_idle.png',  // 严谨/独立（对应“严厉”风格）
    CatPersonality.calm: 'assets/base/cat_maine_coon_idle.png',      // 温暖/温柔
    CatPersonality.curious: 'assets/base/cat_siamese_idle.png',      // 理性/严谨
    CatPersonality.lazy: 'assets/base/cat_persian_idle.png',         // 文艺/慵懒
  };

  /// 获取猫咪图片路径（按品种）
  static String getCatImagePath(String breed) {
    return catBreeds[breed] ?? catBreeds['ragdoll']!; // 默认布偶猫
  }

  /// 获取性格代表图片路径
  static String getPersonaImagePath(CatPersonality p) {
    return personaImages[p] ?? catBreeds['ragdoll']!;
  }

  /// 品种中文名
  static String getCatBreedName(String breed) => catBreedNames[breed] ?? '未知品种';

  /// 品种描述
  static String getCatBreedDescription(String breed) => catBreedDescriptions[breed] ?? '一只可爱的猫咪';

  /// 所有品种 key
  static List<String> getAllBreeds() => catBreeds.keys.toList();

  /// 随机品种
  static String getRandomBreed() {
    final breeds = getAllBreeds();
    breeds.shuffle();
    return breeds.first;
  }

  /// 根据心情推荐品种
  static String getBreedByMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'playful':
      case '顽皮':
        return 'bengal';
      case 'calm':
      case '平静':
        return 'persian';
      case 'sleepy':
      case '困倦':
        return 'ragdoll';
      case 'happy':
      case '开心':
        return 'maine_coon';
      case 'sad':
      case '伤心':
        return 'siamese';
      default:
        return getRandomBreed();
    }
  }

  /// 手绘风格图片组件
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
        return Container(
          width: width ?? 100,
          height: height ?? 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('🐱', style: TextStyle(fontSize: 48))),
        );
      },
    );

    if (withShadow || withBorder) {
      imageWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: withBorder ? Border.all(color: Colors.brown.shade300, width: 2) : null,
          boxShadow: withShadow
              ? [BoxShadow(color: Colors.brown.shade200.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(2, 4))]
              : null,
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(14), child: imageWidget),
      );
    }

    return imageWidget;
  }

  /// 品种选择卡片
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
          border: Border.all(color: isSelected ? Colors.orange.shade300 : Colors.grey.shade300, width: 2),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          buildCatImage(breed: breed, width: 80, height: 80, withShadow: false),
          const SizedBox(height: 8),
          Text(getCatBreedName(breed), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? Colors.orange.shade700 : Colors.brown.shade700)),
          const SizedBox(height: 4),
          Text(getCatBreedDescription(breed), style: TextStyle(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  /// 性格选择卡片
  static Widget buildPersonalityCard({
    required CatPersonality personality,
    required String title,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final img = getPersonaImagePath(personality);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.orange.shade300 : Colors.grey.shade300, width: 2),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(img, width: 80, height: 80, fit: BoxFit.cover)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.brown.shade700)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
