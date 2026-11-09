import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/networking/api_exception.dart';
import '../../../core/utils/app_strings.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/plant_repository.dart';
import '../domain/plant.dart';
import 'plant_form.dart';
import 'plants_controller.dart';

class EditPlantScreen extends ConsumerWidget {
  const EditPlantScreen({super.key, required this.plantId});

  final int plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plant = ref.watch(plantDetailProvider(plantId));
    final categories = ref.watch(categoriesProvider);

    Future<void> submit(PlantInput input) async {
      try {
        await ref.read(plantRepositoryProvider).update(plantId, input);
        refreshPlantData(ref, plantId: plantId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('plant_saved'))));
          context.pop();
        }
      } on ApiException catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('edit_plant'))),
      body: AsyncValueView<Plant>(
        value: plant,
        onRetry: () => ref.invalidate(plantDetailProvider(plantId)),
        builder: (p) => PlantForm(initial: p, categories: categories.valueOrNull ?? const [], onSubmit: submit),
      ),
    );
  }
}
