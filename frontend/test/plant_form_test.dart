import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care/features/plants/domain/plant.dart';
import 'package:plant_care/features/plants/presentation/plant_form.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpForm(WidgetTester tester, Future<void> Function(PlantInput) onSubmit) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(Scaffold(body: PlantForm(categories: const [], onSubmit: onSubmit))));
  }

  testWidgets('empty name is rejected and nothing is submitted', (tester) async {
    var submitted = false;
    await pumpForm(tester, (_) async => submitted = true);

    await tester.tap(find.byKey(const Key('submit_plant')));
    await tester.pump();

    expect(find.text('This field is required'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('watering interval must be a whole number >= 1', (tester) async {
    var submitted = false;
    await pumpForm(tester, (_) async => submitted = true);

    await tester.enterText(find.byKey(const Key('plant_name_field')), 'Fern');
    await tester.enterText(find.byKey(const Key('water_interval_field')), '0');
    await tester.tap(find.byKey(const Key('submit_plant')));
    await tester.pump();
    expect(find.text('Enter a whole number of 1 or more'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('water_interval_field')), 'abc');
    await tester.tap(find.byKey(const Key('submit_plant')));
    await tester.pump();
    expect(find.text('Enter a whole number of 1 or more'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('valid form submits the entered values', (tester) async {
    PlantInput? received;
    await pumpForm(tester, (input) async => received = input);

    await tester.enterText(find.byKey(const Key('plant_name_field')), '  Fern  ');
    await tester.enterText(find.byKey(const Key('water_interval_field')), '4');
    await tester.enterText(find.byKey(const Key('fertilize_interval_field')), '21');
    await tester.tap(find.byKey(const Key('submit_plant')));
    await tester.pumpAndSettle();

    expect(received, isNotNull);
    expect(received!.name, 'Fern');
    expect(received!.wateringIntervalDays, 4);
    expect(received!.fertilizingIntervalDays, 21);
    expect(received!.species, isNull);
  });

  testWidgets('edit mode pre-fills the existing plant', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp(Scaffold(body: PlantForm(initial: Plant.fromJson(plantJson()), categories: const [], onSubmit: (_) async {}))));

    expect(find.widgetWithText(TextFormField, 'Monty'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '7'), findsOneWidget);
  });
}
