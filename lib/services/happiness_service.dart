import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/happiness_task.dart';
import '../models/happiness_checkin.dart';
import '../models/happiness_stats.dart';

class HappinessService {
  static HappinessService? _instance;
  static HappinessService get instance => _instance ??= HappinessService._();
  HappinessService._();

  static const String _tasksKey = 'happiness_tasks_v1';
  static const String _checkinsKey = 'happiness_checkins_v1';
  static const String _statsKey = 'happiness_stats_v1';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Future<List<HappinessTask>> getAllTasks() async {
    await initialize();
    final list = _prefs.getStringList(_tasksKey) ?? const [];
    return list.map((s) => HappinessTask.fromJson(jsonDecode(s))).toList();
  }

  Future<bool> saveTask(HappinessTask task) async {
    await initialize();
    final tasks = await getAllTasks();
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      tasks[idx] = task.copyWith(updatedAt: DateTime.now());
    } else {
      tasks.add(task);
    }
    final data = tasks.map((t) => jsonEncode(t.toJson())).toList();
    return _prefs.setStringList(_tasksKey, data);
  }

  Future<bool> deleteTask(String id) async {
    await initialize();
    final tasks = await getAllTasks();
    tasks.removeWhere((t) => t.id == id);
    return _prefs.setStringList(_tasksKey, tasks.map((t) => jsonEncode(t.toJson())).toList());
  }

  Future<List<HappinessCheckin>> getAllCheckins() async {
    await initialize();
    final list = _prefs.getStringList(_checkinsKey) ?? const [];
    return list.map((s) => HappinessCheckin.fromJson(jsonDecode(s))).toList();
  }

  Future<bool> saveCheckin(HappinessCheckin checkin) async {
    await initialize();
    final checkins = await getAllCheckins();
    final idx = checkins.indexWhere((c) => c.id == checkin.id);
    if (idx >= 0) {
      checkins[idx] = checkin;
    } else {
      checkins.add(checkin);
    }
    final data = checkins.map((c) => jsonEncode(c.toJson())).toList();
    final ok = await _prefs.setStringList(_checkinsKey, data);
    if (ok) await _updateStats();
    return ok;
  }

  Future<bool> deleteCheckin(String id) async {
    await initialize();
    final checkins = await getAllCheckins();
    checkins.removeWhere((c) => c.id == id);
    final ok = await _prefs.setStringList(_checkinsKey, checkins.map((c) => jsonEncode(c.toJson())).toList());
    if (ok) await _updateStats();
    return ok;
  }

  Future<HappinessStats> getStats() async {
    await initialize();
    final s = _prefs.getString(_statsKey);
    if (s != null) {
      try { return HappinessStats.fromJson(jsonDecode(s)); } catch (_) {}
    }
    return await _calculateStats();
  }

  Future<void> _updateStats() async {
    final stats = await _calculateStats();
    await _prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  Future<HappinessStats> _calculateStats() async {
    final checkins = await getAllCheckins();
    if (checkins.isEmpty) {
      return const HappinessStats();
    }

    // 计算 streak
    final byDate = <String, List<HappinessCheckin>>{};
    for (final c in checkins) {
      byDate.putIfAbsent(c.ymdDate, () => []).add(c);
    }
    int currentStreak = 0, longestStreak = 0;
    DateTime day = DateTime.now();
    while (true) {
      final key = _ymd(day);
      if (byDate.containsKey(key)) {
        currentStreak++;
        if (currentStreak > longestStreak) longestStreak = currentStreak;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // 近7/30天完成率（以“是否有任意打卡”为近似）
    double rateInDays(int n) {
      int daysWith = 0;
      final now = DateTime.now();
      for (int i = 0; i < n; i++) {
        final d = now.subtract(Duration(days: i));
        if (byDate.containsKey(_ymd(d))) daysWith++;
      }
      return n == 0 ? 0 : daysWith / n;
    }

    // 类别分布与 topTasks（简单按标题频次）
    final categoryDist = <String, int>{};
    final titleCount = <String, int>{};
    // 这里需要任务信息，简化：从 notes 中尝试读取 title 关键词（后续由 Provider 传入任务映射计算更精确）
    for (final c in checkins) {
      final category = 'general';
      categoryDist[category] = (categoryDist[category] ?? 0) + 1;
      if (c.notes != null && c.notes!.isNotEmpty) {
        titleCount[c.notes!] = (titleCount[c.notes!] ?? 0) + 1;
      }
    }
    final top = titleCount.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));

    // 幸福提升（需要 before/after 可用值，简化：字符串枚举转分值由 Provider 计算后写入 notes 可选）
    final avgLift = 0.0;

    return HappinessStats(
      completionRate7d: rateInDays(7),
      completionRate30d: rateInDays(30),
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      categoryDistribution: categoryDist,
      topTasks: top.take(5).map((e)=>e.key).toList(),
      totalCheckins: checkins.length,
      averageLift: avgLift,
    );
  }

  String _ymd(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}

