class HappinessStats {
  final double completionRate7d;
  final double completionRate30d;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> categoryDistribution; // category -> count
  final List<String> topTasks; // task titles
  final int totalCheckins;
  final double averageLift; // moodAfter - moodBefore 平均提升

  const HappinessStats({
    this.completionRate7d = 0,
    this.completionRate30d = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.categoryDistribution = const {},
    this.topTasks = const [],
    this.totalCheckins = 0,
    this.averageLift = 0,
  });

  factory HappinessStats.fromJson(Map<String, dynamic> json) {
    return HappinessStats(
      completionRate7d: (json['completionRate7d'] as num?)?.toDouble() ?? 0,
      completionRate30d: (json['completionRate30d'] as num?)?.toDouble() ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      categoryDistribution: Map<String, int>.from(json['categoryDistribution'] as Map? ?? {}),
      topTasks: List<String>.from(json['topTasks'] as List? ?? const []),
      totalCheckins: json['totalCheckins'] as int? ?? 0,
      averageLift: (json['averageLift'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'completionRate7d': completionRate7d,
        'completionRate30d': completionRate30d,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'categoryDistribution': categoryDistribution,
        'topTasks': topTasks,
        'totalCheckins': totalCheckins,
        'averageLift': averageLift,
      };
}

