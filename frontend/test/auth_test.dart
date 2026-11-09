import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care/core/networking/api_exception.dart';
import 'package:plant_care/features/auth/data/auth_repository.dart';
import 'package:plant_care/features/auth/presentation/auth_controller.dart';

import 'helpers/fakes.dart';

const _user = {'id': 1, 'name': 'Arwa', 'email': 'a@b.co', 'avatar_url': null};

void main() {
  late FakeAdapter adapter;
  late MemoryStorage storage;
  late ProviderContainer container;

  setUp(() {
    adapter = FakeAdapter();
    storage = MemoryStorage();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(AuthRepository(makeClient(adapter, storage), storage)),
    ]);
    addTearDown(container.dispose);
  });

  group('AuthRepository', () {
    test('login saves the token and returns the user', () async {
      adapter.on('POST', '/auth/login', ok({'user': _user, 'token': 'abc123'}));
      final user = await AuthRepository(makeClient(adapter, storage), storage).login('a@b.co', 'secret123');

      expect(user.name, 'Arwa');
      expect(storage.token, 'abc123');
    });

    test('login failure surfaces validation errors', () async {
      adapter.on('POST', '/auth/login', failure('The given data was invalid.', errors: {'email': ['These credentials do not match our records.']}), status: 422);

      expect(
        () => AuthRepository(makeClient(adapter, storage), storage).login('a@b.co', 'bad'),
        throwsA(isA<ApiException>().having((e) => e.displayMessage, 'message', 'These credentials do not match our records.')),
      );
    });

    test('logout clears the token even if the request fails', () async {
      storage.token = 'abc';
      await AuthRepository(makeClient(adapter, storage), storage).logout(); // no route => 404
      expect(storage.token, isNull);
    });

    test('requests carry the bearer token', () async {
      storage.token = 'tok';
      adapter.on('GET', '/auth/me', ok({'user': _user}));
      await AuthRepository(makeClient(adapter, storage), storage).me();
      expect(adapter.requests.single.headers['Authorization'], 'Bearer tok');
    });
  });

  group('AuthController', () {
    test('starts unknown, restore without token -> unauthenticated', () async {
      expect(container.read(authControllerProvider).status, AuthStatus.unknown);
      await container.read(authControllerProvider.notifier).restore();
      expect(container.read(authControllerProvider).status, AuthStatus.unauthenticated);
    });

    test('restore with a valid token -> authenticated with user', () async {
      storage.token = 'tok';
      adapter.on('GET', '/auth/me', ok({'user': _user}));
      await container.read(authControllerProvider.notifier).restore();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.email, 'a@b.co');
    });

    test('restore with an expired token clears it', () async {
      storage.token = 'old';
      adapter.on('GET', '/auth/me', failure('Unauthenticated.'), status: 401);
      await container.read(authControllerProvider.notifier).restore();

      expect(container.read(authControllerProvider).status, AuthStatus.unauthenticated);
      expect(storage.token, isNull);
    });

    test('login success authenticates', () async {
      adapter.on('POST', '/auth/login', ok({'user': _user, 'token': 't'}));
      final ok_ = await container.read(authControllerProvider.notifier).login('a@b.co', 'secret123');

      expect(ok_, isTrue);
      expect(container.read(authControllerProvider).status, AuthStatus.authenticated);
      expect(container.read(authControllerProvider).isLoading, isFalse);
    });

    test('login failure keeps the user logged out and exposes the error', () async {
      adapter.on('POST', '/auth/login', failure('The given data was invalid.', errors: {'email': ['Wrong credentials']}), status: 422);
      final result = await container.read(authControllerProvider.notifier).login('a@b.co', 'x');

      final state = container.read(authControllerProvider);
      expect(result, isFalse);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.error, 'Wrong credentials');
      expect(state.isLoading, isFalse);
    });

    test('logout returns to unauthenticated and removes the token', () async {
      adapter.on('POST', '/auth/login', ok({'user': _user, 'token': 't'}));
      adapter.on('POST', '/auth/logout', ok(null));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.login('a@b.co', 'secret123');
      await notifier.logout();

      expect(container.read(authControllerProvider).status, AuthStatus.unauthenticated);
      expect(storage.token, isNull);
    });

    test('handleUnauthorized drops an active session', () async {
      adapter.on('POST', '/auth/login', ok({'user': _user, 'token': 't'}));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.login('a@b.co', 'secret123');
      notifier.handleUnauthorized();

      expect(container.read(authControllerProvider).status, AuthStatus.unauthenticated);
    });
  });
}
