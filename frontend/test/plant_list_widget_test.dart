import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care/core/providers.dart';
import 'package:plant_care/features/plants/presentation/plant_list_screen.dart';

import 'helpers/fakes.dart';

Widget _app(FakeAdapter adapter) => ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(makeClient(adapter))],
      child: testApp(const PlantListScreen()),
    );

void main() {
  testWidgets('shows plants returned by the API', (tester) async {
    final adapter = FakeAdapter()
      ..on('GET', '/categories', ok([]))
      ..on('GET', '/plants', ok([plantJson(), plantJson(id: 2, name: 'Goldie', health: 'critical')], meta: {'current_page': 1, 'last_page': 1, 'total': 2}));

    await tester.pumpWidget(_app(adapter));
    await tester.pumpAndSettle();

    expect(find.text('Monty'), findsOneWidget);
    expect(find.text('Goldie'), findsOneWidget);
    expect(find.text('Critical'), findsWidgets); // chip on the plant + the filter chip
  });

  testWidgets('shows the empty state when there are no plants', (tester) async {
    final adapter = FakeAdapter()
      ..on('GET', '/categories', ok([]))
      ..on('GET', '/plants', ok([], meta: {'current_page': 1, 'last_page': 1, 'total': 0}));

    await tester.pumpWidget(_app(adapter));
    await tester.pumpAndSettle();

    expect(find.text('No plants yet'), findsOneWidget);
    expect(find.text('Add plant'), findsWidgets);
  });

  testWidgets('shows an error with retry, and recovers', (tester) async {
    final adapter = FakeAdapter()
      ..on('GET', '/categories', ok([]))
      ..on('GET', '/plants', failure('Server error.'), status: 500);

    await tester.pumpWidget(_app(adapter));
    await tester.pumpAndSettle();
    expect(find.text('Server error.'), findsOneWidget);

    adapter.on('GET', '/plants', ok([plantJson()], meta: {'current_page': 1, 'last_page': 1, 'total': 1}));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Monty'), findsOneWidget);
  });

  testWidgets('shows a loading indicator while fetching', (tester) async {
    final adapter = FakeAdapter()
      ..on('GET', '/categories', ok([]))
      ..on('GET', '/plants', ok([plantJson()], meta: {'current_page': 1, 'last_page': 1, 'total': 1}));

    await tester.pumpWidget(_app(adapter));
    await tester.pump(); // first frame: load() has started
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
