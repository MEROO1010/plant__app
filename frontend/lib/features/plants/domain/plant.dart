import 'dart:typed_data';

import '../../../core/utils/date_utils.dart';
import 'plant_category.dart';

class Plant {
  const Plant({
    required this.id,
    required this.name,
    this.plantCategoryId,
    this.category,
    this.species,
    this.description,
    this.imageUrl,
    this.location,
    this.lightLevel = 'medium',
    this.wateringIntervalDays = 7,
    this.fertilizingIntervalDays = 30,
    this.lastWateredAt,
    this.nextWateringAt,
    this.lastFertilizedAt,
    this.nextFertilizingAt,
    this.needsWatering = false,
    this.healthStatus = 'healthy',
    this.notes,
  });

  final int id;
  final String name;
  final int? plantCategoryId;
  final PlantCategory? category;
  final String? species;
  final String? description;
  final String? imageUrl;
  final String? location;
  final String lightLevel;
  final int wateringIntervalDays;
  final int fertilizingIntervalDays;
  final DateTime? lastWateredAt;
  final DateTime? nextWateringAt;
  final DateTime? lastFertilizedAt;
  final DateTime? nextFertilizingAt;
  final bool needsWatering;
  final String healthStatus;
  final String? notes;

  bool get needsAttention => healthStatus != 'healthy' || needsWatering;

  factory Plant.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    return Plant(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      plantCategoryId: (json['plant_category_id'] as num?)?.toInt(),
      category: cat is Map<String, dynamic> && cat.isNotEmpty ? PlantCategory.fromJson(cat) : null,
      species: json['species'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      location: json['location'] as String?,
      lightLevel: json['light_level'] as String? ?? 'medium',
      wateringIntervalDays: (json['watering_interval_days'] as num?)?.toInt() ?? 7,
      fertilizingIntervalDays: (json['fertilizing_interval_days'] as num?)?.toInt() ?? 30,
      lastWateredAt: parseDate(json['last_watered_at']),
      nextWateringAt: parseDate(json['next_watering_at']),
      lastFertilizedAt: parseDate(json['last_fertilized_at']),
      nextFertilizingAt: parseDate(json['next_fertilizing_at']),
      needsWatering: json['needs_watering'] as bool? ?? false,
      healthStatus: json['health_status'] as String? ?? 'healthy',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'plant_category_id': plantCategoryId,
        'category': category?.toJson(),
        'species': species,
        'description': description,
        'image_url': imageUrl,
        'location': location,
        'light_level': lightLevel,
        'watering_interval_days': wateringIntervalDays,
        'fertilizing_interval_days': fertilizingIntervalDays,
        'last_watered_at': lastWateredAt?.toUtc().toIso8601String(),
        'next_watering_at': nextWateringAt?.toUtc().toIso8601String(),
        'last_fertilized_at': lastFertilizedAt?.toUtc().toIso8601String(),
        'next_fertilizing_at': nextFertilizingAt?.toUtc().toIso8601String(),
        'needs_watering': needsWatering,
        'health_status': healthStatus,
        'notes': notes,
      };
}

/// Data collected by the add/edit form.
class PlantInput {
  const PlantInput({
    required this.name,
    this.species,
    this.location,
    this.notes,
    this.plantCategoryId,
    this.lightLevel = 'medium',
    this.wateringIntervalDays = 7,
    this.fertilizingIntervalDays = 30,
    this.healthStatus = 'healthy',
    this.imageBytes,
    this.imageName,
  });

  final String name;
  final String? species;
  final String? location;
  final String? notes;
  final int? plantCategoryId;
  final String lightLevel;
  final int wateringIntervalDays;
  final int fertilizingIntervalDays;
  final String healthStatus;
  final Uint8List? imageBytes;
  final String? imageName;

  bool get hasImage => imageBytes != null;

  Map<String, dynamic> toMap() => {
        'name': name,
        'species': species,
        'location': location,
        'notes': notes,
        'plant_category_id': plantCategoryId,
        'light_level': lightLevel,
        'watering_interval_days': wateringIntervalDays,
        'fertilizing_interval_days': fertilizingIntervalDays,
        'health_status': healthStatus,
      };
}
