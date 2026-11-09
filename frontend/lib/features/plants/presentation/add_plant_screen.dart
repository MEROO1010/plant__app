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

class AddPlantScreen extends ConsumerWidget {
  const AddPlantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    Future<void> submit(PlantInput input) async {
      try {
        await ref.read(plantRepositoryProvider).create(input);
        refreshPlantData(ref);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('plant_saved'))));
          context.pop();
        }
      } on ApiException catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('add_plant'))),
      body: AsyncValueView(
        value: categories,
        onRetry: () => ref.invalidate(categoriesProvider),
        builder: (cats) => PlantForm(categories: cats, onSubmit: submit),
      ),
    );
  }
}
