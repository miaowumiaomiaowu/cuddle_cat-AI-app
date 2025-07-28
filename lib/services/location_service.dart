import 'package:flutter/foundation.dart';
import '../models/travel.dart';
import 'dart:math' as dart_math;

/// 位置信息类
class LocationInfo {
  final LatLng coordinates;
  final String name;
  final String address;
  final String? city;
  final String? province;
  final String? country;

  LocationInfo({
    required this.coordinates,
    required this.name,
    required this.address,
    this.city,
    this.province,
    this.country,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      coordinates: LatLng(json['latitude'], json['longitude']),
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'],
      province: json['province'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'name': name,
      'address': address,
      'city': city,
      'province': province,
      'country': country,
    };
  }
}

/// 位置建议类
class LocationSuggestion {
  final String name;
  final String address;
  final LatLng coordinates;
  final String type; // 'poi', 'address', 'city' etc.

  LocationSuggestion({
    required this.name,
    required this.address,
    required this.coordinates,
    required this.type,
  });
}

/// 位置服务类
class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  LocationService._internal();

  /// 获取当前位置（模拟实现）
  Future<LocationInfo?> getCurrentLocation() async {
    try {
      // 模拟网络延迟
      await Future.delayed(const Duration(seconds: 1));

      // 返回模拟的北京位置信息
      return LocationInfo(
        coordinates: const LatLng(39.9054, 116.3976),
        name: '天安门广场',
        address: '北京市东城区天安门广场',
        city: '北京市',
        province: '北京市',
        country: '中国',
      );
    } catch (e) {
      debugPrint('获取当前位置失败: $e');
      return null;
    }
  }

