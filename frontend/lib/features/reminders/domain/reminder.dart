import '../../../core/utils/date_utils.dart';

class Reminder {
  const Reminder({
    required this.id,
    required this.plantId,
    required this.type,
    required this.title,
    required this.dueAt,
    this.plantName,
    this.plantImageUrl,
    this.description,
    this.completedAt,
    this.isCompleted = false,
    this.isOverdue = false,
  });

  final int id;
  final int plantId;
  final String? plantName;
  final String? plantImageUrl;
  final String type;
  final String title;
  final String? description;
  final DateTime dueAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final bool isOverdue;

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final plant = json['plant'];
    return Reminder(
      id: (json['id'] as num).toInt(),
      plantId: (json['plant_id'] as num).toInt(),
      plantName: plant is Map<String, dynamic> ? plant['name'] as String? : null,
      plantImageUrl: plant is Map<String, dynamic> ? plant['image_url'] as String? : null,
      type: json['type'] as String? ?? 'watering',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueAt: parseDate(json['due_at']) ?? DateTime.now(),
      completedAt: parseDate(json['completed_at']),
      isCompleted: json['is_completed'] as bool? ?? false,
      isOverdue: json['is_overdue'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plant_id': plantId,
        'plant': {'name': plantName, 'image_url': plantImageUrl},
        'type': type,
        'title': title,
        'description': description,
        'due_at': dueAt.toUtc().toIso8601String(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'is_completed': isCompleted,
        'is_overdue': isOverdue,
      };
}
