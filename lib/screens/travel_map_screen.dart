import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../providers/travel_provider.dart';
import '../models/travel_record_model.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import '../services/amap_web_service.dart';

class TravelMapScreen extends StatefulWidget {
  const TravelMapScreen({super.key});

  @override
  State<TravelMapScreen> createState() => _TravelMapScreenState();
}

class _TravelMapScreenState extends State<TravelMapScreen> with TickerProviderStateMixin {
  final LocationService _locationService = LocationService.instance;
  final AmapWebService _amapService = AmapWebService.instance;

  LocationInfo? _currentLocation;
  bool _isLoadingLocation = true;
  TravelRecord? _selectedRecord;
  late AnimationController _fabAnimationController;
  late AnimationController _bottomSheetController;

  // 地图相关
  double _mapScale = 1.0;
  int _zoomLevel = 15; // 高德地图缩放级别 3-18
  final TransformationController _transformationController = TransformationController();
  String? _mapImageUrl;
  Timer? _debounceTimer;

  // 地图显示区域
  double _mapCenterLat = 39.9042;
  double _mapCenterLng = 116.4074;
  double _mapWidth = 600.0;
  double _mapHeight = 600.0;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _initializeMap();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _bottomSheetController.dispose();
    _transformationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 初始化地图
  Future<void> _initializeMap() async {
    try {
      // 使用默认位置（北京）快速启动
      setState(() {
        _currentLocation = LocationInfo(
          latitude: 39.9042,
          longitude: 116.4074,
          address: '北京市',
          city: '北京市',
          province: '北京市',
        );
        _isLoadingLocation = false;
      });
      _updateMapImage();

      // 异步初始化旅行Provider
      context.read<TravelProvider>().initialize();

      // 异步获取精确位置
      _getCurrentLocation();
    } catch (e) {
      print('初始化失败: $e');
      // 确保不会卡在加载状态
      if (mounted) {
        setState(() {
          _currentLocation = LocationInfo(
            latitude: 39.9042,
            longitude: 116.4074,
            address: '北京市',
            city: '北京市',
            province: '北京市',
          );
          _isLoadingLocation = false;
        });
        _updateMapImage();
      }
    }
  }

  /// 获取当前位置
  Future<void> _getCurrentLocation() async {
    try {
      final locationInfo = await _locationService.getCurrentLocation();
      if (locationInfo != null && mounted) {
        setState(() {
          _currentLocation = locationInfo;
        });
        _updateMapImage();
      }
    } catch (e) {
      print('获取精确位置失败: $e');
      // 已经有IP定位的位置，不需要再设置默认位置
    }
  }

