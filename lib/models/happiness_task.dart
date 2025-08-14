import 'package:uuid/uuid.dart';

class HappinessTask {
  final String id;
  final String title;
  final String emoji;
  final String category; // body/mind/social/selfcare/creative
  final String description;
  final int? difficulty; // 1..5
  final int? estimatedMinutes; // 5/10/15...
  final String frequency; // once/daily/weekly/workdays/custom
  final String? customRule; // 备用字段，描述自定义重复规则
  final List<String> reminders; // HH:mm 列表
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? updatedAt;

  HappinessTask({
    String? id,
    required this.title,
    this.emoji = '🌿',
    this.category = 'selfcare',
    this.description = '',
    this.difficulty,
    this.estimatedMinutes,
    this.frequency = 'daily',
    this.customRule,
    this.reminders = const [],
    this.isArchived = false,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory HappinessTask.fromJson(Map<String, dynamic> json) {
    return HappinessTask(
      id: json['id'] as String?,
      title: json['title'] as String,
      emoji: json['emoji'] as String? ?? '🌿',
      category: json['category'] as String? ?? 'selfcare',
      description: json['description'] as String? ?? '',
      difficulty: json['difficulty'] as int?,
      estimatedMinutes: json['estimatedMinutes'] as int?,
      frequency: json['frequency'] as String? ?? 'daily',
      customRule: json['customRule'] as String?,
      reminders: List<String>.from(json['reminders'] as List? ?? const []),
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'category': category,
        'description': description,
        'difficulty': difficulty,
        'estimatedMinutes': estimatedMinutes,
        'frequency': frequency,
        'customRule': customRule,
        'reminders': reminders,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  HappinessTask copyWith({
    String? id,
    String? title,
    String? emoji,
    String? category,
    String? description,
    int? difficulty,
    int? estimatedMinutes,
    String? frequency,
    String? customRule,
    List<String>? reminders,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HappinessTask(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      frequency: frequency ?? this.frequency,
      customRule: customRule ?? this.customRule,
      reminders: reminders ?? this.reminders,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

