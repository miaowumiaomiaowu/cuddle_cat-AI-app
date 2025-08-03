import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/travel_provider.dart';
import '../models/travel_record_model.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';

class TravelMapScreen extends StatefulWidget {
  const TravelMapScreen({super.key});

  @override
  State<TravelMapScreen> createState() => _TravelMapScreenState();
}

class _TravelMapScreenState extends State<TravelMapScreen> with TickerProviderStateMixin {
  final LocationService _locationService = LocationService.instance;
  
  LocationInfo? _currentLocation;
  bool _isLoadingLocation = true;
  TravelRecord? _selectedRecord;
  late AnimationController _fabAnimationController;
  late AnimationController _bottomSheetController;
  
  // 地图相关
  double _mapScale = 1.0;
  Offset _mapOffset = Offset.zero;
  final TransformationController _transformationController = TransformationController();

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
    super.dispose();
  }

  /// 初始化地图
  Future<void> _initializeMap() async {
    // 初始化旅行Provider
    await context.read<TravelProvider>().initialize();
    
    // 获取当前位置
    await _getCurrentLocation();
  }

  /// 获取当前位置
  Future<void> _getCurrentLocation() async {
    try {
      final locationInfo = await _locationService.getCurrentLocation();
      if (locationInfo != null && mounted) {
        setState(() {
          _currentLocation = locationInfo;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('获取位置失败: $e');
      // 使用默认位置（北京）
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
      }
    }
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

  /// 构建自定义地图
  Widget _buildCustomMap(TravelProvider travelProvider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE8F4F8),
            const Color(0xFFF5F9FA),
          ],
        ),
      ),
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 3.0,
        onInteractionUpdate: (details) {
          setState(() {
            _mapScale = _transformationController.value.getMaxScaleOnAxis();
          });
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: TravelMapPainter(
            currentLocation: _currentLocation!,
            travelRecords: travelProvider.records,
            selectedRecord: _selectedRecord,
            onRecordTapped: _onRecordTapped,
            scale: _mapScale,
          ),
        ),
      ),
    );
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
                  // 实现搜索功能
                  context.read<TravelProvider>().searchRecords(value);
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
                _showFilterDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示筛选对话框
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选旅行记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mood),
              title: const Text('按心情筛选'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现心情筛选
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('按时间筛选'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现时间筛选
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('按地点筛选'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现地点筛选
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
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
}
