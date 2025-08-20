import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/happiness_task.dart';
import '../models/mood_record.dart';
import 'feedback_service.dart';

class RealTimeLearningService {
  static const String _baseUrlKey = 'ai_analysis_base_url';
  static const String _enabledKey = 'ai_analysis_enabled';
  
  final FeedbackService _feedbackService = FeedbackService();
  
  Future<String?> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    if (!enabled) return null;
    
    return prefs.getString(_baseUrlKey);
  }

  Future<void> recordTaskInteraction({
    required String taskId,
    required String taskTitle,
    required String category,
    required String action, // 'started', 'completed', 'skipped', 'liked', 'disliked'
    Map<String, dynamic>? context,
  }) async {
    try {
      // 构建反馈数据
      final feedback = await _buildInteractionFeedback(
        taskId: taskId,
        taskTitle: taskTitle,
        category: category,
        action: action,
        context: context,
      );
      
      // 本地记录
      await _recordLocalFeedback(feedback);
      
      // 发送到服务端进行在线学习
      await _sendLearningFeedback(feedback);
      
    } catch (e) {
      debugPrint('Task interaction recording failed: $e');
    }
  }

  Future<Map<String, dynamic>> _buildInteractionFeedback({
    required String taskId,
    required String taskTitle,
    required String category,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    final now = DateTime.now();
    
    // 基础反馈数据
    final feedback = {
      'giftId': taskId,
      'giftTitle': taskTitle,
      'category': category,
      'action': action,
      'timestamp': now.toIso8601String(),
      'hour_of_day': now.hour,
      'day_of_week': now.weekday,
      'weather_score': 3.0, // 可以从天气服务获取
    };
    
    // 添加上下文信息
    if (context != null) {
      for (final entry in context.entries) {
        feedback[entry.key] = entry.value;
      }
    }
    
    // 根据动作类型添加特定数据
    switch (action) {
      case 'completed':
        feedback['satisfaction_rating'] = 4.0; // 默认满意度
        feedback['engagement_score'] = 0.8;
        break;
      case 'liked':
        feedback['satisfaction_rating'] = 5.0;
        feedback['engagement_score'] = 0.9;
        break;
      case 'disliked':
        feedback['satisfaction_rating'] = 2.0;
        feedback['engagement_score'] = 0.3;
        break;
      case 'skipped':
        feedback['satisfaction_rating'] = 1.0;
        feedback['engagement_score'] = 0.1;
        break;
    }
    
    return feedback;
  }

  Future<void> _recordLocalFeedback(Map<String, dynamic> feedback) async {
    // 使用现有的反馈服务记录本地数据
    final feedbackType = _mapActionToFeedbackType(feedback['action']);
    
    await _feedbackService.recordFeedback(GiftFeedback(
      giftId: feedback['giftId'],
      giftTitle: feedback['giftTitle'],
      type: feedbackType,
      timestamp: DateTime.parse(feedback['timestamp']),
      rating: feedback['satisfaction_rating']?.round(),
      note: feedback['category'],
    ));
  }

  FeedbackType _mapActionToFeedbackType(String action) {
    switch (action) {
      case 'completed':
        return FeedbackType.completed;
      case 'liked':
        return FeedbackType.like;
      case 'disliked':
        return FeedbackType.dislike;
      case 'skipped':
        return FeedbackType.skipped;
      default:
        return FeedbackType.completed;
    }
  }

  Future<void> _sendLearningFeedback(Map<String, dynamic> feedback) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return;

    try {
      final userId = await _getUserId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'feedback': feedback,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Learning feedback sent successfully');
      } else {
        debugPrint('Learning feedback failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Learning feedback network error: $e');
    }
  }

  Future<void> recordMoodChange({
    required MoodType moodBefore,
    required MoodType moodAfter,
    required String context,
    String? taskId,
  }) async {
    try {
      final feedback = {
        'type': 'mood_change',
        'mood_before': _moodToScore(moodBefore),
        'mood_after': _moodToScore(moodAfter),
        'mood_improvement': _moodToScore(moodAfter) - _moodToScore(moodBefore),
        'context': context,
        'task_id': taskId,
        'timestamp': DateTime.now().toIso8601String(),
        'hour_of_day': DateTime.now().hour,
        'day_of_week': DateTime.now().weekday,
      };
      
      await _sendLearningFeedback(feedback);
      
    } catch (e) {
      debugPrint('Mood change recording failed: $e');
    }
  }

  double _moodToScore(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return 5.0;
      case MoodType.neutral:
        return 3.0;
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

  Future<Map<String, dynamic>?> getLearningSystemStats() async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/learning/system-stats'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Learning stats request failed: $e');
    }
    
    return null;
  }

  Future<bool> updateStrategyWeights(Map<String, double> weights) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/learning/update-strategy-weights'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(weights),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
    } catch (e) {
      debugPrint('Strategy weights update failed: $e');
    }
    
    return false;
  }

  Future<void> recordSessionData({
    required Duration sessionDuration,
    required int tasksViewed,
    required int tasksCompleted,
    required List<String> categoriesExplored,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      final sessionFeedback = {
        'type': 'session_data',
        'session_duration_minutes': sessionDuration.inMinutes,
        'tasks_viewed': tasksViewed,
        'tasks_completed': tasksCompleted,
        'completion_rate': tasksViewed > 0 ? tasksCompleted / tasksViewed : 0.0,
        'categories_explored': categoriesExplored,
        'category_diversity': categoriesExplored.toSet().length,
        'timestamp': DateTime.now().toIso8601String(),
        'hour_of_day': DateTime.now().hour,
        'day_of_week': DateTime.now().weekday,
      };
      
      if (additionalContext != null) {
        for (final entry in additionalContext.entries) {
          sessionFeedback[entry.key] = entry.value;
        }
      }
      
      await _sendLearningFeedback(sessionFeedback);
      
    } catch (e) {
      debugPrint('Session data recording failed: $e');
    }
  }

  Future<void> recordUserPreferenceSignal({
    required String signalType, // 'time_preference', 'category_preference', 'difficulty_preference'
    required Map<String, dynamic> signalData,
  }) async {
    try {
      final preferenceSignal = {
        'type': 'preference_signal',
        'signal_type': signalType,
        'signal_data': signalData,
        'timestamp': DateTime.now().toIso8601String(),
        'hour_of_day': DateTime.now().hour,
        'day_of_week': DateTime.now().weekday,
      };
      
      await _sendLearningFeedback(preferenceSignal);
      
    } catch (e) {
      debugPrint('Preference signal recording failed: $e');
    }
  }

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId != null && userId.isNotEmpty) return userId;
    // 兜底：生成新的访客ID（AuthService 登录后会覆盖为真实用户ID）
    userId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('user_id', userId);
    return userId;
  }

  // 便捷方法
  Future<void> recordTaskStarted(HappinessTask task) async {
    await recordTaskInteraction(
      taskId: task.id,
      taskTitle: task.title,
      category: task.category,
      action: 'started',
      context: {
        'difficulty': task.difficulty ?? 0.5,
        'estimated_duration': 15, // 默认预估时长
      },
    );
  }

  Future<void> recordTaskCompleted(HappinessTask task, {
    Duration? actualDuration,
    int? satisfactionRating,
    MoodType? moodBefore,
    MoodType? moodAfter,
  }) async {
    final context = <String, dynamic>{
      'difficulty': task.difficulty ?? 0.5,
    };
    
    if (actualDuration != null) {
      context['actual_duration_minutes'] = actualDuration.inMinutes;
    }
    
    if (satisfactionRating != null) {
      context['satisfaction_rating'] = satisfactionRating.toDouble();
    }
    
    if (moodBefore != null && moodAfter != null) {
      context['mood_before'] = _moodToScore(moodBefore);
      context['mood_after'] = _moodToScore(moodAfter);
      context['mood_improvement'] = _moodToScore(moodAfter) - _moodToScore(moodBefore);
    }
    
    await recordTaskInteraction(
      taskId: task.id,
      taskTitle: task.title,
      category: task.category,
      action: 'completed',
      context: context,
    );
  }

  Future<void> recordTaskLiked(HappinessTask task) async {
    await recordTaskInteraction(
      taskId: task.id,
      taskTitle: task.title,
      category: task.category,
      action: 'liked',
    );
  }

  Future<void> recordTaskDisliked(HappinessTask task, {String? reason}) async {
    await recordTaskInteraction(
      taskId: task.id,
      taskTitle: task.title,
      category: task.category,
      action: 'disliked',
      context: reason != null ? {'dislike_reason': reason} : null,
    );
  }

  Future<void> recordTaskSkipped(HappinessTask task, {String? reason}) async {
    await recordTaskInteraction(
      taskId: task.id,
      taskTitle: task.title,
      category: task.category,
      action: 'skipped',
      context: reason != null ? {'skip_reason': reason} : null,
    );
  }
}
