import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 应用主题配置类 - 手绘风格
class AppTheme {
  // 莫兰迪色系主色调配置 - 手绘彩铅风格
  static const Color primaryColor = Color(0xFFD4A574); // 暖米色
  static const Color primaryColorLight = Color(0xFFE8C4A0); // 浅暖米色
  static const Color primaryColorDark = Color(0xFFB8956A); // 深暖米色
  static const Color accentColor = Color(0xFF9ABEAA); // 薄荷绿
  static const Color secondaryColor = Color(0xFF9ABEAA); // 次要颜色（薄荷绿）

  // 莫兰迪色系背景色配置
  static const Color backgroundColor = Color(0xFFF5F1EB); // 奶白色
  static const Color surfaceColor = Color(0xFFFAF7F2); // 浅奶白色
  static const Color cardColor = Color(0xFFEFEAE2); // 卡片背景

  // 莫兰迪色系文本色配置
  static const Color textPrimary = Color(0xFF5D4E37); // 深棕色
  static const Color textSecondary = Color(0xFF8B7355); // 中棕色
  static const Color textHint = Color(0xFFB5A490); // 浅棕色
  static const Color textColor = Color(0xFF5D4E37); // 主文本颜色（与textPrimary相同）

  // 莫兰迪色系功能色配置
  static const Color successColor = Color(0xFF8FA68E); // 柔和绿
  static const Color warningColor = Color(0xFFD4B896); // 柔和橙
  static const Color errorColor = Color(0xFFCB9CA1); // 柔和红
  static const Color infoColor = Color(0xFF9BB0C1); // 柔和蓝

  // 猫咪心情莫兰迪色系
  static const Color happyColor = Color(0xFFE8C4A0); // 开心 - 温暖米色
  static const Color playfulColor = Color(0xFF9ABEAA); // 顽皮 - 薄荷绿
  static const Color calmColor = Color(0xFF9BB0C1); // 平静 - 柔和蓝
  static const Color sleepyColor = Color(0xFFB5A490); // 困倦 - 浅棕色
  static const Color hungryColor = Color(0xFFD4B896); // 饥饿 - 柔和橙
  static const Color sadColor = Color(0xFFCB9CA1); // 伤心 - 柔和红

  // 手绘风格阴影配置 - 更柔和、更自然
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF8B7355).withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(2, 3),
          spreadRadius: 1,
        ),
        BoxShadow(
          color: const Color(0xFFFFB74D).withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(-1, -1),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF8B7355).withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(3, 5),
          spreadRadius: 2,
        ),
        BoxShadow(
          color: const Color(0xFFFFB74D).withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(-2, -2),
        ),
      ];

  // 手绘风格圆角配置 - 更有机、不规则的感觉
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 18.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  // 手绘风格间距配置 - 更宽松、更舒适
  static const double spacingXSmall = 6.0;
  static const double spacingSmall = 12.0;
  static const double spacingMedium = 20.0;
  static const double spacingLarge = 32.0;
  static const double spacingXLarge = 48.0;

  // 手绘风格装饰方法
  /// 获取手绘风格的边框装饰
  static BoxDecoration get handDrawnBorder => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(
      color: primaryColor.withValues(alpha: 0.3),
      width: 2,
    ),
    boxShadow: cardShadow,
  );

  /// 获取手绘风格的按钮装饰
  static BoxDecoration get handDrawnButton => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        primaryColor,
        primaryColorDark,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.4),
        blurRadius: 8,
        offset: const Offset(2, 4),
      ),
    ],
  );

  /// 获取手绘风格的卡片装饰
  static BoxDecoration get handDrawnCard => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: textSecondary.withValues(alpha: 0.2),
      width: 1.5,
    ),
    boxShadow: cardShadow,
  );

  /// 获取主题数据
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // 颜色方案
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        // background: backgroundColor, // deprecated, using surface instead
        error: errorColor,
      ),

      // 脚手架主题
      scaffoldBackgroundColor: backgroundColor,

      // AppBar主题
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: textPrimary,
          size: 24,
        ),
      ),

      // 卡片主题
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
        hintStyle: TextStyle(color: textHint),
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // 对话框主题
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: textSecondary,
          fontSize: 16,
        ),
      ),

      // SnackBar主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // 文本主题
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textHint,
          height: 1.4,
        ),
      ),

      // 图标主题
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),

      // 分割线主题
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),

      // 芯片主题
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: primaryColor.withOpacity(0.2),
        disabledColor: Colors.grey.shade200,
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 12,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primaryColor,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // 进度指示器主题
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Colors.grey,
        circularTrackColor: Colors.grey,
      ),

      // 滑块主题
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.3),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),

      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.shade300;
        }),
      ),

      // 复选框主题
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // 单选按钮主题
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade400;
        }),
      ),

      // 浮动操作按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // 标签栏主题
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),

      // 列表瓦片主题
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: primaryColor.withOpacity(0.1),
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
    );
  }

  /// 获取情感颜色
  static Color getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case '开心':
        return const Color(0xFFFFD700); // 金色
      case 'sad':
      case '难过':
        return const Color(0xFF87CEEB); // 天蓝色
      case 'angry':
      case '生气':
        return const Color(0xFFFF6B6B); // 红色
      case 'anxious':
      case '焦虑':
        return const Color(0xFFFF8C42); // 橙色
      case 'confused':
      case '困惑':
        return const Color(0xFFB19CD9); // 紫色
      case 'surprised':
      case '惊讶':
        return const Color(0xFFFF69B4); // 粉色
      case 'loving':
      case '关爱':
        return const Color(0xFFFF1493); // 深粉色
      case 'excited':
      case '兴奋':
        return const Color(0xFFFF4500); // 橙红色
      case 'relaxed':
      case '放松':
        return const Color(0xFF98FB98); // 浅绿色
      case 'romantic':
      case '浪漫':
        return const Color(0xFFDDA0DD); // 梅花色
      case 'tired':
      case '疲惫':
        return const Color(0xFF708090); // 石板灰
      case 'bored':
      case '无聊':
        return const Color(0xFFA9A9A9); // 深灰色
      default:
        return textSecondary;
    }
  }

  /// 获取心情颜色 - 莫兰迪色系
  static Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case '开心':
        return happyColor;
      case 'playful':
      case '顽皮':
        return playfulColor;
      case 'calm':
      case 'normal':
      case '平静':
      case '正常':
        return calmColor;
      case 'sleepy':
      case 'tired':
      case '困倦':
      case '疲惫':
        return sleepyColor;
      case 'hungry':
      case '饥饿':
        return hungryColor;
      case 'sad':
      case '伤心':
        return sadColor;
      case 'bored':
      case '无聊':
        return sleepyColor; // 使用困倦色
      default:
        return calmColor; // 默认使用平静色
    }
  }
}
