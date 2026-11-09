import 'package:flutter/widgets.dart';

import 'app_strings.dart';

/// Validators return a translation KEY (or null when valid).
/// Wrap with [localized] inside a form field so the message is translated.
class Validators {
  static String? required(String? v) => (v == null || v.trim().isEmpty) ? 'required_field' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'required_field';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'invalid_email';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'required_field';
    return v.length < 8 ? 'password_short' : null;
  }

  static String? positiveInt(String? v) {
    if (v == null || v.trim().isEmpty) return 'required_field';
    final n = int.tryParse(v.trim());
    return (n == null || n < 1) ? 'positive_number' : null;
  }
}

FormFieldValidator<String> localized(BuildContext context, String? Function(String?) validator) {
  return (value) {
    final key = validator(value);
    return key == null ? null : context.tr(key);
  };
}
