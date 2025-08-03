import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import '../models/travel_record_model.dart';

/// 地图服务类 - 处理地图相关功能
class MapService {
  static MapService? _instance;
  static MapService get instance => _instance ??= MapService._();
  
  MapService._();

  Completer<AMapController>? _controller;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  /// 初始化地图控制器
  void initializeController(AMapController controller) {
    if (_controller == null) {
      _controller = Completer<AMapController>();
      _controller!.complete(controller);
    }
  }

  /// 获取地图控制器
  Future<AMapController> get controller async {
    if (_controller == null) {
      _controller = Completer<AMapController>();
    }
    return _controller!.future;
  }

  /// 移动地图到指定位置
  Future<void> moveToLocation(double latitude, double longitude, {double zoom = 15.0}) async {
    final AMapController mapController = await controller;
    await mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  /// 根据旅行记录创建地图标记
  Future<Set<Marker>> createMarkersFromRecords(
    List<TravelRecord> records,
    Function(TravelRecord) onMarkerTap,
  ) async {
    _markers.clear();

    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      final markerId = MarkerId(record.id);
      
      // 创建自定义标记图标
      final BitmapDescriptor icon = await _createCustomMarkerIcon(
        record.mood,
        _getMarkerColor(i),
      );

      final marker = Marker(
        markerId: markerId,
        position: LatLng(record.location.latitude, record.location.longitude),
        icon: icon,
        infoWindow: InfoWindow(
          title: record.title,
          snippet: record.location.address,
          onTap: () => onMarkerTap(record),
        ),
        onTap: () => onMarkerTap(record),
      );

      _markers.add(marker);
    }

    return _markers;
  }

  /// 创建自定义标记图标
  Future<BitmapDescriptor> _createCustomMarkerIcon(
    String mood,
    Color color,
  ) async {
    try {
      // 创建一个画布来绘制自定义标记
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      const double size = 120.0;

      // 绘制圆形背景
      final Paint backgroundPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 10,
        backgroundPaint,
      );

      // 绘制白色边框
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0;
      
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 10,
        borderPaint,
      );

      // 绘制心情表情
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: mood,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size - textPainter.width) / 2,
          (size - textPainter.height) / 2,
        ),
      );

      // 转换为图片
      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List uint8List = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(uint8List);
    } catch (e) {
      print('创建自定义标记失败: $e');
      // 如果创建失败，使用默认标记
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  /// 获取标记颜色
  Color _getMarkerColor(int index) {
    final colors = [
      const Color(0xFFD4A574), // 暖米色
      const Color(0xFF9ABEAA), // 薄荷绿
      const Color(0xFFE8B4B8), // 粉色
      const Color(0xFFC8A8D8), // 紫色
      const Color(0xFFA8C8E8), // 蓝色
      const Color(0xFFD8C8A8), // 棕色
    ];
    return colors[index % colors.length];
  }

  /// 创建当前位置的圆圈标记
  Set<Circle> createCurrentLocationCircle(double latitude, double longitude) {
    _circles.clear();
    
    final circle = Circle(
      circleId: const CircleId('current_location'),
      center: LatLng(latitude, longitude),
      radius: 100, // 100米半径
      fillColor: const Color(0xFFD4A574).withOpacity(0.2),
      strokeColor: const Color(0xFFD4A574),
      strokeWidth: 2,
    );

    _circles.add(circle);
    return _circles;
  }

  /// 适配地图视图以显示所有标记
  Future<void> fitMarkersInView(List<TravelRecord> records, {double padding = 100.0}) async {
    if (records.isEmpty) return;

    final AMapController mapController = await controller;

    if (records.length == 1) {
      // 如果只有一个记录，直接移动到该位置
      final record = records.first;
      await moveToLocation(record.location.latitude, record.location.longitude);
      return;
    }

    // 计算边界
    double minLat = records.first.location.latitude;
    double maxLat = records.first.location.latitude;
    double minLng = records.first.location.longitude;
    double maxLng = records.first.location.longitude;

    for (final record in records) {
      minLat = minLat < record.location.latitude ? minLat : record.location.latitude;
      maxLat = maxLat > record.location.latitude ? maxLat : record.location.latitude;
      minLng = minLng < record.location.longitude ? minLng : record.location.longitude;
      maxLng = maxLng > record.location.longitude ? maxLng : record.location.longitude;
    }

    // 创建边界
    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // 移动地图以适应所有标记
    await mapController.moveCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  /// 清除所有标记
  void clearMarkers() {
    _markers.clear();
    _circles.clear();
  }

  /// 获取当前标记集合
  Set<Marker> get markers => _markers;

  /// 获取当前圆圈集合
  Set<Circle> get circles => _circles;

  /// 释放资源
  void dispose() {
    _controller = null;
    _markers.clear();
    _circles.clear();
  }
}

/// 地图主题样式
class MapThemes {
  /// 高德地图样式配置
  static const MapType morandiMapType = MapType.normal;

  /// 获取莫兰迪风格的地图配置
  static Map<String, dynamic> getMorandiMapOptions() {
    return {
      'mapType': MapType.normal,
      'myLocationEnabled': true,
      'myLocationButtonEnabled': false,
      'zoomControlsEnabled': false,
      'compassEnabled': true,
      'scaleControlsEnabled': false,
      'zoomGesturesEnabled': true,
      'scrollGesturesEnabled': true,
      'rotateGesturesEnabled': true,
      'tiltGesturesEnabled': true,
    };
  }
}
