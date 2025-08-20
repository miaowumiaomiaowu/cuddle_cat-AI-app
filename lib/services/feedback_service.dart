import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config_service.dart';

enum FeedbackType { like, dislike, completed, skipped }

class GiftFeedback {
  final String giftId;
  final String giftTitle;
  final FeedbackType type;
  final DateTime timestamp;
  final String? note;
  final int? rating; // 1-5 stars

  GiftFeedback({
    required this.giftId,
    required this.giftTitle,
    required this.type,
    required this.timestamp,
    this.note,
    this.rating,
  });

  Map<String, dynamic> toJson() => {
    'giftId': giftId,
    'giftTitle': giftTitle,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
    'rating': rating,
  };

  factory GiftFeedback.fromJson(Map<String, dynamic> json) => GiftFeedback(
    giftId: json['giftId'] as String,
    giftTitle: json['giftTitle'] as String,
    type: FeedbackType.values.firstWhere((e) => e.name == json['type']),
    timestamp: DateTime.parse(json['timestamp'] as String),
    note: json['note'] as String?,
    rating: json['rating'] as int?,
  );
}

class FeedbackService {
  static const String _feedbackKey = 'gift_feedback_history';
  static const String _pendingUploadKey = 'pending_feedback_upload';
  
  Future<void> recordFeedback(GiftFeedback feedback) async {
    // 本地存储
    await _saveFeedbackLocally(feedback);
    
    // 尝试上传到服务端
    await _uploadFeedback(feedback);
  }

  Future<void> _saveFeedbackLocally(GiftFeedback feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_feedbackKey) ?? '[]';
    final List<dynamic> existing = jsonDecode(existingJson);
    
    existing.add(feedback.toJson());
    
    // 只保留最近100条反馈
    if (existing.length > 100) {
      existing.removeRange(0, existing.length - 100);
    }
    
    await prefs.setString(_feedbackKey, jsonEncode(existing));
  }

  Future<void> _uploadFeedback(GiftFeedback feedback) async {
    try {
      final cfg = ConfigService.instance;
      if (!cfg.isRemoteConfigured) {
        await _addToPendingUpload(feedback);
        return;
      }
      final baseUrl = cfg.serverBaseUrl;

      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': await _getUserId(),
          'feedback': feedback.toJson(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        await _addToPendingUpload(feedback);
      }
    } catch (e) {
      // 网络错误，存储到待上传队列
      await _addToPendingUpload(feedback);
    }
  }

  Future<void> _addToPendingUpload(GiftFeedback feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_pendingUploadKey) ?? '[]';
    final List<dynamic> existing = jsonDecode(existingJson);
    
    existing.add(feedback.toJson());
    await prefs.setString(_pendingUploadKey, jsonEncode(existing));
  }

  Future<void> uploadPendingFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(_pendingUploadKey);

    if (pendingJson == null) return;

    final List<dynamic> pending = jsonDecode(pendingJson);
    if (pending.isEmpty) return;

    final cfg = ConfigService.instance;
    if (!cfg.isRemoteConfigured) return;
    final baseUrl = cfg.serverBaseUrl;

    final uploaded = <int>[];
    
    for (int i = 0; i < pending.length; i++) {
      try {
        final feedback = GiftFeedback.fromJson(pending[i]);
        final response = await http.post(
          Uri.parse('$baseUrl/feedback'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': await _getUserId(),
            'feedback': feedback.toJson(),
          }),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          uploaded.add(i);
        }
      } catch (e) {
        // 跳过这条，继续下一条
        continue;
      }
    }

    // 移除已上传的反馈
    for (int i = uploaded.length - 1; i >= 0; i--) {
      pending.removeAt(uploaded[i]);
    }
    
    await prefs.setString(_pendingUploadKey, jsonEncode(pending));
  }

  Future<List<GiftFeedback>> getFeedbackHistory({int days = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_feedbackKey);
    
    if (jsonStr == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    
    return jsonList
        .map((json) => GiftFeedback.fromJson(json))
        .where((feedback) => feedback.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<Map<String, int>> getFeedbackStats() async {
    final history = await getFeedbackHistory();
    final stats = <String, int>{};
    
    for (final feedback in history) {
      stats[feedback.type.name] = (stats[feedback.type.name] ?? 0) + 1;
    }
    
    return stats;
  }

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId != null && userId.isNotEmpty) return userId;
    userId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('user_id', userId);
    return userId;
  }

  // 便捷方法
  Future<void> likegift(String giftId, String giftTitle) async {
    await recordFeedback(GiftFeedback(
      giftId: giftId,
      giftTitle: giftTitle,
      type: FeedbackType.like,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> dislikeGift(String giftId, String giftTitle, {String? reason}) async {
    await recordFeedback(GiftFeedback(
      giftId: giftId,
      giftTitle: giftTitle,
      type: FeedbackType.dislike,
      timestamp: DateTime.now(),
      note: reason,
    ));
  }

  Future<void> completeGift(String giftId, String giftTitle, {int? rating, String? note}) async {
    await recordFeedback(GiftFeedback(
      giftId: giftId,
      giftTitle: giftTitle,
      type: FeedbackType.completed,
      timestamp: DateTime.now(),
      rating: rating,
      note: note,
    ));
  }

  Future<void> skipGift(String giftId, String giftTitle) async {
    await recordFeedback(GiftFeedback(
      giftId: giftId,
      giftTitle: giftTitle,
      type: FeedbackType.skipped,
      timestamp: DateTime.now(),
    ));
  }
}
