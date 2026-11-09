import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.isLoading = false, this.error});

  final AuthStatus status;
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  AuthState copyWith({AuthStatus? status, AuthUser? user, bool? isLoading, String? error, bool clearError = false, bool clearUser = false}) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Called by the splash screen: restores a saved session if the token is still valid.
  Future<void> restore() async {
    if (!await _repo.hasToken()) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      if (e.isUnauthorized) await _repo.clearSession();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) => _run(() => _repo.login(email, password));

  Future<bool> register(String name, String email, String password) => _run(() => _repo.register(name, email, password));

  Future<bool> _run(Future<AuthUser> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await action();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, status: AuthStatus.unauthenticated, error: e.displayMessage);
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> updateName(String name) async {
    final user = await _repo.updateProfile(name: name);
    state = state.copyWith(user: user);
  }

  /// The API rejected our token: drop the session.
  void handleUnauthorized() {
    if (state.status == AuthStatus.authenticated) {
      _repo.clearSession();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

final currentUserProvider = Provider<AuthUser?>((ref) => ref.watch(authControllerProvider).user);
