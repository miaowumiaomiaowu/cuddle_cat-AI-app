import 'package:flutter/material.dart';

/// 颜色工具类 - 处理不同Flutter版本的API兼容性
class ColorUtils {
  /// 安全的透明度设置方法
  /// 兼容不同Flutter版本的withOpacity/withValues API
  static Color withAlpha(Color color, double alpha) {
    // 使用 withOpacity 方法，兼容当前Flutter版本
    return color.withValues(alpha: alpha);
  }
  
  /// 创建带透明度的颜色
  static Color createWithAlpha(int red, int green, int blue, double alpha) {
    return Color.fromRGBO(red, green, blue, alpha);
  }
  
  /// 从十六进制创建带透明度的颜色
  static Color fromHexWithAlpha(String hex, double alpha) {
    final color = Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
    return color.withValues(alpha: alpha);
  }
}
