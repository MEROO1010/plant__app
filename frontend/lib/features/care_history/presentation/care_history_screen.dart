import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/components/journal_components.dart';
import '../../../shared/models/paged_result.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/care_log.dart';
import 'care_history_controller.dart';

class CareHistoryScreen extends ConsumerStatefulWidget {
  const CareHistoryScreen({super.key, this.plantId});

  final int? plantId;

  @override
  ConsumerState<CareHistoryScreen> createState() => _CareHistoryScreenState();
}

class _CareHistoryScreenState extends ConsumerState<CareHistoryScreen> {
  String? _type;

  @override
  Widget build(BuildContext context) {
    final query = (plantId: widget.plantId, type: _type);
    final logs = ref.watch(careHistoryProvider(query));
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('history'))),
      body: PageFrame(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(label: Text(context.tr('all')), selected: _type == null, onSelected: (_) => setState(() => _type = null)),
                  ),
                  for (final t in AppConstants.careTypes)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(label: Text(context.tr(t)), selected: _type == t, onSelected: (_) => setState(() => _type = _type == t ? null : t)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AsyncValueView<PagedResult<CareLog>>(
                value: logs,
                onRetry: () => ref.invalidate(careHistoryProvider(query)),
                builder: (page) {
                  if (page.items.isEmpty) {
                    return EmptyState(icon: Icons.history, title: context.tr('empty_history'), message: context.tr('empty_history_hint'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(careHistoryProvider(query));
                      await ref.read(careHistoryProvider(query).future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: page.items.length,
                      itemBuilder: (_, i) {
                        final log = page.items[i];
                        return Container(
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(careIcon(log.type), color: AppColors.forest),
                            title: Text([context.tr(log.type), if (log.plantName != null) log.plantName!].join(' · '), style: text.titleMedium),
                            subtitle: log.notes == null || log.notes!.isEmpty ? null : Text(log.notes!),
                            trailing: Text(shortDateTime(context, log.performedAt), style: text.bodySmall?.copyWith(color: AppColors.inkSoft)),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
