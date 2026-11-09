import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_exception.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../reminders/presentation/reminders_controller.dart';
import '../data/plant_repository.dart';
import '../domain/plant.dart';
import '../domain/plant_category.dart';

class PlantListState {
  const PlantListState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.search = '',
    this.categoryId,
    this.healthStatus,
  });

  final List<Plant> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final String search;
  final int? categoryId;
  final String? healthStatus;

  bool get isEmpty => !isLoading && error == null && items.isEmpty;

  PlantListState copyWith({
    List<Plant>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
    String? search,
    int? categoryId,
    bool clearCategory = false,
    String? healthStatus,
    bool clearHealth = false,
  }) {
    return PlantListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      healthStatus: clearHealth ? null : (healthStatus ?? this.healthStatus),
    );
  }
}

class PlantListController extends Notifier<PlantListState> {
  @override
  PlantListState build() => const PlantListState();

  PlantRepository get _repo => ref.read(plantRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.list(
        page: 1,
        search: state.search,
        categoryId: state.categoryId,
        healthStatus: state.healthStatus,
      );
      state = state.copyWith(items: result.items, page: 1, hasMore: result.hasMore, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repo.list(
        page: state.page + 1,
        search: state.search,
        categoryId: state.categoryId,
        healthStatus: state.healthStatus,
      );
      state = state.copyWith(items: [...state.items, ...result.items], page: state.page + 1, hasMore: result.hasMore, isLoadingMore: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> setSearch(String value) {
    state = state.copyWith(search: value);
    return load();
  }

  Future<void> setCategory(int? id) {
    state = id == null ? state.copyWith(clearCategory: true) : state.copyWith(categoryId: id);
    return load();
  }

  Future<void> setHealth(String? status) {
    state = status == null ? state.copyWith(clearHealth: true) : state.copyWith(healthStatus: status);
    return load();
  }
}

final plantListControllerProvider = NotifierProvider<PlantListController, PlantListState>(PlantListController.new);

final categoriesProvider = FutureProvider.autoDispose<List<PlantCategory>>(
  (ref) => ref.watch(categoryRepositoryProvider).list(),
);

final plantDetailProvider = FutureProvider.autoDispose.family<Plant, int>(
  (ref, id) => ref.watch(plantRepositoryProvider).get(id),
);

/// Refreshes every screen that shows plant/care data after a change.
void refreshPlantData(WidgetRef ref, {int? plantId}) {
  ref.read(plantListControllerProvider.notifier).load();
  ref.invalidate(dashboardProvider);
  ref.invalidate(weeklyProgressProvider);
  ref.invalidate(plantHealthProvider);
  ref.read(remindersControllerProvider.notifier).load();
  if (plantId != null) ref.invalidate(plantDetailProvider(plantId));
}
