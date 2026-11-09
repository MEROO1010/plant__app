import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<bool> hasToken() async => (await _tokens.readToken()) != null;

  Future<AuthUser> login(String email, String password) async {
    final res = await _api.post(ApiEndpoints.login, body: {'email': email, 'password': password});
    return _saveSession(res.data as Map<String, dynamic>);
  }

  Future<AuthUser> register(String name, String email, String password) async {
    final res = await _api.post(ApiEndpoints.register, body: {'name': name, 'email': email, 'password': password});
    return _saveSession(res.data as Map<String, dynamic>);
  }

  Future<AuthUser> me() async {
    final res = await _api.get(ApiEndpoints.me);
    return AuthUser.fromJson((res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> updateProfile({String? name}) async {
    final res = await _api.put(ApiEndpoints.profile, body: {if (name != null) 'name': name});
    return AuthUser.fromJson((res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  /// Always clears the local token, even when the network call fails.
  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {
      // Token is discarded locally regardless.
    } finally {
      await _tokens.deleteToken();
    }
  }

  Future<void> clearSession() => _tokens.deleteToken();

  Future<AuthUser> _saveSession(Map<String, dynamic> data) async {
    await _tokens.writeToken(data['token'] as String);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)),
);