  /// 防抖更新地图
  void _debounceMapUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _updateMapImage();
    });
  }

  /// 更新地图图片
  void _updateMapImage() {
    if (_currentLocation == null) return;

    final webApiKey = '0cee9416ae3897011cc1d83fef7375fb';

    // 更新地图中心点
    _mapCenterLat = _currentLocation!.latitude;
    _mapCenterLng = _currentLocation!.longitude;

    setState(() {
      _mapImageUrl = 'https://restapi.amap.com/v3/staticmap?'
          'location=$_mapCenterLng,$_mapCenterLat&'
          'zoom=$_zoomLevel&'
          'size=${_mapWidth.toInt()}*${_mapHeight.toInt()}&'
          'scale=1&'
          'key=$webApiKey';
    });
  }

  /// 构建iPhone相册风格的照片标记
  Widget _buildPhotoMapMarkers(TravelProvider travelProvider) {
    if (_currentLocation == null || travelProvider.records.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: travelProvider.records.map((record) {
        final screenPosition = _convertGeoToScreen(
          record.location.latitude,
          record.location.longitude,
        );

        if (screenPosition == null) return const SizedBox.shrink();

        return Positioned(
          left: screenPosition.dx - 30,
          top: screenPosition.dy - 30,
          child: _buildPhotoMarker(record),
        );
      }).toList(),
    );
  }

  /// 构建单个照片标记 - iPhone相册风格
  Widget _buildPhotoMarker(TravelRecord record) {
    final isSelected = _selectedRecord?.id == record.id;

    return GestureDetector(
      onTap: () => _onRecordTapped(record),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 70 : 60,
        height: isSelected ? 70 : 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // 背景图片或颜色
              if (record.mediaItems.isNotEmpty && record.mediaItems.first.type == MediaType.image)
                Image.network(
                  record.mediaItems.first.path,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackMarker(record);
                  },
                )
              else
                _buildFallbackMarker(record),

              // 记录数量标识（如果有多个媒体项目）
              if (record.mediaItems.length > 1)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${record.mediaItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // 选中状态指示器
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建备用标记（当没有图片时）
  Widget _buildFallbackMarker(TravelRecord record) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getRecordColor(record.hashCode % 6),
            _getRecordColor(record.hashCode % 6).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          record.mood,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 将地理坐标转换为屏幕坐标
  Offset? _convertGeoToScreen(double lat, double lng) {
    // 简化的坐标转换算法
    // 实际应用中需要更精确的墨卡托投影转换

    final screenSize = MediaQuery.of(context).size;
    final mapBounds = _getMapBounds();

    // 检查点是否在当前地图范围内
    if (lat < mapBounds['minLat']! || lat > mapBounds['maxLat']! ||
        lng < mapBounds['minLng']! || lng > mapBounds['maxLng']!) {
      return null; // 不在可视范围内
    }

    // 转换为屏幕坐标
    final x = ((lng - mapBounds['minLng']!) / (mapBounds['maxLng']! - mapBounds['minLng']!)) * screenSize.width;
    final y = ((mapBounds['maxLat']! - lat) / (mapBounds['maxLat']! - mapBounds['minLat']!)) * screenSize.height;

    return Offset(x, y);
  }

  /// 获取当前地图显示范围
  Map<String, double> _getMapBounds() {
    // 根据缩放级别计算地图显示范围
    // 这是一个简化的计算，实际应该使用更精确的算法

    double latRange, lngRange;

    switch (_zoomLevel) {
      case 8:
        latRange = 8.0;
        lngRange = 10.0;
        break;
      case 12:
        latRange = 2.0;
        lngRange = 2.5;
        break;
      case 15:
        latRange = 0.5;
        lngRange = 0.6;
        break;
      case 17:
        latRange = 0.1;
        lngRange = 0.12;
        break;
      case 18:
        latRange = 0.05;
        lngRange = 0.06;
        break;
      default:
        latRange = 1.0;
        lngRange = 1.2;
    }

    return {
      'minLat': _mapCenterLat - latRange / 2,
      'maxLat': _mapCenterLat + latRange / 2,
      'minLng': _mapCenterLng - lngRange / 2,
      'maxLng': _mapCenterLng + lngRange / 2,
    };
  }

  /// 获取标记颜色
  String _getMarkerColor(int index) {
    final colors = ['red', 'green', 'orange', 'purple', 'yellow', 'pink'];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TravelProvider>(
      builder: (context, travelProvider, child) {
        if (_isLoadingLocation || travelProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('旅行地图'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '正在加载地图...',
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              // 自定义地图主体
              _buildCustomMap(travelProvider),
              
              // 顶部搜索栏
              _buildTopSearchBar(),
              
              // 底部记录详情面板
              if (_selectedRecord != null)
                _buildBottomRecordPanel(),
              
              // 右侧功能按钮
              _buildSideFunctionButtons(travelProvider),
            ],
          ),
          floatingActionButton: _buildFloatingActionButtons(travelProvider),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  /// 构建高德地图 - iPhone相册风格
  Widget _buildCustomMap(TravelProvider travelProvider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF5F9FA),
      child: Stack(
        children: [
          // 可交互的地图层
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.3, // 更小的最小缩放，看到更大范围
            maxScale: 5.0, // 更大的最大缩放，看到更多细节
            onInteractionUpdate: (details) {
              final newScale = _transformationController.value.getMaxScaleOnAxis();

              // 简化版本：只处理缩放，拖拽功能后续优化
              if ((newScale - _mapScale).abs() > 0.2) {
                setState(() {
                  _mapScale = newScale;

                  // 根据缩放级别动态调整地图详细程度
                  if (newScale < 0.6) {
                    _zoomLevel = 12; // 显示更大范围
                  } else if (newScale < 1.5) {
                    _zoomLevel = 15; // 标准视图
                  } else {
                    _zoomLevel = 17; // 详细视图
                  }
                });

                // 延迟更新地图，避免频繁请求
                _debounceMapUpdate();
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // 高德地图静态图片
                  if (_mapImageUrl != null)
                    Positioned.fill(
                      child: Image.network(
                        _mapImageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFE8F4F8),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    '正在加载地图...',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFE8F4F8),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.map,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    '地图加载失败',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _updateMapImage,
                                    child: const Text('重新加载'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFFE8F4F8),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '正在初始化地图...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 旅行记录标记层 - iPhone相册风格
          _buildPhotoMapMarkers(travelProvider),
        ],
      ),
    );
  }

  /// 构建旅行记录交互层
  Widget _buildRecordInteractionLayer(TravelProvider travelProvider) {
    if (_currentLocation == null || travelProvider.records.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: travelProvider.records.asMap().entries.map((entry) {
        final index = entry.key;
        final record = entry.value;

        // 计算记录在地图上的相对位置
        final position = _calculateRecordPosition(record, index);

        return Positioned(
          left: position.dx - 20,
          top: position.dy - 20,
          child: GestureDetector(
            onTap: () => _onRecordTapped(record),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRecordColor(index),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedRecord?.id == record.id
                      ? AppTheme.primaryColor
                      : Colors.white,
                  width: _selectedRecord?.id == record.id ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  record.mood,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 计算记录在地图上的位置
  Offset _calculateRecordPosition(TravelRecord record, int index) {
    // 简化计算：围绕中心点圆形分布
    final screenSize = MediaQuery.of(context).size;
    final center = Offset(screenSize.width / 2, screenSize.height / 2);
    final radius = math.min(screenSize.width, screenSize.height) * 0.2;

    final angle = (index / context.read<TravelProvider>().records.length) * 2 * math.pi;

    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  /// 获取记录颜色
  Color _getRecordColor(int index) {
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

  /// 记录点击事件
  void _onRecordTapped(TravelRecord record) {
    setState(() {
      _selectedRecord = record;
    });
    _bottomSheetController.forward();
  }

  /// 构建顶部搜索栏
  Widget _buildTopSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search,
              color: Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索旅行记录...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  // TODO: 实现搜索功能
                },
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              onPressed: () {
                // TODO: 实现筛选功能
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建底部记录详情面板
  Widget _buildBottomRecordPanel() {
    return AnimatedBuilder(
      animation: _bottomSheetController,
      builder: (context, child) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, (1 - _bottomSheetController.value) * 200),
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 拖拽指示器
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // 记录内容
                  Expanded(
                    child: _buildRecordDetails(_selectedRecord!),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建记录详情
  Widget _buildRecordDetails(TravelRecord record) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 心情图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    record.mood,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 标题和地址
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.location.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 关闭按钮
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _selectedRecord = null;
                  });
                  _bottomSheetController.reverse();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 描述
          Text(
            record.description,
            style: const TextStyle(fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('查看详情'),
                onPressed: () {
                  // TODO: 导航到详情页面
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('编辑'),
                onPressed: () {
                  // TODO: 编辑记录
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.share, size: 18),
                label: const Text('分享'),
                onPressed: () {
                  // TODO: 分享记录
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建右侧功能按钮
  Widget _buildSideFunctionButtons(TravelProvider travelProvider) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      right: 16,
      child: Column(
        children: [
          // 放大地图
          FloatingActionButton(
            mini: true,
            heroTag: "zoom_in",
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            onPressed: () {
              if (_zoomLevel < 18) {
                setState(() {
                  _zoomLevel++;
                });
                _updateMapImage();
              }
            },
            child: const Icon(Icons.zoom_in),
          ),

          const SizedBox(height: 8),

          // 缩小地图
          FloatingActionButton(
            mini: true,
            heroTag: "zoom_out",
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            onPressed: () {
              if (_zoomLevel > 3) {
                setState(() {
                  _zoomLevel--;
                });
                _updateMapImage();
              }
            },
            child: const Icon(Icons.zoom_out),
          ),

          const SizedBox(height: 8),

          // 定位到当前位置
          FloatingActionButton(
            mini: true,
            heroTag: "location",
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            onPressed: () async {
              // 重新获取当前位置
              await _getCurrentLocation();
              // 重置地图变换
              _transformationController.value = Matrix4.identity();
              setState(() {
                _mapScale = 1.0;
                _zoomLevel = 15;
              });
              _updateMapImage();
            },
            child: const Icon(Icons.my_location),
          ),

          const SizedBox(height: 8),

          // 刷新数据
          FloatingActionButton(
            mini: true,
            heroTag: "refresh",
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            onPressed: () async {
              await travelProvider.refresh();
              _updateMapImage(); // 刷新地图
            },
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  /// 构建浮动操作按钮
  Widget _buildFloatingActionButtons(TravelProvider travelProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 添加记录按钮
        FloatingActionButton.extended(
          heroTag: "add_record",
          onPressed: () {
            Navigator.pushNamed(context, '/travel_test');
          },
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('添加记录'),
        ),

        // 记录列表按钮
        FloatingActionButton.extended(
          heroTag: "record_list",
          onPressed: () {
            _showRecordsList(travelProvider);
          },
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.list),
          label: const Text('记录列表'),
        ),
      ],
    );
  }

  /// 显示记录列表
  void _showRecordsList(TravelProvider travelProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Text(
                    '旅行记录',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 记录列表
            Expanded(
              child: travelProvider.records.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.travel_explore,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '还没有旅行记录',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: travelProvider.records.length,
                      itemBuilder: (context, index) {
                        final record = travelProvider.records[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: Text(record.mood),
                            ),
                            title: Text(record.title),
                            subtitle: Text(record.location.address),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.pop(context);
                              _onRecordTapped(record);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 地图背景绘制器
class MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 绘制地图网格
    _drawMapGrid(canvas, size);

    // 绘制地理特征（河流、道路等）
    _drawGeographicFeatures(canvas, size);
  }

  void _drawMapGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    // 绘制网格线
    const gridSize = 50.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawGeographicFeatures(Canvas canvas, Size size) {
    // 绘制一些模拟的地理特征
    final riverPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;

    // 绘制模拟河流
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.3, size.height * 0.2,
      size.width * 0.6, size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.5,
      size.width, size.height * 0.7,
    );
    canvas.drawPath(path, riverPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// 旅行记录绘制器 - 根据缩放级别显示不同详细程度的信息
class TravelRecordsPainter extends CustomPainter {
  final LocationInfo currentLocation;
  final List<TravelRecord> travelRecords;
  final TravelRecord? selectedRecord;
  final double scale;
  final Function(TravelRecord) onRecordTapped;

  TravelRecordsPainter({
    required this.currentLocation,
    required this.travelRecords,
    required this.selectedRecord,
    required this.scale,
    required this.onRecordTapped,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制当前位置
    _drawCurrentLocation(canvas, size);

    // 根据缩放级别绘制旅行记录
    if (scale < 0.8) {
      // 小缩放：显示记录数量
      _drawRecordClusters(canvas, size);
    } else if (scale < 2.0) {
      // 中等缩放：显示简单标记
      _drawSimpleMarkers(canvas, size);
    } else {
      // 大缩放：显示详细信息和缩略图
      _drawDetailedMarkers(canvas, size);
    }
  }

  void _drawCurrentLocation(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 绘制当前位置圆圈
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 12, paint);

    // 绘制边框
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, 12, borderPaint);

    // 绘制位置图标
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '📍',
        style: TextStyle(fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );
  }

  void _drawRecordClusters(Canvas canvas, Size size) {
    if (travelRecords.isEmpty) return;

    // 将记录按地理位置聚类
    final clusters = _clusterRecords();

    for (final cluster in clusters) {
      final position = _getClusterPosition(cluster, size);

      // 绘制聚类圆圈
      final paint = Paint()
        ..color = AppTheme.primaryColor.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, 20, paint);

      // 绘制记录数量
      final textPainter = TextPainter(
        text: TextSpan(
          text: cluster.length.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawSimpleMarkers(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.3;

    for (int i = 0; i < travelRecords.length; i++) {
      final record = travelRecords[i];
      final angle = (i / travelRecords.length) * 2 * math.pi;
      final position = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      _drawSimpleMarker(canvas, position, record, i);
    }
  }

  void _drawDetailedMarkers(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.35;

    for (int i = 0; i < travelRecords.length; i++) {
      final record = travelRecords[i];
      final angle = (i / travelRecords.length) * 2 * math.pi;
      final position = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      _drawDetailedMarker(canvas, position, record, i);
    }
  }

  void _drawSimpleMarker(Canvas canvas, Offset position, TravelRecord record, int index) {
    final isSelected = selectedRecord?.id == record.id;
    final markerSize = isSelected ? 18.0 : 14.0;

    // 获取标记颜色
    final colors = [
      const Color(0xFFD4A574), // 暖米色
      const Color(0xFF9ABEAA), // 薄荷绿
      const Color(0xFFE8B4B8), // 粉色
      const Color(0xFFC8A8D8), // 紫色
      const Color(0xFFA8C8E8), // 蓝色
      const Color(0xFFD8C8A8), // 棕色
    ];
    final color = colors[index % colors.length];

    // 绘制标记背景
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, markerSize, paint);

    // 绘制边框
    final borderPaint = Paint()
      ..color = isSelected ? AppTheme.primaryColor : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.0;

    canvas.drawCircle(position, markerSize, borderPaint);

    // 绘制心情表情
    final textPainter = TextPainter(
      text: TextSpan(
        text: record.mood,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawDetailedMarker(Canvas canvas, Offset position, TravelRecord record, int index) {
    final isSelected = selectedRecord?.id == record.id;
    final markerSize = isSelected ? 35.0 : 30.0;

    // 获取标记颜色
    final colors = [
      const Color(0xFFD4A574), // 暖米色
      const Color(0xFF9ABEAA), // 薄荷绿
      const Color(0xFFE8B4B8), // 粉色
      const Color(0xFFC8A8D8), // 紫色
      const Color(0xFFA8C8E8), // 蓝色
      const Color(0xFFD8C8A8), // 棕色
    ];
    final color = colors[index % colors.length];

    // 绘制标记背景
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, markerSize, paint);

    // 绘制边框
    final borderPaint = Paint()
      ..color = isSelected ? AppTheme.primaryColor : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 4.0 : 3.0;

    canvas.drawCircle(position, markerSize, borderPaint);

    // 绘制心情表情（更大）
    final textPainter = TextPainter(
      text: TextSpan(
        text: record.mood,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );

    // 绘制标题文本（在标记下方）
    final titlePainter = TextPainter(
      text: TextSpan(
        text: record.title.length > 8 ? '${record.title.substring(0, 8)}...' : record.title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(
        position.dx - titlePainter.width / 2,
        position.dy + markerSize + 5,
      ),
    );
  }

  List<List<TravelRecord>> _clusterRecords() {
    // 简单的聚类算法：按地理位置相近程度分组
    if (travelRecords.isEmpty) return [];

    // 这里简化处理，实际应该根据经纬度距离聚类
    final clusters = <List<TravelRecord>>[];
    final processed = <bool>[];

    for (int i = 0; i < travelRecords.length; i++) {
      processed.add(false);
    }

    for (int i = 0; i < travelRecords.length; i++) {
      if (processed[i]) continue;

      final cluster = <TravelRecord>[travelRecords[i]];
      processed[i] = true;

      // 简单聚类：每3个记录为一组
      int count = 1;
      for (int j = i + 1; j < travelRecords.length && count < 3; j++) {
        if (!processed[j]) {
          cluster.add(travelRecords[j]);
          processed[j] = true;
          count++;
        }
      }

      clusters.add(cluster);
    }

    return clusters;
  }

  Offset _getClusterPosition(List<TravelRecord> cluster, Size size) {
    // 根据聚类中第一个记录的位置计算聚类位置
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.25;

    // 简化：使用聚类索引计算角度
    final clusterIndex = travelRecords.indexOf(cluster.first);
    final angle = (clusterIndex / travelRecords.length) * 2 * math.pi;

    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  bool hitTest(Offset position) {
    return true;
  }
}
