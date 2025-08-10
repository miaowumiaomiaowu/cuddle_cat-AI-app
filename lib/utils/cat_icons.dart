import 'package:flutter/material.dart';
import '../models/cat.dart';

/// 猫咪图标工具类
class CatIcons {
  // 基础猫咪图标 SVG 路径
  static const String _baseCatSvgPath = '''
    <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <path d="M50,20 C30,20 20,40 20,60 C20,75 30,85 50,85 C70,85 80,75 80,60 C80,40 70,20 50,20 Z" />
      <circle cx="35" cy="50" r="5" fill="black" />
      <circle cx="65" cy="50" r="5" fill="black" />
      <path d="M20,40 L10,25" stroke="black" stroke-width="2" />
      <path d="M80,40 L90,25" stroke="black" stroke-width="2" />
      <path d="M43,60 Q50,65 57,60" stroke="black" stroke-width="2" fill="none" />
      <path d="M60,40 Q50,35 40,40" fill="pink" opacity="0.5" />
    </svg>
  ''';

  // 不同猫咪品种的颜色
  static Color getBreedBaseColor(CatBreed breed) {
    switch (breed) {
      case CatBreed.persian:
        return Colors.white;
      case CatBreed.ragdoll:
        return Colors.grey.shade200;
      case CatBreed.siamese:
        return const Color(0xFFE0C9A6);
      case CatBreed.bengal:
        return const Color(0xFFD8A35D);
      case CatBreed.maineCoon:
        return const Color(0xFF8D7E6A);
      case CatBreed.random:
        return Colors.grey.shade300;
    }
  }

  // 不同猫咪品种的点缀颜色
  static Color getBreedAccentColor(CatBreed breed) {
    switch (breed) {
      case CatBreed.persian:
        return Colors.amber.shade100;
      case CatBreed.ragdoll:
        return Colors.blueGrey;
      case CatBreed.siamese:
        return Colors.brown.shade700;
      case CatBreed.bengal:
        return Colors.brown;
      case CatBreed.maineCoon:
        return Colors.brown.shade900;
      case CatBreed.random:
        return Colors.black;
    }
  }

  // 基础猫咪 SVG 字符串（带颜色）
  static String getCatSvgString(
    CatBreed breed, {
    CatMoodState? mood,
    Map<String, String>? accessories,
  }) {
    final baseColor = getBreedBaseColor(breed);
    // final accentColor = getBreedAccentColor(breed); // TODO: Use accent color in future

    String moodPath = '';

    // 根据心情添加不同的表情
    if (mood != null) {
      switch (mood) {
        case CatMoodState.happy:
          moodPath =
              '<path d="M43,60 Q50,70 57,60" stroke="black" stroke-width="2" fill="none" />';
          break;
        case CatMoodState.normal:
          moodPath =
              '<path d="M43,60 Q50,65 57,60" stroke="black" stroke-width="2" fill="none" />';
          break;
        case CatMoodState.hungry:
          moodPath =
              '<path d="M43,65 Q50,60 57,65" stroke="black" stroke-width="2" fill="none" />';
          break;
        case CatMoodState.tired:
          moodPath =
              '<path d="M40,60 L60,60" stroke="black" stroke-width="2" />';
          break;
        case CatMoodState.bored:
          moodPath =
              '<path d="M43,63 Q50,60 57,63" stroke="black" stroke-width="2" fill="none" />';
          break;
      }
    }

    // 添加装饰品
    String accessoriesPath = '';
    if (accessories != null && accessories.isNotEmpty) {
      accessoriesPath = _getAccessoriesPath(accessories);
    }

    // 替换基础SVG中的颜色和表情
    String result = _baseCatSvgPath
        .replaceFirst(
            '<path d="M43,60 Q50,65 57,60" stroke="black" stroke-width="2" fill="none" />',
            moodPath)
        .replaceFirst(
            '<path d="M50,20 C30,20 20,40 20,60 C20,75 30,85 50,85 C70,85 80,75 80,60 C80,40 70,20 50,20 Z" />',
            '<path d="M50,20 C30,20 20,40 20,60 C20,75 30,85 50,85 C70,85 80,75 80,60 C80,40 70,20 50,20 Z" fill="${_colorToHex(baseColor)}" />');

    // 在SVG结束标签前插入装饰品路径
    result = result.replaceFirst('</svg>', '$accessoriesPath</svg>');

    return result;
  }

  // 将Color转换为16进制字符串
  static String _colorToHex(Color color) {
    return '#${(color.a.toInt() << 24 | color.r.toInt() << 16 | color.g.toInt() << 8 | color.b.toInt()).toRadixString(16).substring(2)}';
  }

