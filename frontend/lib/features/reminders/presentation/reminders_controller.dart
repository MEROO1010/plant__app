import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_exception.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/notification_service.dart';
import '../data/reminder_repository.dart';
import '../domain/reminder.dart';

class RemindersState {
  const RemindersState({
    this.today = const [],
    this.upcoming = const [],
    this.isLoading = false,
    this.error,
    this.completingIds = const {},
  });

  final List<Reminder> today;
  final List<Reminder> upcoming;
  final bool isLoading;
  final Object? error;
  final Set<int> completingIds;

  RemindersState copyWith({List<Reminder>? today, List<Reminder>? upcoming, bool? isLoading, Object? error, bool clearError = false, Set<int>? completingIds}) {
    return RemindersState(
      today: today ?? this.today,
      upcoming: upcoming ?? this.upcoming,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      completingIds: completingIds ?? this.completingIds,
    );
  }
}

class RemindersController extends Notifier<RemindersState> {
  @override
  RemindersState build() => const RemindersState();

  ReminderRepository get _repo => ref.read(reminderRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([_repo.today(), _repo.upcoming()]);
      state = state.copyWith(today: results[0], upcoming: results[1], isLoading: false);
      await _syncNotifications();
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Marks a reminder done. Watering/fertilizing reminders also update the plant on the server.
  Future<bool> complete(int id) async {
    if (state.completingIds.contains(id)) return false;
    state = state.copyWith(completingIds: {...state.completingIds, id});
    try {
      await _repo.complete(id);
      state = state.copyWith(
        today: state.today.where((r) => r.id != id).toList(),
        upcoming: state.upcoming.where((r) => r.id != id).toList(),
        completingIds: {...state.completingIds}..remove(id),
      );
      ref.invalidate(dashboardProvider);
      ref.invalidate(weeklyProgressProvider);
      // The server schedules the next occurrence: refresh to pick it up.
      await load();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e, completingIds: {...state.completingIds}..remove(id));
      return false;
    }
  }

  Future<void> _syncNotifications() async {
    final enabled = ref.read(notificationsEnabledProvider);
    if (enabled) {
      await NotificationService.instance.scheduleReminders([...state.today, ...state.upcoming]);
    }
  }
}

final remindersControllerProvider = NotifierProvider<RemindersController, RemindersState>(RemindersController.new);
