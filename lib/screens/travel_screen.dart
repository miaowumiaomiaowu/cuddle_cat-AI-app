import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:amap_flutter_map/amap_flutter_map.dart';
// import 'package:amap_flutter_base/amap_flutter_base.dart';
import '../providers/travel_provider.dart';
import '../providers/cat_provider.dart';
import '../models/travel.dart';
import '../widgets/travel_record_card.dart';
import '../widgets/travel_stats_card.dart';
import '../widgets/quick_travel_widget.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../utils/responsive_utils.dart';
import '../utils/animation_utils.dart';
import '../screens/add_travel_screen.dart';
// import '../utils/map_utils.dart';

/// 旅行记录主页面
class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // AMapController? _mapController;
  // final Set<Marker> _markers = {};
  // MapType _mapType = MapType.normal;
  bool _isLoading = false;
  String? _error;

  // 搜索和筛选
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMoodFilter = '';
  bool _showFavoritesOnly = false;
  String _sortBy = 'date'; // 'date', 'title', 'location'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    // _mapController = null;
    super.dispose();
  }

  /// 加载旅行记录数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<TravelProvider>(context, listen: false);
      await provider.refresh();
      // _updateMarkers();
    } catch (e) {
      setState(() {
        _error = "加载旅行记录失败: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 跳转到当前位置
  Future<void> _locateToCurrentPosition() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // final position = await MapUtils.getCurrentLocation();
      // if (position != null) {
      //   _mapController?.moveCamera(
      //     CameraUpdate.newCameraPosition(
      //       CameraPosition(
      //         target: position,
      //         zoom: 15,
      //       ),
      //     ),
      //   );
      // } else {
      //   setState(() {
      //     _error = "无法获取当前位置";
      //   });
      // }

      // 模拟位置获取成功
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      setState(() {
        _error = "定位失败: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 切换地图类型
  void _toggleMapType() {
    // setState(() {
    //   _mapType = _mapType == MapType.normal ? MapType.satellite : MapType.normal;
    // });
  }

  /// 获取筛选后的记录列表
  List<Travel> _getFilteredRecords(List<Travel> records) {
    List<Travel> filtered = records;

    // 搜索筛选
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((record) =>
              record.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              record.locationName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              record.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              record.tags.any((tag) =>
                  tag.toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();
    }

    // 心情筛选
    if (_selectedMoodFilter.isNotEmpty) {
      filtered = filtered
          .where((record) => record.mood == _selectedMoodFilter)
          .toList();
    }

    // 收藏筛选
    if (_showFavoritesOnly) {
      filtered = filtered.where((record) => record.isFavorite).toList();
    }

    // 排序
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'location':
          comparison = a.locationName.compareTo(b.locationName);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  /// 显示筛选对话框
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('筛选和排序'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 心情筛选
                const Text('按心情筛选:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildMoodFilterChip('', '全部', setDialogState),
                    _buildMoodFilterChip('happy', '😄 开心', setDialogState),
                    _buildMoodFilterChip('relaxed', '😌 放松', setDialogState),
                    _buildMoodFilterChip('excited', '🤩 兴奋', setDialogState),
                    _buildMoodFilterChip('romantic', '💑 浪漫', setDialogState),
                    _buildMoodFilterChip('tired', '😪 疲惫', setDialogState),
                    _buildMoodFilterChip('bored', '😒 无聊', setDialogState),
                  ],
                ),

                const SizedBox(height: 16),

                // 收藏筛选
                CheckboxListTile(
                  title: const Text('只显示收藏'),
                  value: _showFavoritesOnly,
                  onChanged: (value) {
                    setDialogState(() {
                      _showFavoritesOnly = value ?? false;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 16),

                // 排序选项
                const Text('排序方式:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('按日期'),
                      value: 'date',
                      groupValue: _sortBy,
                      onChanged: (value) {
                        setDialogState(() {
                          _sortBy = value!;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('按标题'),
                      value: 'title',
                      groupValue: _sortBy,
                      onChanged: (value) {
                        setDialogState(() {
                          _sortBy = value!;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('按位置'),
                      value: 'location',
                      groupValue: _sortBy,
                      onChanged: (value) {
                        setDialogState(() {
                          _sortBy = value!;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),

                // 排序方向
                CheckboxListTile(
                  title: const Text('升序排列'),
                  value: _sortAscending,
                  onChanged: (value) {
                    setDialogState(() {
                      _sortAscending = value ?? false;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 重置筛选
                setDialogState(() {
                  _selectedMoodFilter = '';
                  _showFavoritesOnly = false;
                  _sortBy = 'date';
                  _sortAscending = false;
                });
              },
              child: const Text('重置'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // 应用筛选设置
                });
                Navigator.of(context).pop();
              },
              child: const Text('应用'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodFilterChip(
      String value, String label, StateSetter setDialogState) {
    return FilterChip(
      label: Text(label),
      selected: _selectedMoodFilter == value,
      onSelected: (selected) {
        setDialogState(() {
          _selectedMoodFilter = selected ? value : '';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '旅行记录',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          IconButton(
            icon: const Text('🔍', style: TextStyle(fontSize: 20)),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _TravelSearchDelegate(),
              );
            },
            tooltip: '搜索记录',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.infoColor.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          IconButton(
            icon: const Text('🔧', style: TextStyle(fontSize: 20)),
            onPressed: _showFilterDialog,
            tooltip: '筛选和排序',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.warningColor.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.map_outlined),
              text: '地图视图',
            ),
            Tab(
              icon: Icon(Icons.list_alt),
              text: '列表视图',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 地图视图
          Consumer<TravelProvider>(
            builder: (context, provider, child) {
              return Stack(
                children: [
                  Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            '地图已暂时禁用',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '共有 ${provider.records.length} 条旅行记录',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 地图控制按钮
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'locate',
                          onPressed:
                              _isLoading ? null : _locateToCurrentPosition,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'mapType',
                          onPressed: _toggleMapType,
                          child: const Icon(Icons.map),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Material(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _error = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // 列表视图
          RefreshIndicator(
            onRefresh: _loadData,
            child: Consumer<TravelProvider>(
              builder: (context, provider, child) {
                if (_isLoading && provider.records.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.records.isEmpty) {
                  return EmptyStateWidget(
                    title: '暂无旅行记录',
                    message: '点击右下角的按钮添加您的第一条旅行记录吧',
                    icon: Icons.travel_explore,
                    actionText: '添加记录',
                    onAction: () async {
                      final result =
                          await Navigator.of(context).pushWithSlideUp(
                        const AddTravelScreen(),
                      );
                      if (result == true) {
                        _loadData();
                      }
                    },
                  );
                }

                final filteredRecords = _getFilteredRecords(provider.records);

                return ResponsiveContainer(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: Column(
                      children: [
                        TravelStatsCard(stats: provider.stats ?? TravelStats(
                          totalRecords: 0,
                          totalCities: 0,
                          totalProvinces: 0,
                          totalDistance: 0,
                          totalDays: 0,
                          moodDistribution: {},
                          monthlyDistribution: {},
                          topCities: [],
                          topTags: [],
                        )),
                        const SizedBox(height: AppTheme.spacingMedium),

                        // 快速旅行组件
                        const QuickTravelWidget(),

                        // 根据猫咪心情推荐旅行地点
                        Consumer<CatProvider>(
                          builder: (context, catProvider, child) {
                            if (catProvider.hasCat) {
                              return TravelRecommendationWidget(
                                mood: catProvider.cat!.moodText,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        // 筛选结果提示
                        if (filteredRecords.length != provider.records.length)
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(AppTheme.spacingMedium),
                            margin: const EdgeInsets.only(
                                bottom: AppTheme.spacingMedium),
                            decoration: BoxDecoration(
                              color: AppTheme.infoColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(
                                color:
                                    AppTheme.infoColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.infoColor,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacingSmall),
                                Expanded(
                                  child: Text(
                                    '显示 ${filteredRecords.length} / ${provider.records.length} 条记录',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.infoColor,
                                        ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedMoodFilter = '';
                                      _showFavoritesOnly = false;
                                      _searchController.clear();
                                    });
                                  },
                                  child: const Text('清除筛选'),
                                ),
                              ],
                            ),
                          ),

                        // 记录列表
                        if (filteredRecords.isEmpty)
                          EmptyStateWidget(
                            title: '没有找到匹配的记录',
                            message: '尝试调整筛选条件或清除筛选',
                            icon: Icons.search_off,
                            actionText: '清除筛选',
                            onAction: () {
                              setState(() {
                                _searchQuery = '';
                                _selectedMoodFilter = '';
                                _showFavoritesOnly = false;
                                _searchController.clear();
                              });
                            },
                          )
                        else
                          ResponsiveGrid(
                            mobileColumns: 1,
                            tabletColumns: 2,
                            desktopColumns: 3,
                            spacing: AppTheme.spacingMedium,
                            runSpacing: AppTheme.spacingMedium,
                            children: filteredRecords.map((record) {
                              return TravelRecordCard(record: record);
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).pushWithSlideUp(
            const AddTravelScreen(),
          );

          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('添加记录'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// 旅行记录搜索委托
class _TravelSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<TravelProvider>(
      builder: (context, provider, child) {
        if (query.isEmpty) {
          return const Center(
            child: Text('输入关键词搜索旅行记录'),
          );
        }

        // 使用新的搜索方法
        provider.searchRecords(query);
        final results = provider.records;

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '没有找到包含 "$query" 的记录',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TravelRecordCard(record: results[index]),
            );
          },
        );
      },
    );
  }
}
