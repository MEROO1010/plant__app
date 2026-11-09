import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/providers.dart';
import '../domain/dashboard_data.dart';

class StatisticsRepository {
  StatisticsRepository(this._api);

  final ApiClient _api;

  Future<DashboardData> dashboard() async => DashboardData.fromJson((await _api.get(ApiEndpoints.statsDashboard)).data as Map<String, dynamic>);

  Future<WeeklyProgress> weeklyProgress() async => WeeklyProgress.fromJson((await _api.get(ApiEndpoints.statsWeekly)).data as Map<String, dynamic>);

  Future<PlantHealthStats> plantHealth() async => PlantHealthStats.fromJson((await _api.get(ApiEndpoints.statsHealth)).data as Map<String, dynamic>);
}

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) => StatisticsRepository(ref.watch(apiClientProvider)));
