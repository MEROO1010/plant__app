import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers.dart';
import '../../../core/storage/secure_storage_service.dart';

class SettingsRepository {
  SettingsRepository(this._storage);

  final SettingsStorage _storage;

  Future<Locale> readLocale() async {
    final code = await _storage.readString(AppConstants.localeKey);
    return Locale(code == 'ar' ? 'ar' : 'en');
  }

  Future<void> saveLocale(Locale locale) => _storage.writeString(AppConstants.localeKey, locale.languageCode);

  Future<bool> readNotificationsEnabled() async => (await _storage.readString(AppConstants.notificationsKey)) == 'true';

  Future<void> saveNotificationsEnabled(bool value) => _storage.writeString(AppConstants.notificationsKey, value.toString());
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository(ref.watch(settingsStorageProvider)));