  /// 搜索位置建议
  Future<List<LocationSuggestion>> searchLocationSuggestions(
      String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // 模拟搜索延迟
      await Future.delayed(const Duration(milliseconds: 500));

      // 返回模拟的搜索结果
      final List<LocationSuggestion> suggestions = [];

      // 根据查询内容返回不同的模拟结果
      if (query.contains('北京') || query.contains('beijing')) {
        suggestions.addAll([
          LocationSuggestion(
            name: '天安门广场',
            address: '北京市东城区天安门广场',
            coordinates: const LatLng(39.9054, 116.3976),
            type: 'poi',
          ),
          LocationSuggestion(
            name: '故宫博物院',
            address: '北京市东城区景山前街4号',
            coordinates: const LatLng(39.9163, 116.3972),
            type: 'poi',
          ),
          LocationSuggestion(
            name: '北京大学',
            address: '北京市海淀区颐和园路5号',
            coordinates: const LatLng(39.9990, 116.3059),
            type: 'poi',
          ),
        ]);
      } else if (query.contains('上海') || query.contains('shanghai')) {
        suggestions.addAll([
          LocationSuggestion(
            name: '外滩',
            address: '上海市黄浦区中山东一路',
            coordinates: const LatLng(31.2397, 121.4912),
            type: 'poi',
          ),
          LocationSuggestion(
            name: '东方明珠',
            address: '上海市浦东新区世纪大道1号',
            coordinates: const LatLng(31.2397, 121.4999),
            type: 'poi',
          ),
        ]);
      } else if (query.contains('广州') || query.contains('guangzhou')) {
        suggestions.addAll([
          LocationSuggestion(
            name: '广州塔',
            address: '广州市海珠区阅江西路222号',
            coordinates: const LatLng(23.1056, 113.3249),
            type: 'poi',
          ),
        ]);
      } else {
        // 通用搜索结果
        suggestions.addAll([
          LocationSuggestion(
            name: '$query (模拟地点)',
            address: '$query 的模拟地址',
            coordinates: LatLng(39.9054 + (query.hashCode % 100) * 0.01,
                116.3976 + (query.hashCode % 100) * 0.01),
            type: 'poi',
          ),
        ]);
      }

      return suggestions;
    } catch (e) {
      debugPrint('搜索位置建议失败: $e');
      return [];
    }
  }

  /// 根据坐标获取地址信息（逆地理编码）
  Future<LocationInfo?> getLocationInfoFromCoordinates(
      LatLng coordinates) async {
    try {
      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 800));

      // 根据坐标返回模拟的地址信息
      String name = '未知地点';
      String address = '未知地址';
      String? city;
      String? province;

      // 简单的坐标范围判断来模拟不同城市
      if (coordinates.latitude >= 39.4 &&
          coordinates.latitude <= 41.0 &&
          coordinates.longitude >= 115.4 &&
          coordinates.longitude <= 117.5) {
        // 北京范围
        name = '北京地点';
        address = '北京市某区某街道';
        city = '北京市';
        province = '北京市';
      } else if (coordinates.latitude >= 31.0 &&
          coordinates.latitude <= 31.5 &&
          coordinates.longitude >= 121.0 &&
          coordinates.longitude <= 122.0) {
        // 上海范围
        name = '上海地点';
        address = '上海市某区某街道';
        city = '上海市';
        province = '上海市';
      } else {
        // 其他地区
        name =
            '地点 (${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)})';
        address =
            '坐标: ${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}';
      }

      return LocationInfo(
        coordinates: coordinates,
        name: name,
        address: address,
        city: city,
        province: province,
        country: '中国',
      );
    } catch (e) {
      debugPrint('获取地址信息失败: $e');
      return null;
    }
  }

  /// 获取热门地点推荐
  Future<List<LocationSuggestion>> getPopularLocations() async {
    try {
      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 300));

      return [
        LocationSuggestion(
          name: '天安门广场',
          address: '北京市东城区天安门广场',
          coordinates: const LatLng(39.9054, 116.3976),
          type: 'poi',
        ),
        LocationSuggestion(
          name: '外滩',
          address: '上海市黄浦区中山东一路',
          coordinates: const LatLng(31.2397, 121.4912),
          type: 'poi',
        ),
        LocationSuggestion(
          name: '广州塔',
          address: '广州市海珠区阅江西路222号',
          coordinates: const LatLng(23.1056, 113.3249),
          type: 'poi',
        ),
        LocationSuggestion(
          name: '西湖',
          address: '浙江省杭州市西湖区',
          coordinates: const LatLng(30.2741, 120.1551),
          type: 'poi',
        ),
        LocationSuggestion(
          name: '大雁塔',
          address: '陕西省西安市雁塔区',
          coordinates: const LatLng(34.2186, 108.9647),
          type: 'poi',
        ),
      ];
    } catch (e) {
      debugPrint('获取热门地点失败: $e');
      return [];
    }
  }

  /// 验证坐标是否有效
  bool isValidCoordinates(LatLng coordinates) {
    return coordinates.latitude >= -90 &&
        coordinates.latitude <= 90 &&
        coordinates.longitude >= -180 &&
        coordinates.longitude <= 180;
  }

  /// 计算两点之间的距离（公里）
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // 地球半径（公里）

    final double lat1Rad = point1.latitude * (3.14159 / 180);
    final double lat2Rad = point2.latitude * (3.14159 / 180);
    final double deltaLatRad =
        (point2.latitude - point1.latitude) * (3.14159 / 180);
    final double deltaLngRad =
        (point2.longitude - point1.longitude) * (3.14159 / 180);

    final double a = (deltaLatRad / 2).sin() * (deltaLatRad / 2).sin() +
        lat1Rad.cos() *
            lat2Rad.cos() *
            (deltaLngRad / 2).sin() *
            (deltaLngRad / 2).sin();
    final double c = 2 * (a.sqrt()).atan2((1 - a).sqrt());

    return earthRadius * c;
  }
}

/// 扩展 sin, cos, atan2, sqrt 方法
extension MathExtensions on double {
  double sin() => dart_math.sin(this);
  double cos() => dart_math.cos(this);
  double atan2(double x) => dart_math.atan2(this, x);
  double sqrt() => dart_math.sqrt(this);
}
