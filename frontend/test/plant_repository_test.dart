import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

import 'package:plant_care/core/networking/api_exception.dart';
import 'package:plant_care/features/plants/data/plant_repository.dart';
import 'package:plant_care/features/plants/domain/plant.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeAdapter adapter;
  late PlantRepository repo;

  setUp(() {
    adapter = FakeAdapter();
    repo = PlantRepository(makeClient(adapter));
  });

  test('list sends filters and parses pagination', () async {
    adapter.on('GET', '/plants', ok([plantJson(), plantJson(id: 2, name: 'Goldie')], meta: {'current_page': 1, 'last_page': 2, 'per_page': 15, 'total': 20}));

    final page = await repo.list(search: 'mon', categoryId: 3, healthStatus: 'critical');

    expect(page.items.map((p) => p.name), ['Monty', 'Goldie']);
    expect(page.hasMore, isTrue);
    final q = adapter.requests.single.queryParameters;
    expect(q['search'], 'mon');
    expect(q['category_id'], 3);
    expect(q['health_status'], 'critical');
    expect(q['sort'], 'next_watering');
  });

  test('get, water, fertilize and rotate return the updated plant', () async {
    adapter
      ..on('GET', '/plants/1', ok(plantJson()))
      ..on('POST', '/plants/1/water', ok(plantJson(name: 'Watered')))
      ..on('POST', '/plants/1/fertilize', ok(plantJson()))
      ..on('POST', '/plants/1/rotate', ok(plantJson()));

    expect((await repo.get(1)).name, 'Monty');
    expect((await repo.water(1)).name, 'Watered');
    await repo.fertilize(1);
    await repo.rotate(1);
    expect(adapter.called('POST', '/plants/1/fertilize'), isTrue);
  });

  test('create posts JSON without null fields', () async {
    adapter.on('POST', '/plants', ok(plantJson()), status: 201);
    await repo.create(const PlantInput(name: 'Monty', species: 'Monstera'));

    final data = adapter.requests.single.data as Map<String, dynamic>;
    expect(data['name'], 'Monty');
    expect(data.containsKey('location'), isFalse);
  });

  test('update without image uses PUT', () async {
    adapter.on('PUT', '/plants/1', ok(plantJson()));
    await repo.update(1, const PlantInput(name: 'Renamed'));
    expect(adapter.called('PUT', '/plants/1'), isTrue);
  });

  test('update with image uses multipart POST with method spoofing', () async {
    adapter.on('POST', '/plants/1', ok(plantJson()));
    await repo.update(1, PlantInput(name: 'Renamed', imageBytes: Uint8List.fromList([1, 2, 3]), imageName: 'p.jpg'));

    final req = adapter.requests.single;
    expect(req.method, 'POST');
    final form = req.data as FormData;
    expect(form.fields.any((f) => f.key == '_method' && f.value == 'PUT'), isTrue);
    expect(form.files.single.key, 'image');
  });

  test('validation errors are exposed field by field', () async {
    adapter.on('POST', '/plants', failure('The given data was invalid.', errors: {'name': ['The name field is required.']}), status: 422);

    expect(
      () => repo.create(const PlantInput(name: '')),
      throwsA(isA<ApiException>().having((e) => e.errors['name'], 'name errors', ['The name field is required.']).having((e) => e.isValidation, 'isValidation', true)),
    );
  });

  test('forbidden and not-found map to ApiException with status', () async {
    adapter.on('GET', '/plants/9', failure('You are not allowed to perform this action.'), status: 403);
    expect(() => repo.get(9), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)));
    expect(() => repo.get(404), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)));
  });

  test('categories repository parses a list', () async {
    adapter.on('GET', '/categories', ok([{'id': 1, 'name': 'Indoor', 'slug': 'indoor'}]));
    final cats = await CategoryRepository(makeClient(adapter)).list();
    expect(cats.single.slug, 'indoor');
  });
}
