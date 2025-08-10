import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../models/travel_record_model.dart';
import '../models/travel.dart';
import '../theme/artistic_theme.dart';

import '../widgets/travel_record_card.dart';
import '../services/location_service.dart';
import 'dart:math' as math;

class TravelMapScreenEnhanced extends StatefulWidget {
  const TravelMapScreenEnhanced({super.key});

  @override
  State<TravelMapScreenEnhanced> createState() => _TravelMapScreenEnhancedState();
}

class _TravelMapScreenEnhancedState extends State<TravelMapScreenEnhanced>
    with TickerProviderStateMixin {
  
  // 地图控制
  final TransformationController _transformationController = TransformationController();
  double _mapScale = 1.0;
  LocationInfo? _currentLocation;
  TravelRecord? _selectedRecord;
  
  // 动画控制器
  late AnimationController _recordDetailController;
  late Animation<double> _recordDetailAnimation;
  
  // 搜索和筛选
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    
    _recordDetailController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _recordDetailAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _recordDetailController,
      curve: Curves.easeInOut,
    ));
    
    _initializeLocation();
  }
  
  @override
  void dispose() {
    _transformationController.dispose();
    _recordDetailController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeLocation() async {
    try {
      final location = await LocationService.instance.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentLocation = location;
        });
      }
    } catch (e) {
      debugPrint('获取位置失败: $e');
      // 使用默认位置（北京）
      setState(() {
        _currentLocation = LocationInfo(
          latitude: 39.9042,
          longitude: 116.4074,
          address: '北京市',
          city: '北京市',
          province: '北京市',
        );
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisticTheme.backgroundColor,
      body: Consumer<TravelProvider>(
        builder: (context, travelProvider, child) {
          if (_currentLocation == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return Stack(
            children: [
              // 彩铅手绘风格地图
              _buildHandDrawnMap(travelProvider),
              
              // 顶部工具栏
              _buildTopToolbar(travelProvider),
              
              // 记录详情面板
              if (_selectedRecord != null)
                _buildRecordDetailPanel(),
              
              // 浮动操作按钮
              _buildFloatingButtons(travelProvider),
            ],
          );
        },
      ),
    );
  }
  
  // 构建彩铅手绘风格地图
  Widget _buildHandDrawnMap(TravelProvider travelProvider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF8F6F0), // 纸张色
            const Color(0xFFF5F2E8), // 温暖的米色
            const Color(0xFFF0EDE0), // 淡雅的象牙色
          ],
        ),
      ),
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        onInteractionUpdate: (details) {
          setState(() {
            _mapScale = _transformationController.value.getMaxScaleOnAxis();
          });
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: HandDrawnMapPainter(
            currentLocation: _currentLocation!,
            travelRecords: travelProvider.filteredRecords,
            selectedRecord: _selectedRecord,
            scale: _mapScale,
            onRecordTapped: _onRecordTapped,
            searchQuery: _searchQuery,
          ),
        ),
      ),
    );
  }
  
  // 构建顶部工具栏
  Widget _buildTopToolbar(TravelProvider travelProvider) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ArtisticTheme.backgroundColor.withValues(alpha: 0.9),
              ArtisticTheme.backgroundColor.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // 标题
                if (!_showSearchBar)
                  Expanded(
                    child: Text(
                      '旅行足迹',
                      style: ArtisticTheme.headlineLarge.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                
                // 搜索框
                if (_showSearchBar)
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: ArtisticTheme.glassEffect,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          travelProvider.searchRecords(value);
                        },
                        decoration: InputDecoration(
                          hintText: '搜索地点、标签...',
                          hintStyle: ArtisticTheme.bodyMedium.copyWith(
                            color: ArtisticTheme.textSecondary,
                          ),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(width: 8),
                
                // 搜索按钮
                _buildToolbarButton(
                  icon: _showSearchBar ? Icons.close : Icons.search,
                  onPressed: () {
                    setState(() {
                      _showSearchBar = !_showSearchBar;
                      if (!_showSearchBar) {
                        _searchController.clear();
                        _searchQuery = '';
                        travelProvider.clearFilters();
                      }
                    });
                  },
                ),
                
                const SizedBox(width: 8),
                
                // 筛选按钮
                _buildToolbarButton(
                  icon: Icons.filter_list,
                  onPressed: () => _showFilterDialog(travelProvider),
                ),
              ],
            ),
            
            // 记录统计
            if (travelProvider.filteredRecords.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: ArtisticTheme.glassEffect,
                child: Text(
                  '共 ${travelProvider.filteredRecords.length} 个记录',
                  style: ArtisticTheme.caption.copyWith(
                    color: ArtisticTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // 构建工具栏按钮
  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: ArtisticTheme.glassEffect,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
  
  // 记录点击处理
  void _onRecordTapped(TravelRecord record) {
    setState(() {
      _selectedRecord = record;
    });
    _recordDetailController.forward();
  }
  
  // 构建记录详情面板
  Widget _buildRecordDetailPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _recordDetailAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _recordDetailAnimation.value) * 300),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: ArtisticTheme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(ArtisticTheme.radiusXLarge),
                  topRight: Radius.circular(ArtisticTheme.radiusXLarge),
                ),
                boxShadow: ArtisticTheme.elevatedShadow,
              ),
              child: Column(
                children: [
                  // 拖拽指示器
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ArtisticTheme.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // 关闭按钮
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _recordDetailController.reverse().then((_) {
                          setState(() {
                            _selectedRecord = null;
                          });
                        });
                      },
                    ),
                  ),
                  
                  // 记录详情
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TravelRecordCard(
                        record: _selectedRecord!,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // 构建浮动按钮
  Widget _buildFloatingButtons(TravelProvider travelProvider) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 添加记录按钮
          FloatingActionButton(
            heroTag: "add_record",
            onPressed: () {
              // TODO: 导航到添加记录页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('添加记录功能即将开放！')),
              );
            },
            backgroundColor: ArtisticTheme.primaryColor,
            child: const Icon(Icons.add_location, color: Colors.white),
          ),
          
          const SizedBox(height: 12),
          
          // 当前位置按钮
          FloatingActionButton(
            heroTag: "current_location",
            onPressed: () {
              // 重置地图到当前位置
              _transformationController.value = Matrix4.identity();
              setState(() {
                _mapScale = 1.0;
              });
            },
            backgroundColor: ArtisticTheme.accentColor,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }
  
  // 显示筛选对话框
  void _showFilterDialog(TravelProvider travelProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选记录'),
        content: const Text('筛选功能即将开放！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 将TravelRecord转换为Travel
  Travel _convertToTravel(TravelRecord record) {
    return Travel(
      id: record.id,
      title: record.title,
      locationName: record.location.address,
      latitude: record.location.latitude,
      longitude: record.location.longitude,
      mood: record.mood,
      description: record.description,
      tags: record.tags,
      photos: record.photos,
      date: record.createdAt,
      isFavorite: record.rating != null && record.rating! >= 4.0,
    );
  }
}

// 彩铅手绘风格地图绘制器
class HandDrawnMapPainter extends CustomPainter {
  final LocationInfo currentLocation;
  final List<TravelRecord> travelRecords;
  final TravelRecord? selectedRecord;
  final double scale;
  final Function(TravelRecord) onRecordTapped;
  final String searchQuery;

  HandDrawnMapPainter({
    required this.currentLocation,
    required this.travelRecords,
    required this.selectedRecord,
    required this.scale,
    required this.onRecordTapped,
    required this.searchQuery,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制彩铅纸张纹理背景
    _drawPaperTexture(canvas, size);
    
    // 绘制当前位置
    _drawCurrentLocation(canvas, size);
    
    // 根据缩放级别绘制旅行记录
    if (scale < 1.0) {
      _drawRecordClusters(canvas, size);
    } else if (scale < 2.5) {
      _drawSimpleMarkers(canvas, size);
    } else {
      _drawDetailedMarkers(canvas, size);
    }
    
    // 绘制连接线（旅行路径）
    if (scale > 1.5) {
      _drawTravelPaths(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
  
  // 绘制纸张纹理
  void _drawPaperTexture(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF8F6F0)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // 添加细微的纹理点
    final random = math.Random(42); // 固定种子确保一致性
    final texturePaint = Paint()
      ..color = const Color(0xFFE8E6E0).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, texturePaint);
    }
  }
  
  // 绘制当前位置
  void _drawCurrentLocation(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // 外圈（脉动效果）
    final outerPaint = Paint()
      ..color = ArtisticTheme.primaryColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 20 + (scale * 5), outerPaint);
    
    // 内圈
    final innerPaint = Paint()
      ..color = ArtisticTheme.primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, innerPaint);
    
    // 白色中心点
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, centerPaint);
  }
  
  // 绘制记录聚合（小缩放）
  void _drawRecordClusters(Canvas canvas, Size size) {
    // 简化实现：显示记录总数
    if (travelRecords.isNotEmpty) {
      final center = Offset(size.width / 2 + 50, size.height / 2 - 50);
      
      final clusterPaint = Paint()
        ..color = ArtisticTheme.accentColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 15, clusterPaint);
      
      // 绘制数字
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${travelRecords.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }
  
  // 绘制简单标记（中等缩放）
  void _drawSimpleMarkers(Canvas canvas, Size size) {
    for (int i = 0; i < travelRecords.length; i++) {
      final record = travelRecords[i];
      final position = _getRecordPosition(record, size, i);
      
      final isSelected = record == selectedRecord;
      final markerSize = isSelected ? 12.0 : 8.0;
      
      final markerPaint = Paint()
        ..color = isSelected ? ArtisticTheme.primaryColor : ArtisticTheme.accentColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(position, markerSize, markerPaint);
      
      // 白色边框
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(position, markerSize, borderPaint);
    }
  }
  
  // 绘制详细标记（大缩放）
  void _drawDetailedMarkers(Canvas canvas, Size size) {
    for (int i = 0; i < travelRecords.length; i++) {
      final record = travelRecords[i];
      final position = _getRecordPosition(record, size, i);
      
      final isSelected = record == selectedRecord;
      final markerSize = isSelected ? 20.0 : 15.0;
      
      // 阴影
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position + const Offset(2, 2), markerSize, shadowPaint);
      
      // 主体
      final markerPaint = Paint()
        ..color = isSelected ? ArtisticTheme.primaryColor : ArtisticTheme.accentColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, markerSize, markerPaint);
      
      // 心情emoji
      final textPainter = TextPainter(
        text: TextSpan(
          text: record.mood,
          style: TextStyle(fontSize: markerSize * 0.8),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
      
      // 标题（如果选中）
      if (isSelected) {
        final titlePainter = TextPainter(
          text: TextSpan(
            text: record.title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        titlePainter.layout();
        titlePainter.paint(
          canvas,
          position + Offset(-titlePainter.width / 2, markerSize + 5),
        );
      }
    }
  }
  
  // 绘制旅行路径
  void _drawTravelPaths(Canvas canvas, Size size) {
    if (travelRecords.length < 2) return;
    
    final pathPaint = Paint()
      ..color = ArtisticTheme.primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    
    for (int i = 0; i < travelRecords.length - 1; i++) {
      final start = _getRecordPosition(travelRecords[i], size, i);
      final end = _getRecordPosition(travelRecords[i + 1], size, i + 1);
      
      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      }
      
      // 使用贝塞尔曲线创建平滑路径
      final controlPoint = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2 - 20,
      );
      
      path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);
    }
    
    canvas.drawPath(path, pathPaint);
  }
  
  // 获取记录在画布上的位置
  Offset _getRecordPosition(TravelRecord record, Size size, int index) {
    // 简化实现：基于索引分布记录
    final angle = (index * 2 * math.pi) / travelRecords.length;
    final radius = 100 + (index % 3) * 50;
    
    return Offset(
      size.width / 2 + radius * math.cos(angle),
      size.height / 2 + radius * math.sin(angle),
    );
  }

}
