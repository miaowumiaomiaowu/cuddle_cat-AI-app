import 'package:flutter/material.dart';
import '../models/travel_record_model.dart';
import '../models/travel.dart';
import '../services/travel_service.dart';
import '../services/location_service.dart';

/// 旅行记录状态管理 - 增强版
class TravelProvider extends ChangeNotifier {
  final TravelService _travelService = TravelService.instance;
  final LocationService _locationService = LocationService.instance;

  // 状态变量
  List<TravelRecord> _records = [];
  List<TravelRecord> _filteredRecords = [];
  TravelRecord? _selectedRecord;
  TravelStats? _stats;
  bool _isLoading = false;
  String? _error;

  // 筛选和搜索状态
  String _searchKeyword = '';
  String? _selectedCity;
  String? _selectedProvince;
  String? _selectedMood;
  List<String> _selectedTags = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _isPrivateFilter;

  // Getters
  List<TravelRecord> get records => _filteredRecords;
  List<TravelRecord> get allRecords => _records;
  List<TravelRecord> get filteredRecords => _filteredRecords;
  TravelRecord? get selectedRecord => _selectedRecord;
  TravelStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasRecords => _records.isNotEmpty;

  // 筛选器状态
  String get searchKeyword => _searchKeyword;
  String? get selectedCity => _selectedCity;
  String? get selectedProvince => _selectedProvince;
  String? get selectedMood => _selectedMood;
  List<String> get selectedTags => _selectedTags;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool? get isPrivateFilter => _isPrivateFilter;

  /// 初始化Provider
  Future<void> initialize() async {
    await _loadRecords();
    await _loadStats();
  }

