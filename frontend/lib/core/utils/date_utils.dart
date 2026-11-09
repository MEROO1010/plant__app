import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_strings.dart';

DateTime? parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today", "Tomorrow", "Overdue" or a short date, in the active locale.
String relativeDay(BuildContext context, DateTime? date, {DateTime? now}) {
  if (date == null) return context.tr('never');
  final today = now ?? DateTime.now();
  final locale = Localizations.localeOf(context).toString();
  if (isSameDay(date, today)) return context.tr('today');
  if (isSameDay(date, today.add(const Duration(days: 1)))) return context.tr('tomorrow');
  if (date.isBefore(DateTime(today.year, today.month, today.day))) return context.tr('overdue');
  return DateFormat.MMMd(locale).format(date);
}

String shortDate(BuildContext context, DateTime? date) {
  if (date == null) return context.tr('never');
  return DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);
}

String shortDateTime(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return '${DateFormat.MMMd(locale).format(date)} · ${DateFormat.jm(locale).format(date)}';
}
