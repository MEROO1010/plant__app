import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/care_history/presentation/care_history_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/statistics_screen.dart';
import '../../features/plants/presentation/add_plant_screen.dart';
import '../../features/plants/presentation/edit_plant_screen.dart';
import '../../features/plants/presentation/plant_details_screen.dart';
import '../../features/plants/presentation/plant_list_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';

/// Bridges Riverpod auth changes to go_router's refresh mechanism.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider.select((s) => s.status), (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      final onAuthPage = loc == '/login' || loc == '/register';

      switch (status) {
        case AuthStatus.unknown:
          return loc == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return onAuthPage ? null : '/login';
        case AuthStatus.authenticated:
          return (loc == '/splash' || onAuthPage) ? '/dashboard' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/plants', builder: (_, __) => const PlantListScreen()),
          // Must come before '/plants/:id' so "add" is not parsed as an id.
          GoRoute(path: '/plants/add', builder: (_, __) => const AddPlantScreen()),
          GoRoute(path: '/plants/:id', builder: (_, s) => PlantDetailsScreen(plantId: int.parse(s.pathParameters['id']!))),
          GoRoute(path: '/plants/:id/edit', builder: (_, s) => EditPlantScreen(plantId: int.parse(s.pathParameters['id']!))),
          GoRoute(path: '/reminders', builder: (_, __) => const RemindersScreen()),
          GoRoute(path: '/history', builder: (_, s) => CareHistoryScreen(plantId: int.tryParse(s.uri.queryParameters['plantId'] ?? ''))),
          GoRoute(path: '/statistics', builder: (_, __) => const StatisticsScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
