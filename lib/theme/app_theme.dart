import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';




/// 应用主题配置类 - 手绘风格
class AppTheme {

  static const Color primaryColor = Color(0xFF34D399);
  static const Color primaryColorLight = Color(0xFFA7F3D0); // 浅薄荷绿
  static const Color primaryColorDark = Color(0xFF10B981); // 深一点的青绿
  static const Color accentColor = Color(0xFF80BC6B); // 保留原叶绿作强调
  static const Color secondaryColor = Color(0xFFC2D4D6); // 雾蓝灰（次要）


	 
	  static const Color vibrantGreen = Color(0xFF68A530);

 
  static const Color backgroundColor = Color(0xFFF4F8F8); // 极浅雾青白
  static const Color surfaceColor = Color(0xFFFCFEFD); // 近白
  static const Color cardColor = Color(0xFFE6F1EE); // 浅雾青卡片

  
  static const Color textPrimary = Color(0xFF2F3A40); // 墨蓝灰
  static const Color textSecondary = Color(0xFF5B6A73); // 次级墨蓝
  static const Color textHint = Color(0xFF9AA8B1); // 提示灰蓝
  static const Color textColor = Color(0xFF2F3A40); // 主文本颜色（与textPrimary相同）

  
  static const Color successColor = Color(0xFF7FB8A7); // 柔水绿
  static const Color warningColor = Color(0xFFE3C48E); // 柔金杏
  static const Color errorColor = Color(0xFFCE9AA5); // 玫瑰灰
  static const Color infoColor = Color(0xFFA8BBCB); // 雾蓝

  
  static const Color happyColor = Color(0xFFF0EEC8); // 开心 - 淡暖米黄
  static const Color playfulColor = Color(0xFF89A89E); // 顽皮 - 水绿
  static const Color calmColor = Color(0xFFA8BBCB); // 平静 - 雾蓝
  static const Color sleepyColor = Color(0xFFB5B3C5); // 困倦 - 淡紫灰
  static const Color hungryColor = Color(0xFFE7D4C2); // 饥饿 - 奶茶米
  static const Color sadColor = Color(0xFF9FADB8); // 伤心 - 灰蓝

