import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_record.dart';
import '../models/happiness_checkin.dart';

class AdvancedAIService {
  static const String _baseUrlKey = 'ai_analysis_base_url';
  static const String _enabledKey = 'ai_analysis_enabled';
  
  Future<String?> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    if (!enabled) return null;
    
    return prefs.getString(_baseUrlKey);
  }

  Future<Map<String, dynamic>?> analyzeEmotionAdvanced({
    required String text,
    Map<String, dynamic>? context,
  }) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analytics/emotion-advanced'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'context': context ?? {},
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['emotions'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Advanced emotion analysis failed: $e');
    }
    
    return null;
  }

  Future<Map<String, dynamic>?> predictMood({
    required Map<String, dynamic> userContext,
  }) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analytics/predict-mood'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userContext),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Mood prediction failed: $e');
    }
    
    return null;
  }

  Future<Map<String, dynamic>?> analyzeUserClusters({
    required List<Map<String, dynamic>> userData,
  }) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analytics/user-clusters'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('User cluster analysis failed: $e');
    }
    
    return null;
  }

  Future<Map<String, dynamic>?> trainMoodPredictor({
    required List<Map<String, dynamic>> trainingData,
  }) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analytics/train-mood-predictor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(trainingData),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Mood predictor training failed: $e');
    }
    
    return null;
  }

  Map<String, dynamic> buildUserContext({
    required List<MoodEntry> moodRecords,
    required List<HappinessCheckin> checkins,
    Map<String, dynamic>? additionalContext,
  }) {
    final now = DateTime.now();
    
    // 计算最近心情平均分
    double recentMoodAvg = 3.0;
    if (moodRecords.isNotEmpty) {
      final recentMoods = moodRecords.take(7).toList();
      final moodScores = recentMoods.map((m) => _moodToScore(m.mood)).toList();
      recentMoodAvg = moodScores.reduce((a, b) => a + b) / moodScores.length;
    }

    // 计算连击长度
    int streakLength = 0;
    if (checkins.isNotEmpty) {
      final sortedCheckins = checkins.toList()
        ..sort((a, b) => b.ymdDate.compareTo(a.ymdDate));
      
      String? lastDate;
      for (final checkin in sortedCheckins) {
        if (lastDate == null) {
          streakLength = 1;
          lastDate = checkin.ymdDate;
        } else {
          final lastDateTime = DateTime.parse('${lastDate}T00:00:00');
          final currentDateTime = DateTime.parse('${checkin.ymdDate}T00:00:00');
          final daysDiff = lastDateTime.difference(currentDateTime).inDays;
          
          if (daysDiff == 1) {
            streakLength++;
            lastDate = checkin.ymdDate;
          } else {
            break;
          }
        }
      }
    }

    // 计算今日完成任务数
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayTasks = checkins.where((c) => c.ymdDate == today).length;

    final context = {
      'hour_of_day': now.hour,
      'day_of_week': now.weekday,
      'weather_score': 3, // 默认值，可以从天气服务获取
      'tasks_completed_today': todayTasks,
      'recent_mood_avg': recentMoodAvg,
      'streak_length': streakLength,
      'sleep_quality': 3, // 默认值，可以从用户输入获取
      'social_interaction': 0, // 默认值，可以从聊天记录分析
    };

    if (additionalContext != null) {
      for (final entry in additionalContext.entries) {
        context[entry.key] = entry.value;
      }
    }

    return context;
  }

  List<Map<String, dynamic>> buildTrainingData({
    required List<MoodEntry> moodRecords,
    required List<HappinessCheckin> checkins,
  }) {
    final trainingData = <Map<String, dynamic>>[];

    for (final mood in moodRecords) {
      final moodDate = mood.timestamp;
      
      // 获取该日期的上下文信息
      final dayCheckins = checkins.where((c) {
        final checkinDate = DateTime.parse('${c.ymdDate}T12:00:00');
        return checkinDate.year == moodDate.year &&
               checkinDate.month == moodDate.month &&
               checkinDate.day == moodDate.day;
      }).toList();

      // 计算该日期前的连击长度
      int streakAtDate = 0;
      final checkinsBeforeDate = checkins.where((c) {
        final checkinDate = DateTime.parse('${c.ymdDate}T12:00:00');
        return checkinDate.isBefore(moodDate);
      }).toList()
        ..sort((a, b) => b.ymdDate.compareTo(a.ymdDate));

      if (checkinsBeforeDate.isNotEmpty) {
        String? lastDate;
        for (final checkin in checkinsBeforeDate) {
          if (lastDate == null) {
            streakAtDate = 1;
            lastDate = checkin.ymdDate;
          } else {
            final lastDateTime = DateTime.parse('${lastDate}T00:00:00');
            final currentDateTime = DateTime.parse('${checkin.ymdDate}T00:00:00');
            final daysDiff = lastDateTime.difference(currentDateTime).inDays;
            
            if (daysDiff == 1) {
              streakAtDate++;
              lastDate = checkin.ymdDate;
            } else {
              break;
            }
          }
        }
      }

      final trainingRecord = {
        'hour_of_day': moodDate.hour,
        'day_of_week': moodDate.weekday,
        'weather_score': 3, // 可以从历史天气数据获取
        'tasks_completed_today': dayCheckins.length,
        'recent_mood_avg': _calculateRecentMoodAvg(moodRecords, moodDate),
        'streak_length': streakAtDate,
        'sleep_quality': 3, // 默认值
        'social_interaction': 0, // 默认值
        'mood_score': _moodToScore(mood.mood),
      };

      trainingData.add(trainingRecord);
    }

    return trainingData;
  }

  double _moodToScore(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return 5.0;
      case MoodType.neutral:
        return 4.0;
      case MoodType.sad:
        return 2.0;
      case MoodType.angry:
        return 1.0;
      case MoodType.excited:
        return 4.5;
      case MoodType.grateful:
        return 4.0;
      case MoodType.peaceful:
        return 4.0;
      case MoodType.confident:
        return 4.5;
      case MoodType.loving:
        return 4.5;
      case MoodType.tired:
        return 2.5;
      case MoodType.bored:
        return 2.0;
      case MoodType.anxious:
        return 1.5;
      case MoodType.frustrated:
        return 1.5;
      case MoodType.lonely:
        return 2.0;
      case MoodType.stressed:
        return 1.5;
    }
  }

  double _calculateRecentMoodAvg(List<MoodEntry> allMoods, DateTime targetDate) {
    final recentMoods = allMoods.where((m) {
      final daysDiff = targetDate.difference(m.timestamp).inDays;
      return daysDiff >= 0 && daysDiff <= 7;
    }).toList();

    if (recentMoods.isEmpty) return 3.0;

    final scores = recentMoods.map((m) => _moodToScore(m.mood)).toList();
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  Map<String, dynamic> buildUserProfile({
    required List<MoodEntry> moodRecords,
    required List<HappinessCheckin> checkins,
    required Map<String, dynamic> userStats,
  }) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // 计算活跃天数
    final activeDays = checkins
        .where((c) => DateTime.parse('${c.ymdDate}T00:00:00').isAfter(thirtyDaysAgo))
        .map((c) => c.ymdDate)
        .toSet()
        .length;

    // 计算完成率
    final totalTasks = checkins.length;
    final completionRate = totalTasks > 0 ? 1.0 : 0.0; // 简化计算

    // 计算最大连击
    int maxStreak = 0;
    int currentStreak = 0;
    String? lastDate;

    final sortedCheckins = checkins.toList()
      ..sort((a, b) => a.ymdDate.compareTo(b.ymdDate));

    for (final checkin in sortedCheckins) {
      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final lastDateTime = DateTime.parse('${lastDate}T00:00:00');
        final currentDateTime = DateTime.parse('${checkin.ymdDate}T00:00:00');
        final daysDiff = currentDateTime.difference(lastDateTime).inDays;

        if (daysDiff == 1) {
          currentStreak++;
        } else {
          maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
          currentStreak = 1;
        }
      }
      lastDate = checkin.ymdDate;
    }
    maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;

    // 计算平均心情分数
    double avgMoodScore = 3.0;
    if (moodRecords.isNotEmpty) {
      final scores = moodRecords.map((m) => _moodToScore(m.mood)).toList();
      avgMoodScore = scores.reduce((a, b) => a + b) / scores.length;
    }

    return {
      'total_tasks_completed': totalTasks,
      'avg_session_duration': 15.0, // 默认值
      'days_active': activeDays,
      'max_streak': maxStreak,
      'avg_mood_score': avgMoodScore,
      'total_gifts_received': userStats['totalGifts'] ?? 0,
      'completion_rate': completionRate,
      'preferred_categories': [], // 可以从任务分析中获取
      'evening_activity_ratio': 0.3, // 默认值
      'weekend_activity_ratio': 0.2, // 默认值
    };
  }
}
