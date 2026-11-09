import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/components/journal_components.dart';
import '../domain/plant.dart';

class PlantCard extends StatelessWidget {
  const PlantCard({super.key, required this.plant, required this.onTap});

  final Plant plant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final urgent = plant.needsWatering || plant.healthStatus != 'healthy';

    return Semantics(
      button: true,
      label: plant.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: urgent ? AppColors.coral.withValues(alpha: 0.6) : AppColors.line),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              PlantThumb(imageUrl: plant.imageUrl, size: 80),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(plant.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (plant.species != null)
                      Text(plant.species!, style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppColors.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.water_drop_outlined, size: 16, color: plant.needsWatering ? AppColors.coral : AppColors.forest),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            relativeDay(context, plant.nextWateringAt),
                            style: text.bodySmall?.copyWith(color: plant.needsWatering ? AppColors.coral : AppColors.inkSoft, fontWeight: plant.needsWatering ? FontWeight.w700 : null),
                          ),
                        ),
                        if (plant.healthStatus != 'healthy') ...[const SizedBox(width: 8), HealthChip(plant.healthStatus)],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
