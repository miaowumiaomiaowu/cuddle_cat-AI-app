import 'dart:async';
import 'package:geolocator/geolocator.dart';




/// 增强的定位服务类 - 支持心情地图和位置追踪
class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  // 私有字段
  StreamSubscription<Position>? _positionStream;
  Position? _lastKnownPosition;
  final List<LocationListener> _listeners = [];

  // 高德地图相关功能已移除

  LocationService._();

  // 添加公共构造函数以支持直接实例化
  LocationService();

  /// 检查位置权限
  Future<bool> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      print('检查位置权限失败: $e');
      return false;
    }
  }

  /// 初始化定位服务
  Future<void> initialize() async {
    // 网络请求已在构造函数中初始化
  }

  /// 获取当前位置
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      if (!await checkLocationPermission()) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      print('获取当前位置失败: $e');
      return null;
    }
  }

  // 旅行相关的位置信息功能已移除

  /// 搜索周边POI
  Future<List<PoiInfo>> searchNearbyPoi({
    required double latitude,
    required double longitude,
    String keywords = '',
    int radius = 1000,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // 简化实现，返回模拟数据
      return [
        PoiInfo(
          id: '1',
          name: '$keywords 附近',
          address: '模拟地址',
          latitude: latitude,
          longitude: longitude,
          category: '其他',
        ),
      ];
    } catch (e) {
      print('搜索POI失败: $e');
      return [];
    }
  }

  /// 开始位置监听
  Future<void> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) async {
    try {
      if (!await checkLocationPermission()) {
        throw Exception('位置权限未授予');
      }

      await stopLocationTracking();

      final locationSettings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastKnownPosition = position;
          _notifyListeners(position);
        },
        onError: (error) {
          print('位置监听错误: $error');
        },
      );
    } catch (e) {
      print('启动位置跟踪失败: $e');
      rethrow;
    }
  }

  /// 停止位置监听
  Future<void> stopLocationTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  /// 计算两点之间的距离
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 添加位置监听器
  void addLocationListener(LocationListener listener) {
    _listeners.add(listener);
  }

  /// 移除位置监听器
  void removeLocationListener(LocationListener listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器
  void _notifyListeners(Position position) {
    for (final listener in _listeners) {
      try {
        listener.onLocationUpdate(position);
      } catch (e) {
        print('位置监听器错误: $e');
      }
    }
  }

  /// 获取最后已知位置
  Position? get lastKnownPosition => _lastKnownPosition;

  /// 清理资源
  Future<void> dispose() async {
    await stopLocationTracking();
    _listeners.clear();
    _lastKnownPosition = null;
  }

  /// 检查位置服务是否启用
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 打开位置设置
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// 打开应用设置
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // 位置搜索功能已移除
}



/// POI信息模型
class PoiInfo {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? category;
  final String? phone;
  final double? distance;

  PoiInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.category,
    this.phone,
    this.distance,
  });

  factory PoiInfo.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as String;
    final coordinates = location.split(',');

    return PoiInfo(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: double.parse(coordinates[1]),
      longitude: double.parse(coordinates[0]),
      category: json['type'],
      phone: json['tel'],
      distance: json['distance']?.toDouble(),
    );
  }
}

/// 位置监听器接口
abstract class LocationListener {
  void onLocationUpdate(Position position);
}
