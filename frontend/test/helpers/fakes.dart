import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:plant_care/core/networking/api_client.dart';
import 'package:plant_care/core/storage/secure_storage_service.dart';
import 'package:plant_care/core/theme/app_theme.dart';
import 'package:plant_care/core/utils/app_strings.dart';

class MemoryStorage implements TokenStorage, SettingsStorage {
  String? token;
  final Map<String, String> values = {};

  @override
  Future<String?> readToken() async => token;
  @override
  Future<void> writeToken(String t) async => token = t;
  @override
  Future<void> deleteToken() async => token = null;
  @override
  Future<String?> readString(String key) async => values[key];
  @override
  Future<void> writeString(String key, String value) async => values[key] = value;
}

/// Serves canned API responses and records requests. A route body may be a value or a function
/// (so a test can return different data on successive calls).
class FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final Map<String, ({int status, Object? body})> _routes = {};

  void on(String method, String path, Object? body, {int status = 200}) => _routes['$method $path'] = (status: status, body: body);

  bool called(String method, String path) => requests.any((r) => r.method == method && r.path == path);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final route = _routes['${options.method} ${options.path}'];
    final status = route?.status ?? 404;
    var body = route?.body ?? {'success': false, 'message': 'Not found', 'data': null};
    if (body is Function) body = body();
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> ok(Object? data, {Map<String, dynamic> meta = const {}}) =>
    {'success': true, 'message': 'ok', 'data': data, 'meta': meta};

Map<String, dynamic> failure(String message, {Map<String, List<String>>? errors}) =>
    {'success': false, 'message': message, 'data': null, if (errors != null) 'errors': errors};

ApiClient makeClient(FakeAdapter adapter, [TokenStorage? tokens]) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = adapter;
  return ApiClient(dio: dio, tokenStorage: tokens ?? MemoryStorage());
}

Map<String, dynamic> plantJson({int id = 1, String name = 'Monty', String health = 'healthy', bool needsWatering = false}) => {
      'id': id,
      'plant_category_id': 1,
      'category': {'id': 1, 'name': 'Tropical', 'slug': 'tropical', 'description': null, 'icon': null, 'color': '#3E7C59'},
      'name': name,
      'species': 'Monstera deliciosa',
      'description': null,
      'image_url': null,
      'location': 'Living room',
      'light_level': 'bright',
      'watering_interval_days': 7,
      'fertilizing_interval_days': 30,
      'last_watered_at': '2026-11-01T09:00:00+00:00',
      'next_watering_at': '2026-11-08T09:00:00+00:00',
      'last_fertilized_at': null,
      'next_fertilizing_at': null,
      'needs_watering': needsWatering,
      'health_status': health,
      'notes': null,
    };

Map<String, dynamic> reminderJson({int id = 1, String type = 'watering', String title = 'Water Monty', bool completed = false}) => {
      'id': id,
      'plant_id': 1,
      'plant': {'id': 1, 'name': 'Monty', 'image_url': null},
      'type': type,
      'title': title,
      'description': null,
      'due_at': '2026-11-05T09:00:00+00:00',
      'completed_at': null,
      'is_completed': completed,
      'is_overdue': false,
    };

/// MaterialApp with the app's localisation, without runtime Google Fonts fetching.
Widget testApp(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: AppTheme.light(locale, useGoogleFonts: false),
      locale: locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: AppStrings.localizationsDelegates,
      home: home,
    );
