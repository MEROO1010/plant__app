import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_controller.dart';
import 'constants/app_config.dart';
import 'networking/api_client.dart';
import 'storage/secure_storage_service.dart';

/// Overridden in main() once the config asset is loaded.
final appConfigProvider = Provider<AppConfig>((ref) => throw UnimplementedError('appConfigProvider must be overridden'));

final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final tokenStorageProvider = Provider<TokenStorage>((ref) => ref.watch(secureStorageProvider));
final settingsStorageProvider = Provider<SettingsStorage>((ref) => ref.watch(secureStorageProvider));

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient.create(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    tokenStorage: ref.watch(tokenStorageProvider),
  );
  // An expired token logs the user out everywhere.
  client.onUnauthorized = () => ref.read(authControllerProvider.notifier).handleUnauthorized();
  return client;
});
