import 'package:flutter/material.dart';


/// 艺术感UI主题配置类 - 参考现代优秀设计
class ArtisticTheme {
  // 莫兰迪艺术色系 - 更精致的配色
  static const Color primaryColor = Color(0xFFD4A574); // 暖米色
  static const Color primaryColorLight = Color(0xFFE8C4A0); // 浅暖米色
  static const Color primaryColorDark = Color(0xFFB8956A); // 深暖米色
  static const Color accentColor = Color(0xFF9ABEAA); // 薄荷绿

  // 艺术背景色系
  static const Color backgroundColor = Color(0xFFF8F5F0); // 艺术纸张色
  static const Color surfaceColor = Color(0xFFFCFAF7); // 画布色
  static const Color cardColor = Color(0xFFF2EFE8); // 卡片色

  // 艺术文字色系
  static const Color textPrimary = Color(0xFF3D3530); // 深墨色
  static const Color textSecondary = Color(0xFF6B5D52); // 中墨色
  static const Color textHint = Color(0xFF9B8B7D); // 浅墨色
  static const Color textAccent = Color(0xFF8B7355); // 强调色

  // 情感色彩 - 艺术化
  static const Color joyColor = Color(0xFFE8C4A0); // 喜悦 - 温暖金
  static const Color calmColor = Color(0xFF9BB0C1); // 平静 - 雾蓝
  static const Color energyColor = Color(0xFF9ABEAA); // 活力 - 薄荷绿
  static const Color restColor = Color(0xFFB5A490); // 休息 - 暖灰
  static const Color loveColor = Color(0xFFCB9CA1); // 爱意 - 玫瑰灰
  static const Color playColor = Color(0xFFD4B896); // 玩耍 - 沙金

  // 艺术渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8C4A0),
      Color(0xFFD4A574),
      Color(0xFFB8956A),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB8D4C6),
      Color(0xFF9ABEAA),
      Color(0xFF7FA08F),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFCFAF7),
      Color(0xFFF8F5F0),
      Color(0xFFF2EFE8),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  // 艺术阴影系统
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.04),
      blurRadius: 40,
      offset: const Offset(0, 16),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.03),
      blurRadius: 32,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.06),
      blurRadius: 48,
      offset: const Offset(0, 24),
      spreadRadius: 0,
    ),
  ];

  // 艺术圆角系统
  static const double radiusXSmall = 8.0;
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;
  static const double radiusXXLarge = 40.0;

  // 艺术间距系统
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // 艺术字体系统 - 参考现代设计
  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w300, // Light weight for elegance
    letterSpacing: -0.5,
    height: 1.1,
    color: textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.25,
    height: 1.2,
    color: textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.3,
    color: textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.3,
    color: textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.4,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.5,
    color: textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: textAccent,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
    color: textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.3,
    color: textHint,
  );

  // 添加缺失的文本样式
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.4,
    color: textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.3,
    color: textSecondary,
  );

  // 添加缺失的颜色
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // 添加 lightTheme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      primaryColor: primaryColor,
      textTheme: const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
    );
  }

  /// 获取心情颜色 - 艺术化
  static Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case '开心':
        return joyColor;
      case 'playful':
      case '顽皮':
        return playColor;
      case 'calm':
      case 'normal':
      case '平静':
      case '正常':
        return calmColor;
      case 'sleepy':
      case 'tired':
      case '困倦':
      case '疲惫':
        return restColor;
      case 'hungry':
      case '饥饿':
        return energyColor;
      case 'sad':
      case '伤心':
        return loveColor;
      case 'bored':
      case '无聊':
        return restColor;
      default:
        return calmColor;
    }
  }

  /// 艺术装饰方法
  static BoxDecoration get artisticCard => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        surfaceColor,
        cardColor,
      ],
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: cardShadow,
    border: Border.all(
      color: primaryColor.withValues(alpha: 0.1),
      width: 1,
    ),
  );

  static BoxDecoration get artisticButton => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: softShadow,
  );

  static BoxDecoration get glassEffect => BoxDecoration(
    color: surfaceColor.withValues(alpha: 0.8),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: primaryColor.withValues(alpha: 0.2),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.2),
        blurRadius: 10,
        offset: const Offset(-5, -5),
      ),
      BoxShadow(
        color: textPrimary.withValues(alpha: 0.1),
        blurRadius: 10,
        offset: const Offset(5, 5),
      ),
    ],
  );
}
