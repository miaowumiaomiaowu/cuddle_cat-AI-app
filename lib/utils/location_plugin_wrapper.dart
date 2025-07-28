import 'package:flutter/foundation.dart';
import 'dart:async';

/// 定位插件包装器 (临时禁用版本)
/// 原本用于解决 amap_flutter_location 3.0.0 API 不一致的问题
/// 当前版本已禁用实际定位功能，返回模拟数据
class LocationPluginWrapper {
  /// 获取位置变化的流 (模拟版本)
  Stream<Map<String, Object>> onLocationChanged() {
    // 返回一个模拟的位置流
    return Stream.periodic(const Duration(seconds: 5), (count) {
      return <String, Object>{
        'latitude': 39.9054 + (count * 0.001), // 模拟位置变化
        'longitude': 116.3976 + (count * 0.001),
        'accuracy': 10.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    });
  }

  /// 设置定位参数 (模拟版本)
  void setLocationOption(Map<String, Object> options) {
    try {
      debugPrint('模拟设置定位参数: $options');
    } catch (e) {
      debugPrint('设置定位参数失败: $e');
    }
  }

  /// 开始定位 (模拟版本)
  void startLocation() {
    debugPrint('模拟开始定位');
  }

  /// 停止定位 (模拟版本)
  void stopLocation() {
    debugPrint('模拟停止定位');
  }

  /// 销毁定位 (模拟版本)
  void dispose() {
    debugPrint('模拟销毁定位');
  }
}
