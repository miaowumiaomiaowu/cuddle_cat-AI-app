import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryEvent {
  final String id;
  final DateTime timestamp;
  final String type; // 'breakthrough', 'achievement', 'growth'
  final String summary;
  final List<String> tags;
  final String? evidence; // 对话片段或打卡记录
  final double significance; // 0.0-1.0 重要程度

  MemoryEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.summary,
    required this.tags,
    this.evidence,
    this.significance = 0.5,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'summary': summary,
    'tags': tags,
    'evidence': evidence,
    'significance': significance,
  };

  factory MemoryEvent.fromJson(Map<String, dynamic> json) => MemoryEvent(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    type: json['type'] as String,
    summary: json['summary'] as String,
    tags: List<String>.from(json['tags'] as List),
    evidence: json['evidence'] as String?,
    significance: (json['significance'] as num?)?.toDouble() ?? 0.5,
  );
}

class MemoryService {
  static const String _memoryKey = 'user_memories';
  static const String _lastReviewKey = 'last_memory_review';

  Future<List<MemoryEvent>> getMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_memoryKey);
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonStr);
    return jsonList.map((json) => MemoryEvent.fromJson(json)).toList();
  }

  Future<void> saveMemory(MemoryEvent memory) async {
    final memories = await getMemories();
    memories.add(memory);
    await _saveMemories(memories);
  }

  Future<void> updateMemory(MemoryEvent updated) async {
    final memories = await getMemories();
    final idx = memories.indexWhere((m) => m.id == updated.id);
    if (idx >= 0) {
      memories[idx] = updated;
      await _saveMemories(memories);
    }
  }

  Future<void> deleteMemory(String id) async {
    final memories = await getMemories();
    memories.removeWhere((m) => m.id == id);
    await _saveMemories(memories);
  }

  Future<void> clearMemories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_memoryKey);
  }

  Future<void> _saveMemories(List<MemoryEvent> memories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(memories.map((m) => m.toJson()).toList());
    await prefs.setString(_memoryKey, jsonStr);
  }

  Future<List<MemoryEvent>> getRecentBreakthroughs({int days = 30}) async {
    final memories = await getMemories();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return memories
        .where((m) => m.timestamp.isAfter(cutoff) && m.type == 'breakthrough')
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<bool> shouldShowReview() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReview = prefs.getString(_lastReviewKey);
    if (lastReview == null) return true;
    
    final lastDate = DateTime.parse(lastReview);
    final daysSince = DateTime.now().difference(lastDate).inDays;
    return daysSince >= 7; // 每周提醒一次
  }

  Future<void> markReviewShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastReviewKey, DateTime.now().toIso8601String());
  }

  Future<List<MemoryEvent>> getMemoriesByTag(String tag) async {
    final memories = await getMemories();
    return memories.where((m) => m.tags.contains(tag)).toList();
  }

  Future<void> detectAndSaveBreakthrough({
    required String context,
    required List<String> keywords,
    required String summary,
  }) async {
    // 简单的突破检测逻辑
    final breakthrough = MemoryEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: 'breakthrough',
      summary: summary,
      tags: keywords,
      evidence: context,
      significance: 0.8,
    );
    
    await saveMemory(breakthrough);
  }
}
