import 'package:flutter/foundation.dart';
import '../models/travel.dart';
import 'base_provider.dart';

/// 旅行记录状态管理Provider
class TravelProvider extends BaseProvider {
  List<Travel> _records = [];
  late TravelStats _stats;

  @override
  String get providerId => 'travel_provider';

  TravelProvider() {
    _stats = TravelStats.fromRecords(_records);
  }

  /// 获取所有旅行记录
  List<Travel> get records => List.unmodifiable(_records);

  /// 获取旅行统计信息
  TravelStats get stats => _stats;

  @override
  Map<String, dynamic> get persistentData {
    return {
      'records': _records.map((r) => r.toJson()).toList(),
      'stats': {
        'totalRecords': _stats.totalRecords,
        'totalPlaces': _stats.totalPlaces,
        'mostVisitedPlaces': _stats.mostVisitedPlaces,
        'mostUsedTags': _stats.mostUsedTags,
        'mostCommonMood': _stats.mostCommonMood,
      },
    };
  }

  @override
  Future<void> restoreFromData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('records')) {
        final recordsList = data['records'] as List<dynamic>;
        _records = recordsList.map((item) => Travel.fromJson(item)).toList();
        _updateStats();
        markPropertyChanged('records');
      }
    } catch (e) {
      debugPrint('TravelProvider: 恢复旅行数据失败 - $e');
      _records = [];
      _updateStats();
    }
  }

  /// 更新统计信息
  void _updateStats() {
    _stats = TravelStats.fromRecords(_records);
    markPropertyChanged('stats');
  }

  /// 加载所有旅行记录
  Future<void> loadRecords() async {
    await executeWithErrorHandling(() async {
      // 数据已通过 restoreFromData 加载，这里只需要确保统计信息是最新的
      _updateStats();
    }, errorMessage: '加载旅行记录失败');
  }

  /// 添加新的旅行记录
  Future<void> addRecord(Travel record) async {
    await executeWithErrorHandling(() async {
      _records.add(record);
      _updateStats();
      markPropertyChanged('records');
      await saveData(immediate: true);
    }, errorMessage: '添加旅行记录失败');
  }

  /// 更新旅行记录
  Future<void> updateRecord(Travel updatedRecord) async {
    await executeWithErrorHandling(() async {
      final index =
          _records.indexWhere((record) => record.id == updatedRecord.id);
      if (index >= 0) {
        _records[index] = updatedRecord;
        _updateStats();
        markPropertyChanged('records');
        await saveData(immediate: true);
      }
    }, errorMessage: '更新旅行记录失败');
  }

  /// 删除旅行记录
  Future<void> deleteRecord(String id) async {
    await executeWithErrorHandling(() async {
      _records.removeWhere((record) => record.id == id);
      _updateStats();
      markPropertyChanged('records');
      await saveData(immediate: true);
    }, errorMessage: '删除旅行记录失败');
  }

  /// 按时间排序的旅行记录
  List<Travel> get sortedRecords {
    final sorted = List<Travel>.from(_records);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// 按标签筛选的旅行记录
  List<Travel> searchByTag(String tag) {
    return _records.where((record) => record.tags.contains(tag)).toList();
  }

  /// 按地点筛选的旅行记录
  List<Travel> searchByLocation(String location) {
    return _records
        .where((record) =>
            record.locationName.toLowerCase().contains(location.toLowerCase()))
        .toList();
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String id) async {
    await executeWithErrorHandling(() async {
      final index = _records.indexWhere((record) => record.id == id);
      if (index >= 0) {
        final record = _records[index];
        final updatedRecord = record.copyWith(isFavorite: !record.isFavorite);
        _records[index] = updatedRecord;
        markPropertyChanged('records');
        await saveData();
      }
    }, errorMessage: '切换收藏状态失败');
  }

  /// 按关键词搜索
  List<Travel> search(String keyword) {
    final lowercaseKeyword = keyword.toLowerCase();
    return _records
        .where((record) =>
            record.title.toLowerCase().contains(lowercaseKeyword) ||
            record.description.toLowerCase().contains(lowercaseKeyword) ||
            record.locationName.toLowerCase().contains(lowercaseKeyword) ||
            record.tags
                .any((tag) => tag.toLowerCase().contains(lowercaseKeyword)))
        .toList();
  }

  @override
  Future<void> onClearData() async {
    _records.clear();
    _updateStats();
  }
}
