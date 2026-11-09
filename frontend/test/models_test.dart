import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care/features/auth/domain/auth_user.dart';
import 'package:plant_care/features/care_history/domain/care_log.dart';
import 'package:plant_care/features/dashboard/domain/dashboard_data.dart';
import 'package:plant_care/features/plants/domain/plant.dart';
import 'package:plant_care/features/reminders/domain/reminder.dart';
import 'package:plant_care/shared/models/paged_result.dart';

import 'helpers/fakes.dart';

void main() {
  test('AuthUser round-trips JSON', () {
    final user = AuthUser.fromJson({'id': 3, 'name': 'Arwa', 'email': 'a@b.co', 'avatar_url': null});
    expect(user.toJson(), {'id': 3, 'name': 'Arwa', 'email': 'a@b.co', 'avatar_url': null});
  });

  test('Plant parses API JSON including nested category and dates', () {
    final plant = Plant.fromJson(plantJson(health: 'critical', needsWatering: true));
    expect(plant.name, 'Monty');
    expect(plant.category?.name, 'Tropical');
    expect(plant.nextWateringAt, isNotNull);
    expect(plant.lastFertilizedAt, isNull);
    expect(plant.needsAttention, isTrue);
    expect(plant.wateringIntervalDays, 7);
  });

  test('Plant toJson -> fromJson keeps values', () {
    final original = Plant.fromJson(plantJson());
    final copy = Plant.fromJson(original.toJson());
    expect(copy.id, original.id);
    expect(copy.nextWateringAt, original.nextWateringAt);
    expect(copy.category?.slug, 'tropical');
  });

  test('Plant tolerates empty category object and missing optional fields', () {
    final plant = Plant.fromJson({'id': 1, 'name': 'Bare', 'category': <String, dynamic>{}});
    expect(plant.category, isNull);
    expect(plant.lightLevel, 'medium');
    expect(plant.healthStatus, 'healthy');
  });

  test('PlantInput.toMap uses API field names', () {
    const input = PlantInput(name: 'Fern', wateringIntervalDays: 4, plantCategoryId: 2);
    expect(input.toMap()['watering_interval_days'], 4);
    expect(input.toMap()['plant_category_id'], 2);
    expect(input.hasImage, isFalse);
  });

  test('Reminder and CareLog parse plant summary', () {
    final r = Reminder.fromJson(reminderJson());
    expect(r.plantName, 'Monty');
    expect(r.isCompleted, isFalse);
    final log = CareLog.fromJson({'id': 1, 'plant_id': 1, 'plant': {'name': 'Monty'}, 'type': 'watering', 'notes': 'x', 'performed_at': '2026-11-01T10:00:00+00:00'});
    expect(log.plantName, 'Monty');
    expect(CareLog.fromJson(log.toJson()).notes, 'x');
  });

  test('DashboardData parses nested weekly progress, featured plant and reminders', () {
    final d = DashboardData.fromJson({
      'total_plants': 6,
      'tasks_due_today': 2,
      'overdue_tasks': 1,
      'weekly_progress': {
        'tasks_due': 4,
        'tasks_completed': 1,
        'completion_percentage': 25,
        'days': [
          {'date': '2026-11-02', 'day': 'Mon', 'tasks_due': 2, 'tasks_completed': 1, 'care_actions': 1}
        ],
      },
      'featured_plant': plantJson(),
      'today_reminders': [reminderJson()],
      'upcoming_reminders': <dynamic>[],
    });
    expect(d.totalPlants, 6);
    expect(d.weeklyProgress.completionPercentage, 25);
    expect(d.weeklyProgress.days.single.day, 'Mon');
    expect(d.featuredPlant?.name, 'Monty');
    expect(d.todayReminders, hasLength(1));
  });

  test('DashboardData handles null featured plant', () {
    final d = DashboardData.fromJson({'featured_plant': null});
    expect(d.featuredPlant, isNull);
    expect(d.totalPlants, 0);
  });

  test('PlantHealthStats parses breakdown', () {
    final h = PlantHealthStats.fromJson({'total': 4, 'breakdown': {'healthy': 3, 'critical': 1}, 'healthy_percentage': 75, 'overdue_watering': 2});
    expect(h.breakdown['healthy'], 3);
    expect(h.overdueWatering, 2);
  });

  test('PagedResult reads meta and hasMore', () {
    final page = PagedResult.fromResponse([plantJson()], {'current_page': 1, 'last_page': 3, 'total': 31}, Plant.fromJson);
    expect(page.items, hasLength(1));
    expect(page.hasMore, isTrue);
    expect(page.total, 31);
  });
}
