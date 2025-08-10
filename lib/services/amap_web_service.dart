import 'dart:async';

import 'package:dio/dio.dart';
import '../models/travel_record_model.dart';

/// 高德地图Web API服务
class AmapWebService {
  static AmapWebService? _instance;
  static AmapWebService get instance => _instance ??= AmapWebService._();
  
  AmapWebService._();

  late Dio _dio;
  
  // 高德地图Web API密钥
  static const String _webApiKey = '0cee9416ae3897011cc1d83fef7375fb';
  
  /// 初始化服务
  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://restapi.amap.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  /// 地理编码 - 将地址转换为经纬度
  Future<LocationInfo?> geocode(String address, {String? city}) async {
    try {
      final response = await _dio.get('/v3/geocode/geo', queryParameters: {
        'key': _webApiKey,
        'address': address,
        if (city != null) 'city': city,
        'output': 'JSON',
      });

      if (response.data['status'] == '1' && response.data['geocodes'].isNotEmpty) {
        final geocode = response.data['geocodes'][0];
        final location = geocode['location'].toString().split(',');
        
        return LocationInfo(
          latitude: double.parse(location[1]),
          longitude: double.parse(location[0]),
          address: geocode['formatted_address'] ?? address,
          city: geocode['city'] ?? '',
          province: geocode['province'] ?? '',
        );
      }
    } catch (e) {
      print('地理编码失败: $e');
    }
    return null;
  }

  /// 逆地理编码 - 将经纬度转换为地址
  Future<LocationInfo?> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await _dio.get('/v3/geocode/regeo', queryParameters: {
        'key': _webApiKey,
        'location': '$longitude,$latitude',
        'output': 'JSON',
        'extensions': 'all',
        'radius': '1000',
      });

      if (response.data['status'] == '1') {
        final regeocode = response.data['regeocode'];
        final addressComponent = regeocode['addressComponent'];
        
        return LocationInfo(
          latitude: latitude,
          longitude: longitude,
          address: regeocode['formatted_address'] ?? '',
          city: addressComponent['city'] ?? addressComponent['province'] ?? '',
          province: addressComponent['province'] ?? '',
        );
      }
    } catch (e) {
      print('逆地理编码失败: $e');
    }
    return null;
  }

  /// IP定位 - 获取大概位置
  Future<LocationInfo?> getLocationByIP() async {
    try {
      final response = await _dio.get('/v3/ip', queryParameters: {
        'key': _webApiKey,
        'output': 'JSON',
      });

      if (response.data['status'] == '1') {
        final location = response.data['location'].toString().split(',');
        
        return LocationInfo(
          latitude: double.parse(location[1]),
          longitude: double.parse(location[0]),
          address: '${response.data['province']}${response.data['city']}',
          city: response.data['city'] ?? '',
          province: response.data['province'] ?? '',
        );
      }
    } catch (e) {
      print('IP定位失败: $e');
    }
    return null;
  }

  /// 搜索POI
  Future<List<LocationInfo>> searchPOI(String keywords, {
    String? city,
    int page = 1,
    int offset = 20,
  }) async {
    try {
      final response = await _dio.get('/v3/place/text', queryParameters: {
        'key': _webApiKey,
        'keywords': keywords,
        if (city != null) 'city': city,
        'page': page.toString(),
        'offset': offset.toString(),
        'output': 'JSON',
        'extensions': 'all',
      });

      if (response.data['status'] == '1') {
        final pois = response.data['pois'] as List;
        return pois.map((poi) {
          final location = poi['location'].toString().split(',');
          return LocationInfo(
            latitude: double.parse(location[1]),
            longitude: double.parse(location[0]),
            address: poi['address'] ?? '',
            city: poi['cityname'] ?? '',
            province: poi['pname'] ?? '',
          );
        }).toList();
      }
    } catch (e) {
      print('POI搜索失败: $e');
    }
    return [];
  }

  /// 获取静态地图图片URL
  String getStaticMapUrl({
    required double latitude,
    required double longitude,
    int zoom = 15,
    int size = 400,
    List<MapMarker>? markers,
  }) {
    final params = <String, String>{
      'key': _webApiKey,
      'location': '$longitude,$latitude',
      'zoom': zoom.toString(),
      'size': '${size}*$size',
      'scale': '1', // 先使用普通图，避免问题
    };

    // 添加标记参数
    if (markers != null && markers.isNotEmpty) {
      params['markers'] = _buildMarkersParam(markers);
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final url = 'https://restapi.amap.com/v3/staticmap?$query';
    print('地图URL: $url'); // 调试用
    return url;
  }

  /// 构建标记参数
  String _buildMarkersParam(List<MapMarker>? markers) {
    if (markers == null || markers.isEmpty) return '';

    // 高德地图标记格式：size,color,label:longitude,latitude
    final markerStrings = <String>[];

    for (final marker in markers) {
      final label = marker.label ?? '';
      markerStrings.add('mid,0x${_getColorHex(marker.color)},$label:${marker.longitude},${marker.latitude}');
    }

    return markerStrings.join('|');
  }

  /// 获取颜色的十六进制值
  String _getColorHex(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return 'FF0000';
      case 'blue':
        return '0000FF';
      case 'green':
        return '008000';
      case 'yellow':
        return 'FFFF00';
      case 'orange':
        return 'FFA500';
      case 'purple':
        return '800080';
      case 'pink':
        return 'FFC0CB';
      default:
        return 'FF0000'; // 默认红色
    }
  }

  /// 计算两点间距离
  Future<double?> calculateDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) async {
    try {
      final response = await _dio.get('/v3/distance', queryParameters: {
        'key': _webApiKey,
        'origins': '$lng1,$lat1',
        'destination': '$lng2,$lat2',
        'type': '1', // 直线距离
        'output': 'JSON',
      });

      if (response.data['status'] == '1') {
        final results = response.data['results'] as List;
        if (results.isNotEmpty) {
          return double.tryParse(results[0]['distance'].toString());
        }
      }
    } catch (e) {
      print('距离计算失败: $e');
    }
    return null;
  }

  /// 获取天气信息
  Future<WeatherInfo?> getWeather(String city) async {
    try {
      final response = await _dio.get('/v3/weather/weatherInfo', queryParameters: {
        'key': _webApiKey,
        'city': city,
        'extensions': 'base',
        'output': 'JSON',
      });

      if (response.data['status'] == '1') {
        final lives = response.data['lives'] as List;
        if (lives.isNotEmpty) {
          final live = lives[0];
          return WeatherInfo(
            city: live['city'] ?? '',
            weather: live['weather'] ?? '',
            temperature: live['temperature'] ?? '',
            humidity: live['humidity'] ?? '',
            windDirection: live['winddirection'] ?? '',
            windPower: live['windpower'] ?? '',
            reportTime: live['reporttime'] ?? '',
          );
        }
      }
    } catch (e) {
      print('天气查询失败: $e');
    }
    return null;
  }
}

/// 地图标记
class MapMarker {
  final double latitude;
  final double longitude;
  final String color;
  final String? label;

  MapMarker({
    required this.latitude,
    required this.longitude,
    this.color = 'red',
    this.label,
  });
}

/// 天气信息
class WeatherInfo {
  final String city;
  final String weather;
  final String temperature;
  final String humidity;
  final String windDirection;
  final String windPower;
  final String reportTime;

  WeatherInfo({
    required this.city,
    required this.weather,
    required this.temperature,
    required this.humidity,
    required this.windDirection,
    required this.windPower,
    required this.reportTime,
  });
}
