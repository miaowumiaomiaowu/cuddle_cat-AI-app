import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../models/travel_record_model.dart';

/// 增强的定位服务类 - 支持心情地图和位置追踪
class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  LocationService._();

  late Dio _dio;
  Position? _lastKnownPosition;
  StreamSubscription<Position>? _positionStream;
  final List<LocationListener> _listeners = [];

  // 高德地图Web API密钥
  static const String _webApiKey = '0cee9416ae3897011cc1d83fef7375fb';

  /// 初始化定位服务
  Future<void> initialize() async {
    // 初始化网络请求
    _dio = Dio(BaseOptions(
      baseUrl: 'https://restapi.amap.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  /// 检查定位权限
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 检查定位服务是否启用
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
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
  }
  /// 获取当前位置
  Future<LocationInfo?> getCurrentLocation() async {
    try {
      // 检查权限
      if (!await checkLocationPermission()) {
        throw Exception('定位权限被拒绝');
      }

      // 获取当前位置
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // 使用高德地图API进行逆地理编码
      final locationInfo = await _reverseGeocodeWithAmap(
        position.latitude,
        position.longitude
      );

      if (locationInfo != null) {
        return locationInfo;
      }

      // 如果高德API失败，使用系统逆地理编码作为备选
      return await _reverseGeocodeWithSystem(
        position.latitude,
        position.longitude
      );

    } catch (e) {
      print('获取位置失败: $e');
      return null;
    }
  }

  /// 使用高德地图API进行逆地理编码
  Future<LocationInfo?> _reverseGeocodeWithAmap(
    double latitude,
    double longitude
  ) async {
    try {
      final response = await _dio.get('/v3/geocode/regeo', queryParameters: {
        'key': _webApiKey,
        'location': '$longitude,$latitude',
        'radius': 1000,
        'extensions': 'all',
      });

      if (response.data['status'] == '1' && response.data['regeocode'] != null) {
        final regeocode = response.data['regeocode'];
        final addressComponent = regeocode['addressComponent'];

        return LocationInfo(
          latitude: latitude,
          longitude: longitude,
          address: regeocode['formatted_address'] ?? '未知地址',
          city: addressComponent['city'] ?? addressComponent['district'],
          province: addressComponent['province'],
          country: addressComponent['country'] ?? '中国',
          poiName: regeocode['pois']?.isNotEmpty == true
              ? regeocode['pois'][0]['name']
              : null,
        );
      }
    } catch (e) {
      print('高德逆地理编码失败: $e');
    }
    return null;
  }

  /// 使用简单的坐标显示作为备选
  Future<LocationInfo?> _reverseGeocodeWithSystem(
    double latitude,
    double longitude
  ) async {
    try {
      // 简单的坐标显示，避免依赖geocoding包
      return LocationInfo(
        latitude: latitude,
        longitude: longitude,
        address: '位置: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
        city: '未知城市',
        province: '未知省份',
        country: '中国',
        poiName: '当前位置',
      );
    } catch (e) {
      print('备选定位失败: $e');
    }
    return null;
  }

  /// 地理编码 - 根据地址获取坐标
  Future<LocationInfo?> geocodeAddress(String address) async {
    try {
      // 只使用高德地图API进行地理编码
      return await _geocodeWithAmap(address);
    } catch (e) {
      print('地理编码失败: $e');
    }
    return null;
  }

  /// 使用高德地图API进行地理编码
  Future<LocationInfo?> _geocodeWithAmap(String address) async {
    try {
      final response = await _dio.get('/v3/geocode/geo', queryParameters: {
        'key': _webApiKey,
        'address': address,
        'city': '', // 可以指定城市范围
      });

      if (response.data['status'] == '1' &&
          response.data['geocodes'] != null &&
          response.data['geocodes'].isNotEmpty) {

        final geocode = response.data['geocodes'][0];
        final location = geocode['location'] as String;
        final coordinates = location.split(',');

        if (coordinates.length == 2) {
          return LocationInfo(
            latitude: double.parse(coordinates[1]),
            longitude: double.parse(coordinates[0]),
            address: address,
            city: geocode['city'],
            province: geocode['province'],
            country: '中国',
          );
        }
      }
    } catch (e) {
      print('高德地理编码失败: $e');
    }
    return null;
  }

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
      final response = await _dio.get('/v3/place/around', queryParameters: {
        'key': _webApiKey,
        'location': '$longitude,$latitude',
        'keywords': keywords,
        'radius': radius,
        'page': page,
        'offset': pageSize,
        'extensions': 'all',
      });

      if (response.data['status'] == '1' && response.data['pois'] != null) {
        final pois = response.data['pois'] as List;
        return pois.map((poi) => PoiInfo.fromJson(poi)).toList();
      }
    } catch (e) {
      print('搜索POI失败: $e');
    }
    return [];
  }

  /// 计算两点间距离 (公里)
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// 获取位置流（实时定位）
  Stream<LocationInfo?> getLocationStream() async* {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10米变化才更新
    );

    await for (Position position in Geolocator.getPositionStream(
      locationSettings: locationSettings,
    )) {
      final locationInfo = await _reverseGeocodeWithAmap(
        position.latitude,
        position.longitude
      );
      yield locationInfo;
    }
  }

  /// 检查定位服务是否可用
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 打开定位设置
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// 打开应用设置
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
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

// === 新增的增强功能 ===

/// 位置监听器接口
abstract class LocationListener {
  void onLocationUpdate(Position position);
}

/// 位置工具类扩展
extension LocationServiceExtension on LocationService {
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
}
