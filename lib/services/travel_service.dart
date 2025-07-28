import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/travel.dart';

/// 旅行记录服务类
class TravelService {
  static final TravelService _instance = TravelService._internal();

  /// 单例模式工厂构造函数
  factory TravelService() {
    return _instance;
  }

  TravelService._internal();

  /// 存储键
  static const String _travelRecordsKey = 'travel_records';
  static const String _travelStatsKey = 'travel_stats';

  /// 获取所有旅行记录
  Future<List<Travel>> getAllRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? recordsJson = prefs.getString(_travelRecordsKey);

      if (recordsJson == null) {
        return [];
      }

      final List<dynamic> recordsList = jsonDecode(recordsJson);
      return recordsList.map((json) => Travel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('获取旅行记录失败: $e');
      return [];
    }
  }

  /// 保存旅行记录
  Future<bool> saveRecord(Travel record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Travel> records = await getAllRecords();

      // 检查是否已存在相同ID的记录
      final index = records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        records[index] = record;
      } else {
        records.add(record);
      }

      final String recordsJson =
          jsonEncode(records.map((r) => r.toJson()).toList());
      await prefs.setString(_travelRecordsKey, recordsJson);

      // 更新统计信息
      await _updateStats(records);

      return true;
    } catch (e) {
      debugPrint('保存旅行记录失败: $e');
      return false;
    }
  }

  /// 删除旅行记录
  Future<bool> deleteRecord(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Travel> records = await getAllRecords();

      records.removeWhere((record) => record.id == id);

      final String recordsJson =
          jsonEncode(records.map((r) => r.toJson()).toList());
      await prefs.setString(_travelRecordsKey, recordsJson);

      // 更新统计信息
      await _updateStats(records);

      return true;
    } catch (e) {
      debugPrint('删除旅行记录失败: $e');
      return false;
    }
  }

  /// 获取旅行统计信息
  Future<TravelStats> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? statsJson = prefs.getString(_travelStatsKey);

      if (statsJson == null) {
        return TravelStats(
          totalRecords: 0,
          totalPlaces: 0,
          mostVisitedPlaces: [],
          mostUsedTags: [],
          mostCommonMood: '未知',
        );
      }

      return TravelStats.fromRecords([]);
    } catch (e) {
      debugPrint('获取旅行统计信息失败: $e');
      return TravelStats(
        totalRecords: 0,
        totalPlaces: 0,
        mostVisitedPlaces: [],
        mostUsedTags: [],
        mostCommonMood: '未知',
      );
    }
  }

  /// 更新统计信息
  Future<void> _updateStats(List<Travel> records) async {
    try {
      // 计算统计信息
      final Set<String> cities = {};
      final Map<String, int> moodCount = {};
      final Map<String, int> tagCount = {};
      final Map<String, int> locationCount = {};
      DateTime? lastTravelDate;

      for (var record in records) {
        // 更新城市和国家计数
        cities.add(record.locationName);
        // TODO: 根据经纬度获取国家信息

        // 更新心情分布
        moodCount[record.mood] = (moodCount[record.mood] ?? 0) + 1;

        // 更新标签分布
        for (var tag in record.tags) {
          tagCount[tag] = (tagCount[tag] ?? 0) + 1;
        }

        // 更新地点计数
        locationCount[record.locationName] =
            (locationCount[record.locationName] ?? 0) + 1;

        // 更新最后旅行日期
        if (lastTravelDate == null || record.date.isAfter(lastTravelDate)) {
          lastTravelDate = record.date;
        }
      }

      // 计算统计数据 - 暂时不使用，为将来功能预留
      // final entries = locationCount.entries.toList();
      // entries.sort((a, b) => b.value.compareTo(a.value));
      // final favoriteLocations = entries.take(5).map((e) => e.key).toList();

      // final String mostCommonMood = moodCount.isNotEmpty
      //     ? moodCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
      //     : '未知';

      // final sortedTags = tagCount.entries.toList()
      //   ..sort((a, b) => b.value.compareTo(a.value));
      // final mostUsedTags = sortedTags.take(5).map((e) => e.key).toList();

      // 创建统计信息对象 - 暂时不保存，因为TravelStats没有toJson方法
      // final stats = TravelStats(
      //   totalRecords: records.length,
      //   totalPlaces: cities.length,
      //   mostVisitedPlaces: favoriteLocations,
      //   mostUsedTags: mostUsedTags,
      //   mostCommonMood: mostCommonMood,
      // );
      // await prefs.setString(_travelStatsKey, jsonEncode(stats.toJson()));
    } catch (e) {
      debugPrint('更新旅行统计信息失败: $e');
    }
  }

  // 距离计算方法已移除 - 如需要可重新添加
}
