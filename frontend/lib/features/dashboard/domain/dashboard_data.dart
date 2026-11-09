import '../../plants/domain/plant.dart';
import '../../reminders/domain/reminder.dart';

class DayProgress {
  const DayProgress({required this.date, required this.day, required this.tasksDue, required this.tasksCompleted, required this.careActions});

  final String date;
  final String day;
  final int tasksDue;
  final int tasksCompleted;
  final int careActions;

  factory DayProgress.fromJson(Map<String, dynamic> j) => DayProgress(
        date: j['date'] as String? ?? '',
        day: j['day'] as String? ?? '',
        tasksDue: (j['tasks_due'] as num?)?.toInt() ?? 0,
        tasksCompleted: (j['tasks_completed'] as num?)?.toInt() ?? 0,
        careActions: (j['care_actions'] as num?)?.toInt() ?? 0,
      );
}

class WeeklyProgress {
  const WeeklyProgress({required this.tasksDue, required this.tasksCompleted, required this.completionPercentage, required this.days});

  final int tasksDue;
  final int tasksCompleted;
  final int completionPercentage;
  final List<DayProgress> days;

  factory WeeklyProgress.fromJson(Map<String, dynamic> j) => WeeklyProgress(
        tasksDue: (j['tasks_due'] as num?)?.toInt() ?? 0,
        tasksCompleted: (j['tasks_completed'] as num?)?.toInt() ?? 0,
        completionPercentage: (j['completion_percentage'] as num?)?.toInt() ?? 0,
        days: (j['days'] as List? ?? const []).cast<Map<String, dynamic>>().map(DayProgress.fromJson).toList(),
      );
}

class PlantHealthStats {
  const PlantHealthStats({required this.total, required this.breakdown, required this.healthyPercentage, required this.overdueWatering});

  final int total;
  final Map<String, int> breakdown;
  final int healthyPercentage;
  final int overdueWatering;

  factory PlantHealthStats.fromJson(Map<String, dynamic> j) => PlantHealthStats(
        total: (j['total'] as num?)?.toInt() ?? 0,
        breakdown: (j['breakdown'] as Map? ?? const {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
        healthyPercentage: (j['healthy_percentage'] as num?)?.toInt() ?? 0,
        overdueWatering: (j['overdue_watering'] as num?)?.toInt() ?? 0,
      );
}

class DashboardData {
  const DashboardData({
    required this.totalPlants,
    required this.tasksDueToday,
    required this.overdueTasks,
    required this.weeklyProgress,
    required this.todayReminders,
    required this.upcomingReminders,
    this.featuredPlant,
  });

  final int totalPlants;
  final int tasksDueToday;
  final int overdueTasks;
  final WeeklyProgress weeklyProgress;
  final Plant? featuredPlant;
  final List<Reminder> todayReminders;
  final List<Reminder> upcomingReminders;

  factory DashboardData.fromJson(Map<String, dynamic> j) {
    List<Reminder> reminders(dynamic v) => (v as List? ?? const []).cast<Map<String, dynamic>>().map(Reminder.fromJson).toList();
    final featured = j['featured_plant'];
    return DashboardData(
      totalPlants: (j['total_plants'] as num?)?.toInt() ?? 0,
      tasksDueToday: (j['tasks_due_today'] as num?)?.toInt() ?? 0,
      overdueTasks: (j['overdue_tasks'] as num?)?.toInt() ?? 0,
      weeklyProgress: WeeklyProgress.fromJson((j['weekly_progress'] as Map?)?.cast<String, dynamic>() ?? const {}),
      featuredPlant: featured is Map<String, dynamic> ? Plant.fromJson(featured) : null,
      todayReminders: reminders(j['today_reminders']),
      upcomingReminders: reminders(j['upcoming_reminders']),
    );
  }
}
