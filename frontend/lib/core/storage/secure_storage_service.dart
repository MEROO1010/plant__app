import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Where the auth token lives. Abstracted so tests can use an in-memory fake.
abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> deleteToken();
}

/// Key/value storage for small settings (locale, notification toggle).
abstract class SettingsStorage {
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
}

class SecureStorageService implements TokenStorage, SettingsStorage {
  SecureStorageService([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: AppConstants.tokenKey);

  @override
  Future<void> writeToken(String token) => _storage.write(key: AppConstants.tokenKey, value: token);

  @override
  Future<void> deleteToken() => _storage.delete(key: AppConstants.tokenKey);

  @override
  Future<String?> readString(String key) => _storage.read(key: key);

  @override
  Future<void> writeString(String key, String value) => _storage.write(key: key, value: value);
}
