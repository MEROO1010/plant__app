import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/components/journal_components.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/dashboard_data.dart';
import 'dashboard_controller.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  static const _ochre = Color(0xFF8A6A1E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(weeklyProgressProvider);
    final health = ref.watch(plantHealthProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('statistics')),
        actions: [IconButton(tooltip: context.tr('history'), icon: const Icon(Icons.history), onPressed: () => context.push('/history'))],
      ),
      body: PageFrame(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(weeklyProgressProvider);
            ref.invalidate(plantHealthProvider);
            await ref.read(weeklyProgressProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              SectionLabel(context.tr('weekly_progress')),
              SizedBox(
                height: 200,
                child: AsyncValueView<WeeklyProgress>(
                  value: weekly,
                  onRetry: () => ref.invalidate(weeklyProgressProvider),
                  builder: (w) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${w.completionPercentage}%', style: text.displaySmall?.copyWith(color: AppColors.forest)),
                      Text('${w.tasksCompleted} / ${w.tasksDue} ${context.tr('completed')}', style: text.bodyMedium?.copyWith(color: AppColors.inkSoft)),
                      const SizedBox(height: 12),
                      Expanded(child: _DayBars(days: w.days)),
                    ],
                  ),
                ),
              ),
              SectionLabel(context.tr('health')),
              AsyncValueView<PlantHealthStats>(
                value: health,
                onRetry: () => ref.invalidate(plantHealthProvider),
                builder: (h) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${h.healthyPercentage}% ${context.tr('healthy_share')}', style: text.titleLarge),
                    const SizedBox(height: 14),
                    if (h.total > 0)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Row(children: [
                          for (final entry in {'healthy': AppColors.forest, 'needs_attention': _ochre, 'critical': AppColors.coral}.entries)
                            if ((h.breakdown[entry.key] ?? 0) > 0) Expanded(flex: h.breakdown[entry.key]!, child: Container(height: 14, color: entry.value)),
                        ]),
                      ),
                    const SizedBox(height: 14),
                    for (final entry in {'healthy': AppColors.forest, 'needs_attention': _ochre, 'critical': AppColors.coral}.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Container(width: 12, height: 12, color: entry.value),
                          const SizedBox(width: 10),
                          Expanded(child: Text(context.tr(entry.key))),
                          Text('${h.breakdown[entry.key] ?? 0}', style: text.titleMedium),
                        ]),
                      ),
                    const Divider(height: 28),
                    Row(children: [
                      Expanded(child: Text(context.tr('overdue_watering'))),
                      Text('${h.overdueWatering}', style: text.titleMedium?.copyWith(color: h.overdueWatering > 0 ? AppColors.coral : null)),
                    ]),
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

class _DayBars extends StatelessWidget {
  const _DayBars({required this.days});

  final List<DayProgress> days;

  @override
  Widget build(BuildContext context) {
    final maxDue = math.max(1, days.fold<int>(0, (m, d) => math.max(m, d.tasksDue)));
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(builder: (context, c) {
      final barArea = c.maxHeight - 22;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days)
            Expanded(
              child: Semantics(
                label: '${d.day}: ${d.tasksCompleted}/${d.tasksDue}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: barArea,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Stack(alignment: Alignment.bottomCenter, children: [
                          Container(width: 22, height: math.max(4, barArea * d.tasksDue / maxDue), color: AppColors.line),
                          Container(width: 22, height: barArea * d.tasksCompleted / maxDue, color: AppColors.forest),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(d.day, style: text.labelSmall),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}