  // 手绘风格阴影配置 - 更柔和、更自然
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: textPrimary.withValues(alpha: 0.10), // 墨蓝灰阴影
          blurRadius: 14,
          offset: const Offset(2, 3),
          spreadRadius: 1,
        ),
        BoxShadow(
          color: accentColor.withValues(alpha: 0.06), // 淡紫灰冷光
          blurRadius: 8,
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


	  // 8pt 栅格化命名（兼容保留原有 spacing 常量）
	  static const double gap8 = 8.0;
	  static const double gap12 = 12.0;

	  // 动效 tokens
	  static const Duration motionShort = Duration(milliseconds: 150);
	  static const Duration motionMedium = Duration(milliseconds: 250);
	  static const Duration motionLong = Duration(milliseconds: 400);
	  static const Curve easeStandard = Curves.easeInOutCubic;
	  static const Curve easeEmphasized = Curves.easeInOut;

	  static const double gap16 = 16.0;
	  static const double gap24 = 24.0;
	  static const double gap32 = 32.0;
	  static const double gap48 = 48.0;

	  // 状态层不透明度（可访问性一致化）
	  static const double opacityHover = 0.08;
	  static const double opacityFocus = 0.12;
	  static const double opacityPressed = 0.12;
	  static const double opacityDragged = 0.16;

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

	  // 通用渐变（参考图：浅雾蓝灰 → 雾青绿）
	  static const LinearGradient mistSkyGradient = LinearGradient(
	    colors: [Color(0xFFF6FFFB), Color(0xFFE9FBF4)],
	    begin: Alignment.topLeft,
	    end: Alignment.bottomRight,
	    stops: [0.1, 1.0],
	  );


		  // 关键 CTA/庆祝渐变（浅叶绿 → 深翠绿）
		  static const LinearGradient fieldGreenGradient = LinearGradient(
		    colors: [Color(0xFF80BC6B), Color(0xFF329363)],
		    begin: Alignment.topLeft,
		    end: Alignment.bottomRight,
		  );


  /// 获取手绘风格的按钮装饰（睡莲渐变）
  static BoxDecoration get handDrawnButton => BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0xFFDDEAE4), // light water green
        Color(0xFF89A89E), // water green
        Color(0xFF4F6F66), // deep pool green
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: [0.0, 0.5, 1.0],
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.35),
        blurRadius: 10,
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


	      // 全局字体（用户指定）
	      fontFamily: 'ZCOOL KuaiLe',

      // 颜色方案（显式覆盖角色，确保与参考配色一致）
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryColorLight,
        onPrimaryContainer: textPrimary,

        secondary: accentColor,
        onSecondary: const Color(0xFF0F1A14),
        secondaryContainer: const Color(0xFFDDEAE4),
        onSecondaryContainer: textPrimary,

        tertiary: primaryColorLight, // 雾青绿
        onTertiary: const Color(0xFF163028),
        tertiaryContainer: const Color(0xFFE8F3F0),
        onTertiaryContainer: textPrimary,

        surface: surfaceColor,
        surfaceTint: primaryColor,
        surfaceContainerHighest: cardColor,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,

        error: errorColor,
        onError: Colors.white,

        outline: const Color(0xFFBFD4CF),
      ),

      // 脚手架主题
      scaffoldBackgroundColor: backgroundColor,

      // AppBar主题
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.zcoolKuaiLe(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: textPrimary,
          size: 24,
        ),
      ),

      // 卡片主题
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
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
          shadowColor: primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          textStyle: GoogleFonts.zcoolKuaiLe(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primaryColor.withValues(alpha: opacityPressed);
            }
            if (states.contains(WidgetState.hovered)) {
              return primaryColor.withValues(alpha: opacityHover);
            }
            if (states.contains(WidgetState.focused)) {
              return primaryColor.withValues(alpha: opacityFocus);
            }
            return null;
          }),
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
          textStyle: GoogleFonts.zcoolKuaiLe(),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primaryColor.withValues(alpha: opacityPressed);
            }
            if (states.contains(WidgetState.hovered)) {
              return primaryColor.withValues(alpha: opacityHover);
            }
            if (states.contains(WidgetState.focused)) {
              return primaryColor.withValues(alpha: opacityFocus);
            }
            return null;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          textStyle: GoogleFonts.zcoolKuaiLe(),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primaryColor.withValues(alpha: opacityPressed);
            }
            if (states.contains(WidgetState.hovered)) {
              return primaryColor.withValues(alpha: opacityHover);
            }
            if (states.contains(WidgetState.focused)) {
              return primaryColor.withValues(alpha: opacityFocus);
            }
            return null;
          }),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F7F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primaryColorLight.withValues(alpha: 0.40)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primaryColorLight.withValues(alpha: 0.40)),
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
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'ZCOOL KuaiLe',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: 'ZCOOL KuaiLe',
        ),
        showUnselectedLabels: true,
      ),

      // NavigationBar 主题（M3 胶囊指示）
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        indicatorColor: primaryColorLight.withValues(alpha: 0.25),
        indicatorShape: StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.zcoolKuaiLe(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? primaryColor : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? primaryColor : textSecondary,
            size: isSelected ? 28 : 24,
          );
        }),
      ),

      // 对话框主题
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: GoogleFonts.zcoolKuaiLe(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.zcoolKuaiLe(
          color: textSecondary,
          fontSize: 16,
        ),
      ),

      // SnackBar主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.zcoolKuaiLe(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // 文本主题（套用 ZCOOL KuaiLe 字体）
      textTheme: GoogleFonts.zcoolKuaiLeTextTheme(const TextTheme(
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
      )),

      // 图标主题
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),

      // 分割线主题
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE3ECEA),
        thickness: 1,
        space: 1,
      ),

      // 芯片主题
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF2F7F6),
        selectedColor: primaryColor.withValues(alpha: 0.20),
        disabledColor: const Color(0xFFE8EFEF),
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
        side: BorderSide(color: primaryColorLight.withValues(alpha: 0.40)),
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
        inactiveTrackColor: primaryColor.withValues(alpha: 0.3),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.2),
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),

      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return Colors.grey.shade300;
        }),
      ),

      // 复选框主题
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // 单选按钮主题
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
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
        selectedTileColor: primaryColor.withValues(alpha: 0.1),
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
