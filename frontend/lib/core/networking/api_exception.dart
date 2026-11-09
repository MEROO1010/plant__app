/// Error raised by [ApiClient] for any failed request.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;

  /// Laravel validation errors: field -> messages.
  final Map<String, List<String>> errors;

  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 422;

  /// The first field error if there is one, otherwise the general message.
  String get displayMessage {
    for (final list in errors.values) {
      if (list.isNotEmpty) return list.first;
    }
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
