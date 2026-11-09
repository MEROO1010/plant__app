import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/state_views.dart';
import 'plant_card.dart';
import 'plants_controller.dart';

class PlantListScreen extends ConsumerStatefulWidget {
  const PlantListScreen({super.key});

  @override
  ConsumerState<PlantListScreen> createState() => _PlantListScreenState();
}

class _PlantListScreenState extends ConsumerState<PlantListScreen> {
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
        ref.read(plantListControllerProvider.notifier).loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(plantListControllerProvider.notifier).load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => ref.read(plantListControllerProvider.notifier).setSearch(value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plantListControllerProvider);
    final controller = ref.read(plantListControllerProvider.notifier);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    Widget body;
    if (state.isLoading && state.items.isEmpty) {
      body = const LoadingView();
    } else if (state.error != null && state.items.isEmpty) {
      body = ErrorView(error: state.error!, onRetry: controller.load);
    } else if (state.isEmpty) {
      body = EmptyState(
        icon: Icons.eco_outlined,
        title: context.tr('empty_plants'),
        message: context.tr('empty_plants_hint'),
        action: FilledButton.icon(onPressed: () => context.push('/plants/add'), icon: const Icon(Icons.add), label: Text(context.tr('add_plant'))),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: controller.load,
        child: GridView.builder(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 480, mainAxisExtent: 108, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= state.items.length) return const LoadingView();
            final plant = state.items[i];
            return PlantCard(plant: plant, onTap: () => context.push('/plants/${plant.id}'));
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('plants'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/plants/add'),
        icon: const Icon(Icons.add),
        label: Text(context.tr('add_plant')),
      ),
      body: PageFrame(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                key: const Key('plant_search'),
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr('search_plants')),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(label: context.tr('all'), selected: state.categoryId == null && state.healthStatus == null, onSelected: () async {
                    await controller.setCategory(null);
                    await controller.setHealth(null);
                  }),
                  for (final c in categories)
                    _FilterChip(label: c.name, selected: state.categoryId == c.id, onSelected: () => controller.setCategory(state.categoryId == c.id ? null : c.id)),
                  for (final h in AppConstants.healthStatuses.where((h) => h != 'healthy'))
                    _FilterChip(label: context.tr(h), selected: state.healthStatus == h, onSelected: () => controller.setHealth(state.healthStatus == h ? null : h)),
                ],
              ),
            ),
            Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: body)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onSelected()),
      );
}
