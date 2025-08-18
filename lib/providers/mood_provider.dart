import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/mood_record.dart';
import '../providers/user_provider.dart';

/// 心情记录状态管理 - 专注于心理治愈
class MoodProvider extends ChangeNotifier {
  final UserProvider? _userProvider;

  List<MoodEntry> _moodEntries = [];
  MoodAnalytics? _analytics;
  bool _isLoading = false;
  String? _error;

  MoodProvider([this._userProvider]);

  // Getters
  List<MoodEntry> get moodEntries => List.unmodifiable(_moodEntries);
  MoodAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasEntries => _moodEntries.isNotEmpty;

  /// 获取当前用户ID
  String? get _currentUserId => _userProvider?.currentUser?.id;

  /// 初始化
  Future<void> initialize() async {
    await loadMoodEntries();
  }

  /// 加载心情记录
  Future<void> loadMoodEntries() async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUserId == null) {
        debugPrint('用户未登录，无法加载心情记录');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final key = 'mood_entries_${_currentUserId}';
      final entriesJson = prefs.getStringList(key) ?? [];

      _moodEntries = entriesJson
          .map((json) => MoodEntry.fromJson(jsonDecode(json)))
          .where((entry) => entry.userId == _currentUserId) // 确保只加载当前用户的记录
          .toList();

      // 若无记录，注入一次性开发样本
      if (_moodEntries.isEmpty) {
        final seeded = prefs.getBool('dev_seeded_moods_v1') ?? false;
        if (!seeded) {
          final now = DateTime.now();
          final sample = <MoodEntry>[
            MoodTypeConfig.createMoodEntry(
              userId: _currentUserId!,
              moodType: MoodType.anxious,
              intensity: 7,
              description: '接连加班，心里有些慌张',
              tags: const ['工作','压力'],
            ).copyWith(timestamp: now.subtract(const Duration(days: 3, hours: 2))),
            MoodTypeConfig.createMoodEntry(
              userId: _currentUserId!,
              moodType: MoodType.sad,
              intensity: 6,
              description: '和同事争执了一下，心情低落',
              tags: const ['人际'],
            ).copyWith(timestamp: now.subtract(const Duration(days: 2, hours: 4))),
            MoodTypeConfig.createMoodEntry(
              userId: _currentUserId!,
              moodType: MoodType.neutral,
              intensity: 4,
              description: '晚上散步放松了一会儿',
              tags: const ['运动','放松'],
            ).copyWith(timestamp: now.subtract(const Duration(days: 1, hours: 6))),
            MoodTypeConfig.createMoodEntry(
              userId: _currentUserId!,
              moodType: MoodType.happy,
              intensity: 7,
              description: '决定明天早起跑步给自己打气',
              tags: const ['计划','自我激励'],
            ).copyWith(timestamp: now.subtract(const Duration(hours: 12))),
          ];
          _moodEntries = sample;
          // 写回本地，确保各页面可见
          final jsonList = _moodEntries.map((e) => jsonEncode(e.toJson())).toList();
          await prefs.setStringList(key, jsonList);
          await prefs.setBool('dev_seeded_moods_v1', true);
        }
      }

      // 按时间倒序排列
      _moodEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _updateAnalytics();
      debugPrint('加载了 ${_moodEntries.length} 条心情记录');
    } catch (e) {
      _setError('加载心情记录失败: $e');
      debugPrint('加载心情记录失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 保存心情记录到本地
  Future<void> _saveMoodEntries() async {
    try {
      if (_currentUserId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final key = 'mood_entries_$_currentUserId';
      final entriesJson = _moodEntries
          .where((entry) => entry.userId == _currentUserId) // 只保存当前用户的记录
          .map((entry) => jsonEncode(entry.toJson()))
          .toList();

      await prefs.setStringList(key, entriesJson);
      debugPrint('保存了 ${entriesJson.length} 条心情记录');
    } catch (e) {
      debugPrint('保存心情记录失败: $e');
      throw Exception('保存心情记录失败: $e');
    }
  }

  /// 添加心情记录
  Future<void> addMoodEntry(MoodEntry entry) async {
    try {
      _clearError();

      if (_currentUserId == null) {
        throw Exception('用户未登录');
      }

      // 确保记录属于当前用户
      final userEntry = entry.copyWith(userId: _currentUserId);

      _moodEntries.insert(0, userEntry);
      await _saveMoodEntries();
      _updateAnalytics();

      // 更新用户统计
      await _userProvider?.incrementMoodEntryCount();

      // 检查成就
      await _checkAchievements();

      debugPrint('添加心情记录: ${MoodTypeConfig.getMoodName(entry.mood)} ${entry.emoji}');
      notifyListeners();
    } catch (e) {
      _setError('添加心情记录失败: $e');
      debugPrint('添加心情记录失败: $e');
    }
  }

  /// 删除心情记录
  Future<void> deleteMoodEntry(String entryId) async {
    try {
      _clearError();

      _moodEntries.removeWhere((entry) => entry.id == entryId);
      await _saveMoodEntries();
      _updateAnalytics();

      debugPrint('删除心情记录: $entryId');
      notifyListeners();
    } catch (e) {
      _setError('删除心情记录失败: $e');
      debugPrint('删除心情记录失败: $e');
    }
  }

  /// 更新心情记录
  Future<void> updateMoodEntry(MoodEntry updatedEntry) async {
    try {
      _clearError();

      final index = _moodEntries.indexWhere((entry) => entry.id == updatedEntry.id);
      if (index != -1) {
        // 确保记录属于当前用户
        final userEntry = updatedEntry.copyWith(userId: _currentUserId);
        _moodEntries[index] = userEntry;
        await _saveMoodEntries();
        _updateAnalytics();

        debugPrint('更新心情记录: ${MoodTypeConfig.getMoodName(updatedEntry.mood)}');
        notifyListeners();
      }
    } catch (e) {
      _setError('更新心情记录失败: $e');
      debugPrint('更新心情记录失败: $e');
    }
  }

  /// 根据日期范围获取心情记录
  List<MoodEntry> getMoodEntriesByDateRange(DateTime startDate, DateTime endDate) {
    return _moodEntries.where((entry) {
      return entry.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
             entry.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// 根据心情类型获取记录
  List<MoodEntry> getMoodEntriesByType(MoodType moodType) {
    return _moodEntries.where((entry) => entry.mood == moodType).toList();
  }

  /// 根据标签获取记录
  List<MoodEntry> getMoodEntriesByTag(String tag) {
    return _moodEntries.where((entry) => entry.tags.contains(tag)).toList();
  }

  /// 获取积极心情记录
  List<MoodEntry> getPositiveMoodEntries() {
    return _moodEntries.where((entry) => entry.isPositive).toList();
  }

  /// 获取消极心情记录
  List<MoodEntry> getNegativeMoodEntries() {
    return _moodEntries.where((entry) => entry.isNegative).toList();
  }

  /// 获取今天的心情记录
  List<MoodEntry> getTodayMoodEntries() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _moodEntries.where((entry) {
      return entry.timestamp.isAfter(startOfDay) && entry.timestamp.isBefore(endOfDay);
    }).toList();
  }

  /// 获取本周的心情记录
  List<MoodEntry> getWeeklyMoodEntries() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));

    return _moodEntries.where((entry) {
      return entry.timestamp.isAfter(startOfWeekDay) && entry.timestamp.isBefore(endOfWeek);
    }).toList();
  }

  /// 获取本月的心情记录
  List<MoodEntry> getMonthlyMoodEntries() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    return _moodEntries.where((entry) {
      return entry.timestamp.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
             entry.timestamp.isBefore(endOfMonth);
    }).toList();
  }

  /// 快速添加心情记录
  Future<void> quickAddMood(MoodType moodType, {
    String? description,
    int intensity = 5,
    List<String> tags = const [],
    String? trigger,
    List<String> gratitude = const [],
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('用户未登录');
      }

      final entry = MoodTypeConfig.createMoodEntry(
        userId: _currentUserId!,
        moodType: moodType,
        intensity: intensity,
        description: description,
        tags: tags,
        trigger: trigger,
        gratitude: gratitude,
      );

      await addMoodEntry(entry);
    } catch (e) {
      _setError('快速添加心情失败: $e');
      debugPrint('快速添加心情失败: $e');
    }
  }

  /// 添加感恩记录
  Future<void> addGratitudeEntry(List<String> gratitudeList, {
    MoodType moodType = MoodType.grateful,
    int intensity = 7,
    String? description,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('用户未登录');
      }

      final entry = MoodTypeConfig.createMoodEntry(
        userId: _currentUserId!,
        moodType: moodType,
        intensity: intensity,
        description: description,
        tags: ['感恩'],
        gratitude: gratitudeList,
      );

      await addMoodEntry(entry);
    } catch (e) {
      _setError('添加感恩记录失败: $e');
      debugPrint('添加感恩记录失败: $e');
    }
  }

  /// 清除所有心情记录
  Future<void> clearAllMoodEntries() async {
    try {
      _clearError();

      _moodEntries.clear();
      await _saveMoodEntries();
      _updateAnalytics();

      debugPrint('清除所有心情记录');
      notifyListeners();
    } catch (e) {
      _setError('清除心情记录失败: $e');
      debugPrint('清除心情记录失败: $e');
    }
  }

  /// 更新分析数据
  void _updateAnalytics() {
    if (_moodEntries.isNotEmpty) {
      _analytics = MoodAnalytics.fromEntries(_moodEntries);
    } else {
      _analytics = null;
    }
  }

  /// 检查成就
  Future<void> _checkAchievements() async {
    if (_userProvider == null) return;

    final totalEntries = _moodEntries.length;
    final gratitudeEntries = _moodEntries.where((e) => e.gratitude.isNotEmpty).length;
    final consecutiveDays = _userProvider!.consecutiveDays;

    // 检查各种成就
    if (totalEntries >= 1 && !_userProvider!.hasAchievement('first_mood')) {
      await _userProvider!.addAchievement('first_mood');
    }

    if (totalEntries >= 7 && !_userProvider!.hasAchievement('week_recorder')) {
      await _userProvider!.addAchievement('week_recorder');
    }

    if (totalEntries >= 30 && !_userProvider!.hasAchievement('month_recorder')) {
      await _userProvider!.addAchievement('month_recorder');
    }

    if (gratitudeEntries >= 10 && !_userProvider!.hasAchievement('gratitude_master')) {
      await _userProvider!.addAchievement('gratitude_master');
    }

    if (consecutiveDays >= 7 && !_userProvider!.hasAchievement('week_streak')) {
      await _userProvider!.addAchievement('week_streak');
    }
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 设置错误信息
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// 获取心情趋势数据（用于图表）
  Map<String, double> getMoodTrendData(int days) {
    final now = DateTime.now();
    final Map<String, double> trendData = {};

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';

      final dayEntries = _moodEntries.where((entry) {
        return entry.timestamp.year == date.year &&
               entry.timestamp.month == date.month &&
               entry.timestamp.day == date.day;
      }).toList();

      if (dayEntries.isNotEmpty) {
        final averageIntensity = dayEntries
            .map((e) => e.intensity)
            .reduce((a, b) => a + b) / dayEntries.length;
        trendData[dateKey] = averageIntensity;
      } else {
        trendData[dateKey] = 0.0;
      }
    }

    return trendData;
  }

  /// 获取心情分布数据（用于饼图）
  Map<String, double> getMoodDistributionData() {
    if (_analytics == null) return {};

    final total = _analytics!.totalEntries.toDouble();
    if (total == 0) return {};

    return _analytics!.moodDistribution.map((mood, count) {
      return MapEntry(MoodTypeConfig.getMoodName(mood), count / total * 100);
    });
  }

  /// 获取积极心情占比
  double get positiveRatio {
    return _analytics?.positiveRatio ?? 0.0;
  }

  /// 获取消极心情占比
  double get negativeRatio {
    return _analytics?.negativeRatio ?? 0.0;
  }

  /// 获取平均心情强度
  double get averageIntensity {
    return _analytics?.averageIntensity ?? 5.0;
  }

  /// 获取改善分数
  double get improvementScore {
    return _analytics?.improvementScore ?? 50.0;
  }

  /// 获取主导心情
  MoodType get dominantMood {
    return _analytics?.dominantMood ?? MoodType.neutral;
  }

  /// 获取洞察建议
  List<String> get insights {
    return _analytics?.insights ?? [];
  }

  /// 获取推荐建议
  List<String> get recommendations {
    return _analytics?.recommendations ?? [];
  }

  /// 获取成就列表
  List<Achievement> get achievements {
    return _analytics?.achievements ?? [];
  }

  /// 今天是否已记录心情
  bool get hasTodayEntry {
    return getTodayMoodEntries().isNotEmpty;
  }

  /// 获取连续记录天数
  int get consecutiveDays {
    if (_moodEntries.isEmpty) return 0;

    final now = DateTime.now();
    int days = 0;

    for (int i = 0; i < 365; i++) { // 最多检查一年
      final checkDate = now.subtract(Duration(days: i));
      final hasEntry = _moodEntries.any((entry) =>
        entry.timestamp.year == checkDate.year &&
        entry.timestamp.month == checkDate.month &&
        entry.timestamp.day == checkDate.day
      );

      if (hasEntry) {
        days++;
      } else {
        break;
      }
    }

    return days;
  }

  /// 获取本周积极心情天数
  int get weeklyPositiveDays {
    final weeklyEntries = getWeeklyMoodEntries();
    final positiveDays = <String>{};

    for (final entry in weeklyEntries) {
      if (entry.isPositive) {
        final dayKey = '${entry.timestamp.year}-${entry.timestamp.month}-${entry.timestamp.day}';
        positiveDays.add(dayKey);
      }
    }

    return positiveDays.length;
  }
}
