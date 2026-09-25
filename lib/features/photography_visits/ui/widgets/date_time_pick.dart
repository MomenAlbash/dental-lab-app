import 'package:flutter/material.dart';

/// A date, then a time, as one local [DateTime]; null if either is dismissed.
Future<DateTime?> pickDateTime(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  final start = initial ?? now;

  final date = await showDatePicker(
    context: context,
    initialDate: start,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 2),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(start),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
