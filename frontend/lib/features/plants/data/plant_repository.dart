import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../shared/models/paged_result.dart';
import '../domain/plant.dart';
import '../domain/plant_category.dart';

class PlantRepository {
  PlantRepository(this._api);

  final ApiClient _api;

  Future<PagedResult<Plant>> list({
    int page = 1,
    int perPage = 15,
    String? search,
    int? categoryId,
    String? healthStatus,
    String sort = 'next_watering',
  }) async {
    final res = await _api.get(ApiEndpoints.plants, query: {
      'page': page,
      'per_page': perPage,
      'sort': sort,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId,
      if (healthStatus != null) 'health_status': healthStatus,
    });
    return PagedResult.fromResponse(res.data, res.meta, Plant.fromJson);
  }

  Future<Plant> get(int id) async {
    final res = await _api.get(ApiEndpoints.plant(id));
    return Plant.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Plant> create(PlantInput input) async {
    final res = await _api.post(ApiEndpoints.plants, body: _body(input));
    return Plant.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Plant> update(int id, PlantInput input) async {
    // PHP does not parse multipart PUT bodies, so uploads are POSTed with method spoofing.
    final res = input.hasImage
        ? await _api.post(ApiEndpoints.plant(id), body: _body(input, spoofPut: true))
        : await _api.put(ApiEndpoints.plant(id), body: _body(input));
    return Plant.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete(ApiEndpoints.plant(id));

  Future<Plant> water(int id) async => Plant.fromJson((await _api.post(ApiEndpoints.waterPlant(id))).data as Map<String, dynamic>);

  Future<Plant> fertilize(int id) async => Plant.fromJson((await _api.post(ApiEndpoints.fertilizePlant(id))).data as Map<String, dynamic>);

  Future<Plant> rotate(int id) async => Plant.fromJson((await _api.post(ApiEndpoints.rotatePlant(id))).data as Map<String, dynamic>);

  Object _body(PlantInput input, {bool spoofPut = false}) {
    final map = input.toMap()..removeWhere((k, v) => v == null);
    if (!input.hasImage) return map;
    final form = FormData.fromMap({
      ...map.map((k, v) => MapEntry(k, v.toString())),
      if (spoofPut) '_method': 'PUT',
      'image': MultipartFile.fromBytes(input.imageBytes!, filename: input.imageName ?? 'plant.jpg'),
    });
    return form;
  }
}

class CategoryRepository {
  CategoryRepository(this._api);

  final ApiClient _api;

  Future<List<PlantCategory>> list() async {
    final res = await _api.get(ApiEndpoints.categories);
    return (res.data as List).cast<Map<String, dynamic>>().map(PlantCategory.fromJson).toList();
  }
}

final plantRepositoryProvider = Provider<PlantRepository>((ref) => PlantRepository(ref.watch(apiClientProvider)));
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) => CategoryRepository(ref.watch(apiClientProvider)));
