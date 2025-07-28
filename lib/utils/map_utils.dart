import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import '../models/travel.dart';

/// 地图工具类
///
/// 临时版本：禁用了实际的高德地图API调用，返回模拟数据
class MapUtils {
  // static final LocationPluginWrapper _locationPlugin = LocationPluginWrapper();
  // static StreamSubscription<Map<String, Object>>? _locationListener;

  /// 获取当前位置
  ///
  /// 注意：此为临时实现，返回固定位置
  static Future<LatLng?> getCurrentLocation() async {
    try {
      // 模拟定位，返回北京位置
      await Future.delayed(const Duration(seconds: 2)); // 模拟网络延迟
      return const LatLng(39.9054, 116.3976); // 北京位置
    } catch (e) {
      debugPrint('获取位置失败: $e');
      return null;
    }
  }

  /// 计算两点之间的距离（以公里为单位）
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // 地球半径（单位：公里）

    // 将经纬度转换为弧度
    final lat1 = _degreesToRadians(point1.latitude);
    final lon1 = _degreesToRadians(point1.longitude);
    final lat2 = _degreesToRadians(point2.latitude);
    final lon2 = _degreesToRadians(point2.longitude);

    // 半正矢公式计算
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// 获取地图缩放级别
  static double getZoomLevel(double distance) {
    if (distance < 100) return 18;
    if (distance < 500) return 16;
    if (distance < 1000) return 14;
    if (distance < 5000) return 12;
    if (distance < 10000) return 10;
    if (distance < 50000) return 8;
    if (distance < 100000) return 6;
    return 4;
  }

  /// 将角度转换为弧度
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
