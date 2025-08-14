import 'package:uuid/uuid.dart';

class HappinessCheckin {
  final String id;
  final String taskId;
  final String ymdDate; // YYYY-MM-DD
  final DateTime completedAt;
  final String? moodBefore;
  final String? moodAfter;
  final String? notes;
  final List<String> attachments; // 图片路径
  final int? rating; // 1..5 幸福感/完成感

  HappinessCheckin({
    String? id,
    required this.taskId,
    required this.ymdDate,
    DateTime? completedAt,
    this.moodBefore,
    this.moodAfter,
    this.notes,
    this.attachments = const [],
    this.rating,
  })  : id = id ?? const Uuid().v4(),
        completedAt = completedAt ?? DateTime.now();

  factory HappinessCheckin.fromJson(Map<String, dynamic> json) {
    return HappinessCheckin(
      id: json['id'] as String?,
      taskId: json['taskId'] as String,
      ymdDate: json['ymdDate'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      moodBefore: json['moodBefore'] as String?,
      moodAfter: json['moodAfter'] as String?,
      notes: json['notes'] as String?,
      attachments: List<String>.from(json['attachments'] as List? ?? const []),
      rating: json['rating'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'ymdDate': ymdDate,
        'completedAt': completedAt.toIso8601String(),
        'moodBefore': moodBefore,
        'moodAfter': moodAfter,
        'notes': notes,
        'attachments': attachments,
        'rating': rating,
      };
}

