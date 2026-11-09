import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/components/journal_components.dart';
import '../domain/reminder.dart';
import 'reminders_controller.dart';

class ReminderTile extends ConsumerWidget {
  const ReminderTile({super.key, required this.reminder, this.showComplete = true});

  final Reminder reminder;
  final bool showComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(remindersControllerProvider.select((s) => s.completingIds.contains(reminder.id)));
    final now = DateTime.now();
    final overdue = reminder.dueAt.isBefore(DateTime(now.year, now.month, now.day));
    final color = overdue ? AppColors.coral : AppColors.inkSoft;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(careIcon(reminder.type), color: overdue ? AppColors.coral : AppColors.forest),
        title: Text(reminder.title, style: text.titleMedium),
        subtitle: Text(
          [if (reminder.plantName != null) reminder.plantName!, relativeDay(context, reminder.dueAt)].join(' · '),
          style: text.bodySmall?.copyWith(color: color, fontWeight: overdue ? FontWeight.w700 : null),
        ),
        trailing: showComplete
            ? IconButton(
                tooltip: context.tr('complete'),
                onPressed: busy ? null : () => ref.read(remindersControllerProvider.notifier).complete(reminder.id),
                icon: busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline, color: AppColors.forest),
              )
            : null,
      ),
    );
  }
}
