import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/paged_result.dart';
import '../data/care_log_repository.dart';
import '../domain/care_log.dart';

typedef CareHistoryQuery = ({int? plantId, String? type});

final careHistoryProvider = FutureProvider.autoDispose.family<PagedResult<CareLog>, CareHistoryQuery>(
  (ref, q) => ref.watch(careLogRepositoryProvider).list(plantId: q.plantId, type: q.type),
);