  /// 加载所有记录
  Future<void> _loadRecords() async {
    try {
      _setLoading(true);
      _records = await _travelService.getAllRecords();
      await _applyFilters();
      _clearError();
    } catch (e) {
      _setError('加载旅行记录失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载统计数据
  Future<void> _loadStats() async {
    try {
      _stats = await _travelService.getStats();
      notifyListeners();
    } catch (e) {
      debugPrint('加载统计数据失败: $e');
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await _loadRecords();
    await _loadStats();
  }

  /// 添加新记录
  Future<bool> addRecord(TravelRecord record) async {
    try {
      _setLoading(true);
      final success = await _travelService.saveRecord(record);
      if (success) {
        await _loadRecords();
        await _loadStats();
        return true;
      }
      return false;
    } catch (e) {
      _setError('添加记录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新记录
  Future<bool> updateRecord(TravelRecord record) async {
    try {
      _setLoading(true);
      final success = await _travelService.saveRecord(record);
      if (success) {
        await _loadRecords();
        await _loadStats();
        return true;
      }
      return false;
    } catch (e) {
      _setError('更新记录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除记录
  Future<bool> deleteRecord(String id) async {
    try {
      _setLoading(true);
      final success = await _travelService.deleteRecord(id);
      if (success) {
        await _loadRecords();
        await _loadStats();
        return true;
      }
      return false;
    } catch (e) {
      _setError('删除记录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 根据ID获取记录
  TravelRecord? getRecordById(String id) {
    try {
      return _records.firstWhere((record) => record.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 搜索记录
  Future<void> searchRecords(String keyword) async {
    _searchKeyword = keyword;
    await _applyFilters();
  }

  /// 设置城市筛选
  Future<void> filterByCity(String? city) async {
    _selectedCity = city;
    await _applyFilters();
  }

  /// 设置省份筛选
  Future<void> filterByProvince(String? province) async {
    _selectedProvince = province;
    await _applyFilters();
  }

  /// 设置心情筛选
  Future<void> filterByMood(String? mood) async {
    _selectedMood = mood;
    await _applyFilters();
  }

  /// 设置标签筛选
  Future<void> filterByTags(List<String> tags) async {
    _selectedTags = tags;
    await _applyFilters();
  }

  /// 设置日期范围筛选
  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    _startDate = start;
    _endDate = end;
    await _applyFilters();
  }

  /// 设置隐私筛选
  Future<void> filterByPrivacy(bool? isPrivate) async {
    _isPrivateFilter = isPrivate;
    await _applyFilters();
  }

  /// 清除所有筛选
  Future<void> clearFilters() async {
    _searchKeyword = '';
    _selectedCity = null;
    _selectedProvince = null;
    _selectedMood = null;
    _selectedTags = [];
    _startDate = null;
    _endDate = null;
    _isPrivateFilter = null;
    await _applyFilters();
  }

  /// 应用筛选条件
  Future<void> _applyFilters() async {
    try {
      if (_searchKeyword.isNotEmpty) {
        _filteredRecords = await _travelService.searchRecords(_searchKeyword);
      } else {
        _filteredRecords = await _travelService.filterRecords(
          city: _selectedCity,
          province: _selectedProvince,
          mood: _selectedMood,
          tags: _selectedTags.isNotEmpty ? _selectedTags : null,
          startDate: _startDate,
          endDate: _endDate,
          isPrivate: _isPrivateFilter,
        );
      }
      notifyListeners();
    } catch (e) {
      _setError('筛选记录失败: $e');
    }
  }

  /// 获取当前位置
  Future<LocationInfo?> getCurrentLocation() async {
    try {
      return await _locationService.getCurrentLocation();
    } catch (e) {
      _setError('获取位置失败: $e');
      return null;
    }
  }

  /// 地理编码
  Future<LocationInfo?> geocodeAddress(String address) async {
    try {
      return await _locationService.geocodeAddress(address);
    } catch (e) {
      _setError('地址解析失败: $e');
      return null;
    }
  }

  /// 搜索周边POI
  Future<List<PoiInfo>> searchNearbyPoi({
    required double latitude,
    required double longitude,
    String keywords = '',
    int radius = 1000,
  }) async {
    try {
      return await _locationService.searchNearbyPoi(
        latitude: latitude,
        longitude: longitude,
        keywords: keywords,
        radius: radius,
      );
    } catch (e) {
      _setError('搜索周边失败: $e');
      return [];
    }
  }

  /// 添加媒体文件
  Future<MediaItem?> addMediaFromCamera({
    required MediaType type,
    String? caption,
  }) async {
    try {
      return await _travelService.addMediaFromCamera(
        type: type,
        caption: caption,
      );
    } catch (e) {
      _setError('添加媒体失败: $e');
      return null;
    }
  }

  /// 从相册添加媒体
  Future<MediaItem?> addMediaFromGallery({
    required MediaType type,
    String? caption,
  }) async {
    try {
      return await _travelService.addMediaFromGallery(
        type: type,
        caption: caption,
      );
    } catch (e) {
      _setError('添加媒体失败: $e');
      return null;
    }
  }

  /// 获取所有城市列表
  List<String> getAllCities() {
    final cities = <String>{};
    for (final record in _records) {
      if (record.location.city != null) {
        cities.add(record.location.city!);
      }
    }
    return cities.toList()..sort();
  }

  /// 获取所有省份列表
  List<String> getAllProvinces() {
    final provinces = <String>{};
    for (final record in _records) {
      if (record.location.province != null) {
        provinces.add(record.location.province!);
      }
    }
    return provinces.toList()..sort();
  }

  /// 获取所有标签列表
  List<String> getAllTags() {
    final tags = <String>{};
    for (final record in _records) {
      tags.addAll(record.tags);
    }
    return tags.toList()..sort();
  }

  /// 获取所有心情列表
  List<String> getAllMoods() {
    final moods = <String>{};
    for (final record in _records) {
      moods.add(record.mood);
    }
    return moods.toList()..sort();
  }

  /// 清空所有数据
  Future<void> clearAllData() async {
    try {
      _setLoading(true);
      await _travelService.clearAllData();
      _records.clear();
      _filteredRecords.clear();
      _stats = null;
      await clearFilters();
    } catch (e) {
      _setError('清空数据失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // ========== 向后兼容的方法（用于测试） ==========

  /// 向后兼容：获取travels列表
  List<Travel> get travels {
    return _filteredRecords.map((record) => _convertToTravel(record)).toList();
  }

  /// 向后兼容：加载travels
  Future<void> loadTravels() async {
    await _loadRecords();
  }

  /// 向后兼容：添加travel
  Future<void> addTravel(Travel travel, {String? mood}) async {
    final record = _convertToTravelRecord(travel);
    await addRecord(record);
  }

  /// 向后兼容：删除travel
  Future<void> deleteTravel(String id) async {
    await deleteRecord(id);
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
      photos: record.mediaItems.where((item) => item.type == 'photo').map((item) => item.path).toList(),
      date: record.createdAt,
      isFavorite: record.rating != null && record.rating! >= 4.0,
    );
  }

  /// 将Travel转换为TravelRecord
  TravelRecord _convertToTravelRecord(Travel travel) {
    return TravelRecord(
      id: travel.id,
      title: travel.title,
      description: travel.description,
      location: LocationInfo(
        address: travel.locationName,
        latitude: travel.latitude,
        longitude: travel.longitude,
      ),
      mediaItems: travel.photos.map((photo) => MediaItem(
        path: photo,
        type: 'photo',
      )).toList(),
      mood: travel.mood,
      tags: travel.tags,
      companions: [],
      createdAt: travel.date,
      rating: travel.isFavorite ? 5.0 : null,
    );
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String recordId) async {
    try {
      final recordIndex = _records.indexWhere((r) => r.id == recordId);
      if (recordIndex != -1) {
        final record = _records[recordIndex];
        final updatedRecord = record.copyWith(
          rating: record.rating != null && record.rating! >= 4.0 ? null : 5.0,
        );
        _records[recordIndex] = updatedRecord;
        await _travelService.saveRecord(updatedRecord);
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = '切换收藏状态失败: $e';
      notifyListeners();
    }
  }
}
