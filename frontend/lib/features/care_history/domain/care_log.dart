import '../../../core/utils/date_utils.dart';

class CareLog {
  const CareLog({required this.id, required this.plantId, required this.type, required this.performedAt, this.plantName, this.notes});

  final int id;
  final int plantId;
  final String? plantName;
  final String type;
  final String? notes;
  final DateTime performedAt;

  factory CareLog.fromJson(Map<String, dynamic> json) {
    final plant = json['plant'];
    return CareLog(
      id: (json['id'] as num).toInt(),
      plantId: (json['plant_id'] as num).toInt(),
      plantName: plant is Map<String, dynamic> ? plant['name'] as String? : null,
      type: json['type'] as String? ?? 'other',
      notes: json['notes'] as String?,
      performedAt: parseDate(json['performed_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plant_id': plantId,
        'plant': {'name': plantName},
        'type': type,
        'notes': notes,
        'performed_at': performedAt.toUtc().toIso8601String(),
      };
}
