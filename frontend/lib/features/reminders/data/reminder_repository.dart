import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/providers.dart';
import '../domain/reminder.dart';

class ReminderRepository {
  ReminderRepository(this._api);

  final ApiClient _api;

  Future<List<Reminder>> today() async => _list((await _api.get(ApiEndpoints.remindersToday)).data);

  Future<List<Reminder>> upcoming() async => _list((await _api.get(ApiEndpoints.remindersUpcoming)).data);

  Future<Reminder> complete(int id) async {
    final res = await _api.post(ApiEndpoints.completeReminder(id));
    return Reminder.fromJson(res.data as Map<String, dynamic>);
  }

  List<Reminder> _list(dynamic data) => (data as List).cast<Map<String, dynamic>>().map(Reminder.fromJson).toList();
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) => ReminderRepository(ref.watch(apiClientProvider)));
