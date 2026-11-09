import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/app_strings.dart';
import '../utils/responsive.dart';

/// Bottom navigation on phones, navigation rail on tablet/desktop.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _paths = ['/dashboard', '/plants', '/reminders', '/statistics', '/settings'];
  static const _items = [
    (Icons.menu_book_outlined, Icons.menu_book, 'journal'),
    (Icons.eco_outlined, Icons.eco, 'plants'),
    (Icons.checklist_outlined, Icons.checklist, 'tasks'),
    (Icons.insights_outlined, Icons.insights, 'progress'),
    (Icons.settings_outlined, Icons.settings, 'settings'),
  ];

  int get _index {
    if (location.startsWith('/plants')) return 1;
    if (location.startsWith('/reminders')) return 2;
    if (location.startsWith('/statistics') || location.startsWith('/history')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= Breakpoints.tablet) {
      final extended = width >= Breakpoints.desktop;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              extended: extended,
              labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              onDestinationSelected: (i) => context.go(_paths[i]),
              destinations: [
                for (final (icon, selected, key) in _items)
                  NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(context.tr(key))),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => context.go(_paths[i]),
        destinations: [
          for (final (icon, selected, key) in _items)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: context.tr(key)),
        ],
      ),
    );
  }
}
