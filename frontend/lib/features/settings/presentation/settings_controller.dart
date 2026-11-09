import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reminders/data/notification_service.dart';
import '../data/settings_repository.dart';

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    // English is the default; a saved choice is applied as soon as it is read.
    Future.microtask(() async {
      try {
        state = await ref.read(settingsRepositoryProvider).readLocale();
      } catch (_) {}
    });
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref.read(settingsRepositoryProvider).saveLocale(locale);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

class NotificationsController extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(() async {
      try {
        state = await ref.read(settingsRepositoryProvider).readNotificationsEnabled();
      } catch (_) {}
    });
    return false;
  }

  Future<void> setEnabled(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) return;
    } else {
      await NotificationService.instance.cancelAll();
    }
    state = value;
    await ref.read(settingsRepositoryProvider).saveNotificationsEnabled(value);
  }
}

final notificationsEnabledProvider = NotifierProvider<NotificationsController, bool>(NotificationsController.new);
