import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_strings.dart';

/// Small caps label used above sections, like a journal tab.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 1.4, color: AppColors.inkSoft),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.urgent = false});

  final String value;
  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border.all(color: urgent ? AppColors.coral : AppColors.line),
        color: urgent ? AppColors.coralSoft.withValues(alpha: 0.5) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: text.headlineMedium?.copyWith(color: urgent ? AppColors.coral : AppColors.forest)),
          const SizedBox(height: 2),
          Text(label, style: text.bodySmall?.copyWith(color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class PlantThumb extends StatelessWidget {
  const PlantThumb({super.key, this.imageUrl, this.size = 64});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.mossSoft,
      child: Icon(Icons.eco_outlined, color: AppColors.forest, size: size * 0.45),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return ClipRRect(borderRadius: BorderRadius.circular(4), child: placeholder);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}

/// Health status pill: coral for anything urgent.
class HealthChip extends StatelessWidget {
  const HealthChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final urgent = status != 'healthy';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: urgent ? AppColors.coralSoft : AppColors.mossSoft,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        context.tr(status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: urgent ? AppColors.coral : AppColors.forest, fontWeight: FontWeight.w700),
      ),
    );
  }
}

IconData careIcon(String type) => switch (type) {
      'watering' => Icons.water_drop_outlined,
      'fertilizing' => Icons.grass_outlined,
      'rotating' => Icons.rotate_right_outlined,
      'pruning' => Icons.content_cut_outlined,
      'repotting' => Icons.yard_outlined,
      _ => Icons.eco_outlined,
    };
