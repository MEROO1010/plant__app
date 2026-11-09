import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../shared/models/paged_result.dart';
import '../domain/care_log.dart';

class CareLogRepository {
  CareLogRepository(this._api);

  final ApiClient _api;

  Future<PagedResult<CareLog>> list({int page = 1, int perPage = 30, int? plantId, String? type}) async {
    final res = await _api.get(ApiEndpoints.careLogs, query: {
      'page': page,
      'per_page': perPage,
      if (plantId != null) 'plant_id': plantId,
      if (type != null) 'type': type,
    });
    return PagedResult.fromResponse(res.data, res.meta, CareLog.fromJson);
  }
}

final careLogRepositoryProvider = Provider<CareLogRepository>((ref) => CareLogRepository(ref.watch(apiClientProvider)));
