import 'package:flutter/foundation.dart';

class PlanGoal {
  final String title;
  final String? rationale;
  final String horizon; // 'weekly' | 'monthly'
  PlanGoal({required this.title, this.rationale, this.horizon = 'weekly'});
  factory PlanGoal.fromJson(Map<String, dynamic> json) => PlanGoal(
    title: json['title'] ?? '',
    rationale: json['rationale'],
    horizon: json['horizon'] ?? 'weekly',
  );
}

class PlanHabit {
  final String title;
  final String category;
  final String frequency; // e.g., '3x/week', 'daily'
  final int? estimatedMinutes;
  final String? reason;
  PlanHabit({required this.title, required this.category, required this.frequency, this.estimatedMinutes, this.reason});
  factory PlanHabit.fromJson(Map<String, dynamic> json) => PlanHabit(
    title: json['title'] ?? '',
    category: json['category'] ?? '',
    frequency: json['frequency'] ?? '',
    estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
    reason: json['reason'],
  );
}

class PlanCheckpoint {
  final int week;
  final String focus;
  final String? metricHint;
  PlanCheckpoint({required this.week, required this.focus, this.metricHint});
  factory PlanCheckpoint.fromJson(Map<String, dynamic> json) => PlanCheckpoint(
    week: (json['week'] as num?)?.toInt() ?? 1,
    focus: json['focus'] ?? '',
    metricHint: json['metricHint'],
  );
}

class WellnessPlan {
  final List<PlanGoal> goals;
  final List<PlanHabit> habits;
  final List<PlanCheckpoint> checkpoints;
  final List<String> tips;
  WellnessPlan({required this.goals, required this.habits, required this.checkpoints, required this.tips});
  factory WellnessPlan.fromJson(Map<String, dynamic> json) => WellnessPlan(
    goals: (json['goals'] as List? ?? const []).map((e) => PlanGoal.fromJson(e as Map<String, dynamic>)).toList(),
    habits: (json['habits'] as List? ?? const []).map((e) => PlanHabit.fromJson(e as Map<String, dynamic>)).toList(),
    checkpoints: (json['checkpoints'] as List? ?? const []).map((e) => PlanCheckpoint.fromJson(e as Map<String, dynamic>)).toList(),
    tips: List<String>.from(json['tips'] as List? ?? const []),
  );
}

