import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Runtime configuration.
///
/// Select the environment with `--dart-define=APP_ENV=production` (default: development).
/// Override the API URL (e.g. for a physical device) with
/// `--dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1`.
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.environment});

  final String apiBaseUrl;
  final String environment;

  bool get isProduction => environment == 'production';

  static const String _env = String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static Future<AppConfig> load() async {
    if (_override.isNotEmpty) {
      return AppConfig(apiBaseUrl: _override, environment: _env);
    }
    final raw = jsonDecode(await rootBundle.loadString('assets/config/app_config.json')) as Map<String, dynamic>;
    final section = raw[_env] as Map<String, dynamic>;

    if (_env == 'production') {
      return AppConfig(apiBaseUrl: section['api_base_url'] as String, environment: _env);
    }

    final key = kIsWeb
        ? 'web'
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => 'android_emulator',
            TargetPlatform.iOS => 'ios_simulator',
            _ => 'desktop',
          };
    return AppConfig(apiBaseUrl: section[key] as String, environment: _env);
  }
}
