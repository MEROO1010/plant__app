import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care/core/providers.dart';
import 'package:plant_care/features/reminders/presentation/reminders_controller.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeAdapter adapter;
  late ProviderContainer container;
  late List<Map<String, dynamic>> today;

  setUp(() {
    adapter = FakeAdapter();
    today = [reminderJson(id: 1), reminderJson(id: 2, title: 'Water Goldie')];
    adapter
      ..on('GET', '/reminders/today', () => ok(today))
      ..on('GET', '/reminders/upcoming', ok([reminderJson(id: 3, type: 'fertilizing', title: 'Fertilize Monty')]));

    final storage = MemoryStorage();
    container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(makeClient(adapter, storage)),
      settingsStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
  });

  test('load fills today and upcoming lists', () async {
    await container.read(remindersControllerProvider.notifier).load();

    final state = container.read(remindersControllerProvider);
    expect(state.today.map((r) => r.id), [1, 2]);
    expect(state.upcoming.single.title, 'Fertilize Monty');
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('completing a reminder calls the API and removes it from the list', () async {
    adapter.on('POST', '/reminders/1/complete', ok(reminderJson(id: 1, completed: true)));
    final controller = container.read(remindersControllerProvider.notifier);
    await controller.load();

    // After completion the server no longer returns reminder 1.
    today = [reminderJson(id: 2, title: 'Water Goldie')];
    final done = await controller.complete(1);

    final state = container.read(remindersControllerProvider);
    expect(done, isTrue);
    expect(adapter.called('POST', '/reminders/1/complete'), isTrue);
    expect(state.today.map((r) => r.id), [2]);
    expect(state.completingIds, isEmpty);
  });

  test('a failed completion keeps the reminder and records the error', () async {
    adapter.on('POST', '/reminders/1/complete', failure('You are not allowed to perform this action.'), status: 403);
    final controller = container.read(remindersControllerProvider.notifier);
    await controller.load();

    final done = await controller.complete(1);

    final state = container.read(remindersControllerProvider);
    expect(done, isFalse);
    expect(state.today.map((r) => r.id), contains(1));
    expect(state.error, isNotNull);
    expect(state.completingIds, isEmpty);
  });

  test('load failure sets the error state', () async {
    adapter.on('GET', '/reminders/today', failure('Server error.'), status: 500);
    await container.read(remindersControllerProvider.notifier).load();

    final state = container.read(remindersControllerProvider);
    expect(state.error, isNotNull);
    expect(state.isLoading, isFalse);
  });
}
