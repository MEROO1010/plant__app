import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/components/journal_components.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reminders/presentation/reminder_tile.dart';
import '../../reminders/presentation/reminders_controller.dart';
import '../domain/dashboard_data.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Loads reminders so local notifications get scheduled.
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(remindersControllerProvider.notifier).load());
  }

  void _openWaterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _WaterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      body: SafeArea(
        child: AsyncValueView<DashboardData>(
          value: data,
          onRetry: () => ref.invalidate(dashboardProvider),
          builder: (d) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              await ref.read(dashboardProvider.future);
            },
            child: PageFrame(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  Text(DateFormat.MMMMEEEEd(locale).format(DateTime.now()).toUpperCase(), style: text.labelLarge?.copyWith(letterSpacing: 1.4, color: AppColors.inkSoft)),
                  const SizedBox(height: 6),
                  Text(
                    user == null ? context.tr('welcome') : '${context.tr('welcome')}, ${user.name.split(' ').first}',
                    style: text.headlineLarge,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: StatTile(value: '${d.totalPlants}', label: context.tr('total_plants'))),
                      const SizedBox(width: 12),
                      Expanded(child: StatTile(value: '${d.tasksDueToday}', label: context.tr('due_today'), urgent: d.overdueTasks > 0)),
                      const SizedBox(width: 12),
                      Expanded(child: StatTile(value: '${d.weeklyProgress.completionPercentage}%', label: context.tr('this_week'))),
                    ],
                  ),
                  SectionLabel(context.tr('weekly_progress')),
                  _WeeklyBar(progress: d.weeklyProgress),
                  SectionLabel(context.tr('needs_attention')),
                  if (d.featuredPlant == null)
                    Text(context.tr('nothing_featured'), style: text.bodyLarge?.copyWith(color: AppColors.inkSoft))
                  else
                    _FeaturedPlant(data: d),
                  SectionLabel(context.tr('quick_actions')),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(onPressed: _openWaterSheet, icon: const Icon(Icons.water_drop_outlined), label: Text(context.tr('water_plants'))),
                      OutlinedButton.icon(onPressed: () => context.push('/plants/add'), icon: const Icon(Icons.add), label: Text(context.tr('add_plant'))),
                    ],
                  ),
                  SectionLabel(context.tr('upcoming')),
                  if (d.upcomingReminders.isEmpty)
                    Text(context.tr('empty_reminders_hint'), style: text.bodyLarge?.copyWith(color: AppColors.inkSoft))
                  else
                    for (final r in d.upcomingReminders) ReminderTile(reminder: r),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyBar extends StatelessWidget {
  const _WeeklyBar({required this.progress});

  final WeeklyProgress progress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '${progress.tasksCompleted}/${progress.tasksDue}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.completionPercentage / 100,
              minHeight: 8,
              color: AppColors.forest,
              backgroundColor: AppColors.line,
            ),
          ),
          const SizedBox(height: 8),
          Text('${progress.tasksCompleted} / ${progress.tasksDue} ${context.tr('completed')}', style: text.bodyMedium?.copyWith(color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _FeaturedPlant extends StatelessWidget {
  const _FeaturedPlant({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final plant = data.featuredPlant!;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => context.push('/plants/${plant.id}'),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(left: const BorderSide(color: AppColors.coral, width: 4), top: const BorderSide(color: AppColors.line), right: const BorderSide(color: AppColors.line), bottom: const BorderSide(color: AppColors.line)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            PlantThumb(imageUrl: plant.imageUrl, size: 84),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.name, style: text.titleLarge),
                  if (plant.species != null) Text(plant.species!, style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppColors.inkSoft)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    HealthChip(plant.healthStatus),
                    Text('${context.tr('next_watering')}: ${relativeDay(context, plant.nextWateringAt)}', style: text.bodySmall?.copyWith(color: plant.needsWatering ? AppColors.coral : AppColors.inkSoft)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterSheet extends ConsumerWidget {
  const _WaterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider).valueOrNull;
    final watering = data?.todayReminders.where((r) => r.type == 'watering').toList() ?? const [];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: watering.isEmpty
            ? Padding(padding: const EdgeInsets.all(24), child: Text(context.tr('nothing_to_water'), textAlign: TextAlign.center))
            : Column(mainAxisSize: MainAxisSize.min, children: [for (final r in watering) ReminderTile(reminder: r)]),
      ),
    );
  }
}