  // 根据装饰品ID获取SVG路径
  static String _getAccessoriesPath(Map<String, String> accessories) {
    StringBuffer paths = StringBuffer();

    accessories.forEach((type, id) {
      switch (type) {
        case 'AccessoryType.hat':
          paths.write(_getHatPath(id));
          break;
        case 'AccessoryType.collar':
          paths.write(_getCollarPath(id));
          break;
        case 'AccessoryType.glasses':
          paths.write(_getGlassesPath(id));
          break;
        case 'AccessoryType.costume':
          paths.write(_getCostumePath(id));
          break;
        case 'AccessoryType.background':
          paths.write(_getBackgroundPath(id));
          break;
      }
    });

    return paths.toString();
  }

  // 帽子SVG路径
  static String _getHatPath(String id) {
    switch (id) {
      case 'hat_crown':
        return '''
          <path d="M50,10 L40,20 L30,10 L40,5 L50,10 L60,5 L70,10 L60,20 Z" fill="gold" stroke="black" stroke-width="0.5" />
          <circle cx="50" cy="8" r="2" fill="red" />
        ''';
      case 'hat_wizard':
        return '''
          <path d="M50,5 L30,25 L70,25 Z" fill="darkblue" stroke="black" stroke-width="0.5" />
          <circle cx="50" cy="15" r="2" fill="yellow" />
          <circle cx="45" cy="20" r="1" fill="yellow" />
          <circle cx="55" cy="20" r="1" fill="yellow" />
        ''';
      case 'hat_cap':
        return '''
          <path d="M30,25 Q50,15 70,25 L65,32 Q50,25 35,32 Z" fill="red" stroke="black" stroke-width="0.5" />
          <path d="M40,25 L60,25 L55,20 L45,20 Z" fill="red" stroke="black" stroke-width="0.5" />
        ''';
      default:
        return '';
    }
  }

  // 项圈SVG路径
  static String _getCollarPath(String id) {
    switch (id) {
      case 'collar_bow':
        return '''
          <path d="M30,40 Q50,45 70,40" stroke="red" stroke-width="3" fill="none" />
          <path d="M46,40 L54,40 L50,45 Z" fill="red" stroke="black" stroke-width="0.5" />
          <path d="M48,37 L52,37 L50,42 Z" fill="red" stroke="black" stroke-width="0.5" />
        ''';
      case 'collar_bell':
        return '''
          <path d="M30,40 Q50,45 70,40" stroke="blue" stroke-width="3" fill="none" />
          <circle cx="50" cy="45" r="3" fill="gold" stroke="black" stroke-width="0.5" />
          <line x1="50" y1="48" x2="50" y2="50" stroke="black" stroke-width="1" />
        ''';
      default:
        return '';
    }
  }

  // 眼镜SVG路径
  static String _getGlassesPath(String id) {
    switch (id) {
      case 'glasses_sunglasses':
        return '''
          <path d="M35,45 L65,45" stroke="black" stroke-width="1" />
          <circle cx="35" cy="50" r="8" fill="black" opacity="0.7" />
          <circle cx="65" cy="50" r="8" fill="black" opacity="0.7" />
        ''';
      case 'glasses_reading':
        return '''
          <path d="M35,45 L65,45" stroke="brown" stroke-width="1" />
          <circle cx="35" cy="50" r="7" fill="none" stroke="brown" stroke-width="1" />
          <circle cx="65" cy="50" r="7" fill="none" stroke="brown" stroke-width="1" />
        ''';
      default:
        return '';
    }
  }

  // 服装SVG路径
  static String _getCostumePath(String id) {
    switch (id) {
      case 'costume_cape':
        return '''
          <path d="M50,40 L30,80 L70,80 Z" fill="red" opacity="0.8" />
          <path d="M30,40 L40,43 L50,40 L60,43 L70,40" stroke="gold" stroke-width="1" fill="none" />
        ''';
      case 'costume_sweater':
        return '''
          <path d="M30,40 Q50,45 70,40 L65,70 Q50,75 35,70 Z" fill="lightblue" opacity="0.8" stroke="white" stroke-width="0.5" />
          <path d="M40,45 L45,60 M60,45 L55,60" stroke="white" stroke-width="1" />
        ''';
      default:
        return '';
    }
  }

  // 背景SVG路径
  static String _getBackgroundPath(String id) {
    switch (id) {
      case 'background_space':
        return '''
          <rect x="0" y="0" width="100" height="100" fill="navy" opacity="0.3" />
          <circle cx="20" cy="20" r="1" fill="white" />
          <circle cx="30" cy="10" r="0.8" fill="white" />
          <circle cx="70" cy="15" r="1.2" fill="white" />
          <circle cx="80" cy="30" r="0.6" fill="white" />
          <circle cx="15" cy="70" r="1.5" fill="white" />
          <circle cx="90" cy="80" r="1" fill="white" />
          <circle cx="40" cy="85" r="0.7" fill="white" />
        ''';
      case 'background_beach':
        return '''
          <rect x="0" y="60" width="100" height="40" fill="sandybrown" opacity="0.5" />
          <rect x="0" y="0" width="100" height="60" fill="skyblue" opacity="0.3" />
          <circle cx="80" cy="15" r="10" fill="yellow" opacity="0.7" />
        ''';
      default:
        return '';
    }
  }
}
