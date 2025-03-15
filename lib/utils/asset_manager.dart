import '../models/cat.dart';

/// 资源管理工具类
class AssetManager {
  // 基础目录
  static const String _baseDir = 'assets/images';
  static const String _catsDir = '$_baseDir/cats';
  static const String _accessoriesDir = '$_baseDir/accessories';
  static const String _backgroundsDir = '$_baseDir/backgrounds';
  static const String _iconsDir = '$_baseDir/icons';

  // 猫咪基础图片路径
  static String getCatBaseImage(CatBreed breed) {
    final breedName = _getBreedName(breed);
    return '$_catsDir/$breedName/base/normal.png';
  }

  // 猫咪心情图片路径
  static String getCatMoodImage(CatBreed breed, CatMoodState mood) {
    final breedName = _getBreedName(breed);
    final moodName = _getMoodName(mood);
    return '$_catsDir/$breedName/mood/$moodName.png';
  }

  // 猫咪动作图片路径
  static String getCatActionImage(CatBreed breed, String action) {
    final breedName = _getBreedName(breed);
    return '$_catsDir/$breedName/action/$action.png';
  }

  // 猫咪动画路径
  static String getCatAnimationPath(CatBreed breed, String animationType) {
    final breedName = _getBreedName(breed);
    return '$_catsDir/$breedName/action/${animationType}_anim.json';
  }

  // 装饰品图片路径
  static String getAccessoryImage(String category, String accessoryId) {
    return '$_accessoriesDir/$category/$accessoryId.png';
  }

  // 背景图片路径
  static String getBackgroundImage(String category, String backgroundId) {
    return '$_backgroundsDir/$category/$backgroundId.png';
  }

  // 图标路径
  static String getIconImage(String category, String iconName) {
    return '$_iconsDir/$category/$iconName.png';
  }

  // 获取品种名称
  static String _getBreedName(CatBreed breed) {
    switch (breed) {
      case CatBreed.persian:
        return 'persian';
      case CatBreed.ragdoll:
        return 'ragdoll';
      case CatBreed.siamese:
        return 'siamese';
      case CatBreed.bengal:
        return 'bengal';
      case CatBreed.maineCoon:
        return 'maine_coon';
      case CatBreed.random:
        return 'random';
    }
  }

  // 获取心情名称
  static String _getMoodName(CatMoodState mood) {
    switch (mood) {
      case CatMoodState.happy:
        return 'happy';
      case CatMoodState.normal:
        return 'normal';
      case CatMoodState.hungry:
        return 'hungry';
      case CatMoodState.tired:
        return 'tired';
      case CatMoodState.bored:
        return 'bored';
    }
  }
} 