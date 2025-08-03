import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../models/travel_record_model.dart';
import '../theme/app_theme.dart';

/// 旅行记录模块测试页面
class TravelTestScreen extends StatefulWidget {
  const TravelTestScreen({Key? key}) : super(key: key);

  @override
  State<TravelTestScreen> createState() => _TravelTestScreenState();
}

class _TravelTestScreenState extends State<TravelTestScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化旅行Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TravelProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('旅行记录测试'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<TravelProvider>(
        builder: (context, travelProvider, child) {
          if (travelProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          if (travelProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '出错了',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    travelProvider.error!,
                    style: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => travelProvider.refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 统计信息卡片
              _buildStatsCard(travelProvider),
              
              // 功能按钮区域
              _buildActionButtons(context, travelProvider),
              
              // 记录列表
              Expanded(
                child: _buildRecordsList(travelProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// 构建统计信息卡片
  Widget _buildStatsCard(TravelProvider provider) {
    final stats = provider.stats;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '旅行统计',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '总记录',
                  '${stats?.totalRecords ?? 0}',
                  Icons.book,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '城市数',
                  '${stats?.totalCities ?? 0}',
                  Icons.location_city,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '总里程',
                  '${(stats?.totalDistance ?? 0).toStringAsFixed(1)}km',
                  Icons.route,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计项目
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// 构建功能按钮
  Widget _buildActionButtons(BuildContext context, TravelProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _testGetLocation(context, provider),
              icon: const Icon(Icons.location_on, size: 18),
              label: const Text('获取位置'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _testAddMedia(context, provider),
              icon: const Icon(Icons.photo_camera, size: 18),
              label: const Text('添加照片'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建记录列表
  Widget _buildRecordsList(TravelProvider provider) {
    if (provider.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: 64,
              color: AppTheme.textColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '还没有旅行记录',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角的 + 按钮添加第一条记录',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.records.length,
      itemBuilder: (context, index) {
        final record = provider.records[index];
        return _buildRecordCard(record, provider);
      },
    );
  }

  /// 构建记录卡片
  Widget _buildRecordCard(TravelRecord record, TravelProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            record.mood,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          record.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              record.location.address,
              style: TextStyle(
                color: AppTheme.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${record.createdAt.year}-${record.createdAt.month.toString().padLeft(2, '0')}-${record.createdAt.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDelete(context, record, provider);
            }
          },
        ),
      ),
    );
  }

  /// 测试获取位置
  Future<void> _testGetLocation(BuildContext context, TravelProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在获取位置...')),
    );

    final location = await provider.getCurrentLocation();
    if (location != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('位置: ${location.address}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('获取位置失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 测试添加媒体
  Future<void> _testAddMedia(BuildContext context, TravelProvider provider) async {
    final media = await provider.addMediaFromGallery(
      type: MediaType.image,
      caption: '测试照片',
    );

    if (media != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('照片添加成功')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('照片添加失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 显示添加记录对话框
  void _showAddRecordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加测试记录'),
        content: const Text('是否添加一条测试旅行记录？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addTestRecord(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 添加测试记录
  Future<void> _addTestRecord(BuildContext context) async {
    final provider = context.read<TravelProvider>();
    
    final testRecord = TravelRecord(
      title: '测试旅行记录',
      description: '这是一条测试记录，用于验证旅行模块功能。',
      location: LocationInfo(
        latitude: 39.9042,
        longitude: 116.4074,
        address: '北京市东城区天安门广场',
        city: '北京市',
        province: '北京市',
        country: '中国',
        poiName: '天安门广场',
      ),
      mediaItems: [],
      mood: '😊',
      tags: ['测试', '北京', '旅行'],
      companions: [],
    );

    final success = await provider.addRecord(testRecord);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('测试记录添加成功')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('添加记录失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 确认删除
  void _confirmDelete(BuildContext context, TravelRecord record, TravelProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除记录"${record.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteRecord(record.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('记录已删除')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
