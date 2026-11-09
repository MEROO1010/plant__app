import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder.dart';

/// Schedules local notifications for upcoming reminders. Does nothing on web
/// or on platforms where the plugin is unavailable.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final androidOk = await android?.requestNotificationsPermission();
    final iosOk = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return (androidOk ?? iosOk ?? true);
  }

  Future<void> scheduleReminders(List<Reminder> reminders) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails('plant_care_reminders', 'Plant care reminders', importance: Importance.defaultImportance),
      iOS: DarwinNotificationDetails(),
    );
    final now = DateTime.now();
    for (final r in reminders.where((r) => !r.isCompleted && r.dueAt.isAfter(now))) {
      await _plugin.zonedSchedule(
        r.id,
        r.title,
        r.plantName,
        // An absolute instant: expressing it in UTC is the same moment in local time.
        tz.TZDateTime.from(r.dueAt, tz.UTC),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }
}
