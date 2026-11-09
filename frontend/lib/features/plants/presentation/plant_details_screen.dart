import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/networking/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/components/journal_components.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/plant_repository.dart';
import '../domain/plant.dart';
import 'plants_controller.dart';

class PlantDetailsScreen extends ConsumerWidget {
  const PlantDetailsScreen({super.key, required this.plantId});

  final int plantId;

  Future<void> _run(BuildContext context, WidgetRef ref, Future<Object?> Function() action) async {
    try {
      await action();
      refreshPlantData(ref, plantId: plantId);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(ctx.tr('delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr('delete'), style: const TextStyle(color: AppColors.coral))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(plantRepositoryProvider).delete(plantId);
      refreshPlantData(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('plant_deleted'))));
        context.go('/plants');
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(plantDetailProvider(plantId));
    final repo = ref.read(plantRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(tooltip: context.tr('edit_plant'), icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/plants/$plantId/edit')),
          IconButton(tooltip: context.tr('delete'), icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, ref)),
        ],
      ),
      body: AsyncValueView<Plant>(
        value: value,
        onRetry: () => ref.invalidate(plantDetailProvider(plantId)),
        builder: (plant) {
          final text = Theme.of(context).textTheme;
          return PageFrame(
            maxWidth: 720,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlantThumb(imageUrl: plant.imageUrl, size: 120),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plant.name, style: text.headlineMedium),
                          if (plant.species != null) Text(plant.species!, style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: AppColors.inkSoft)),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            HealthChip(plant.healthStatus),
                            if (plant.category != null) Chip(label: Text(plant.category!.name), visualDensity: VisualDensity.compact),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: FilledButton.icon(onPressed: () => _run(context, ref, () => repo.water(plantId)), icon: const Icon(Icons.water_drop_outlined), label: Text(context.tr('water')))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(onPressed: () => _run(context, ref, () => repo.fertilize(plantId)), icon: const Icon(Icons.grass_outlined), label: Text(context.tr('fertilize')))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(onPressed: () => _run(context, ref, () => repo.rotate(plantId)), icon: const Icon(Icons.rotate_right_outlined), label: Text(context.tr('rotate')))),
                  ],
                ),
                SectionLabel(context.tr('details')),
                _Fact(context.tr('next_watering'), relativeDay(context, plant.nextWateringAt), urgent: plant.needsWatering),
                _Fact(context.tr('last_watered'), shortDate(context, plant.lastWateredAt)),
                _Fact(context.tr('next_fertilizing'), relativeDay(context, plant.nextFertilizingAt)),
                _Fact(context.tr('water_every'), '${plant.wateringIntervalDays}'),
                _Fact(context.tr('fertilize_every'), '${plant.fertilizingIntervalDays}'),
                _Fact(context.tr('light_level'), context.tr(plant.lightLevel)),
                if (plant.location != null && plant.location!.isNotEmpty) _Fact(context.tr('location'), plant.location!),
                if (plant.notes != null && plant.notes!.isNotEmpty) ...[
                  SectionLabel(context.tr('notes')),
                  Text(plant.notes!, style: text.bodyLarge),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.push('/history?plantId=$plantId'),
                  icon: const Icon(Icons.history),
                  label: Text(context.tr('history')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.urgent = false});

  final String label;
  final String value;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyMedium?.copyWith(color: AppColors.inkSoft))),
          Text(value, style: text.bodyLarge?.copyWith(color: urgent ? AppColors.coral : null, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
