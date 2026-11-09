import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/components/journal_components.dart';
import '../../auth/presentation/auth_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('edit_name')),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: ctx.tr('name'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(ctx.tr('save'))),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == current) return;
    try {
      await ref.read(authControllerProvider.notifier).updateName(name);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(localeProvider);
    final notifications = ref.watch(notificationsEnabledProvider);
    final config = ref.watch(appConfigProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: PageFrame(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            SectionLabel(context.tr('profile')),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(user?.name ?? '', style: text.titleLarge),
              subtitle: Text(user?.email ?? ''),
              trailing: IconButton(
                tooltip: context.tr('edit_name'),
                icon: const Icon(Icons.edit_outlined),
                onPressed: user == null ? null : () => _editName(context, ref, user.name),
              ),
            ),
            SectionLabel(context.tr('language')),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'en', label: Text('English')), ButtonSegment(value: 'ar', label: Text('العربية'))],
              selected: {locale.languageCode},
              onSelectionChanged: (s) => ref.read(localeProvider.notifier).setLocale(Locale(s.first)),
            ),
            SectionLabel(context.tr('notifications')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('notifications')),
              value: notifications,
              activeColor: AppColors.forest,
              onChanged: (v) => ref.read(notificationsEnabledProvider.notifier).setEnabled(v),
            ),
            SectionLabel(context.tr('api_url')),
            SelectableText(config.apiBaseUrl, style: text.bodyMedium?.copyWith(color: AppColors.inkSoft)),
            const SizedBox(height: 4),
            Text('${context.tr('version')} 1.0.0', style: text.bodySmall?.copyWith(color: AppColors.inkSoft)),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: Text(context.tr('logout')),
            ),
          ],
        ),
      ),
    );
  }
}
