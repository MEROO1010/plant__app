import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/statistics_repository.dart';
import '../domain/dashboard_data.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) => ref.watch(statisticsRepositoryProvider).dashboard());

final weeklyProgressProvider = FutureProvider.autoDispose<WeeklyProgress>((ref) => ref.watch(statisticsRepositoryProvider).weeklyProgress());

final plantHealthProvider = FutureProvider.autoDispose<PlantHealthStats>((ref) => ref.watch(statisticsRepositoryProvider).plantHealth());
