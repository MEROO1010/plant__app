import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/reminder.dart';
import 'reminder_tile.dart';
import 'reminders_controller.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(remindersControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(remindersControllerProvider);
    final nothingYet = state.today.isEmpty && state.upcoming.isEmpty;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('tasks')),
          bottom: TabBar(tabs: [Tab(text: context.tr('today')), Tab(text: context.tr('upcoming'))]),
        ),
        body: PageFrame(
          child: Builder(builder: (context) {
            if (state.isLoading && nothingYet) return const LoadingView();
            if (state.error != null && nothingYet) {
              return ErrorView(error: state.error!, onRetry: () => ref.read(remindersControllerProvider.notifier).load());
            }
            return TabBarView(children: [
              _ReminderList(items: state.today),
              _ReminderList(items: state.upcoming),
            ]);
          }),
        ),
      ),
    );
  }
}

class _ReminderList extends ConsumerWidget {
  const _ReminderList({required this.items});

  final List<Reminder> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.check_circle_outline,
        title: context.tr('empty_reminders'),
        message: context.tr('empty_reminders_hint'),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(remindersControllerProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: items.length,
        itemBuilder: (_, i) => ReminderTile(reminder: items[i]),
      ),
    );
  }
}
