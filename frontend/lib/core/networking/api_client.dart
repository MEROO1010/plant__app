import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

/// The unwrapped `{success, message, data, meta}` envelope returned by the API.
class ApiResponse {
  const ApiResponse({required this.data, required this.meta, required this.message});

  final dynamic data;
  final Map<String, dynamic> meta;
  final String message;
}

/// Thin wrapper around Dio. Widgets never use this directly: only repositories do.
class ApiClient {
  ApiClient({required Dio dio, required TokenStorage tokenStorage}) : _dio = dio {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.readToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          options.headers['Accept'] = 'application/json';
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) onUnauthorized?.call();
          handler.next(error);
        },
      ),
    );
  }

  factory ApiClient.create({required String baseUrl, required TokenStorage tokenStorage}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    return ApiClient(dio: dio, tokenStorage: tokenStorage);
  }

  final Dio _dio;

  /// Called when the server answers 401 (expired/revoked token).
  VoidCallback? onUnauthorized;

  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<ApiResponse> post(String path, {Object? body}) => _send(() => _dio.post<dynamic>(path, data: body));

  Future<ApiResponse> put(String path, {Object? body}) => _send(() => _dio.put<dynamic>(path, data: body));

  Future<ApiResponse> delete(String path) => _send(() => _dio.delete<dynamic>(path));

  Future<ApiResponse> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return ApiResponse(
          data: body['data'],
          meta: (body['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
          message: (body['message'] as String?) ?? '',
        );
      }
      return const ApiResponse(data: null, meta: {}, message: '');
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  ApiException _toException(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;

    if (body is Map<String, dynamic>) {
      final errors = <String, List<String>>{};
      final raw = body['errors'];
      if (raw is Map) {
        raw.forEach((key, value) {
          errors[key.toString()] = (value as List).map((v) => v.toString()).toList();
        });
      }
      return ApiException((body['message'] as String?) ?? 'Request failed', statusCode: status, errors: errors);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('The server took too long to respond.', statusCode: status);
      case DioExceptionType.connectionError:
        return ApiException('Cannot reach the server. Check your connection and the API URL.', statusCode: status);
      default:
        return ApiException('Something went wrong. Please try again.', statusCode: status);
    }
  }
}
