import 'package:flutter/material.dart';

/// Converts between the API's bare `time` / `date` strings and Dart's types.
///
/// These fields are not timestamps: a scanner availability rule says "09:00 to
/// 17:00 on Tuesdays", with no date and no zone attached. Parsing them as
/// `DateTime` would attach today's date and the device's offset to them, so
/// they are handled as [TimeOfDay] and date-only [DateTime] instead.
class ApiTime {
  ApiTime._();

  /// Parses `"HH:mm:ss"` (the API's `format: time`). Also accepts `"HH:mm"`,
  /// and returns null on anything unparseable rather than throwing — a bad
  /// value from the server must not take a whole screen down.
  static TimeOfDay? parseTime(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;

    final parts = text.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Formats as `"HH:mm:ss"` — seconds included because that is the shape the
  /// API's `TimeSpan`/`TimeOnly` binder expects.
  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  /// 24-hour `"HH:mm"` for display. Deliberately not localised to Arabic
  /// numerals or AM/PM: these are working hours on a schedule, read at a
  /// glance and compared against each other.
  static String displayTime(TimeOfDay? time) {
    if (time == null) return '—';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Parses `"yyyy-MM-dd"` (the API's `format: date`), tolerating a full
  /// timestamp by keeping only its date part.
  static DateTime? parseDate(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;

    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Formats as `"yyyy-MM-dd"`. Uses the date's own fields rather than
  /// `toIso8601String`, which would append a time and could shift the day
  /// across a UTC boundary.
  static String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Minutes since midnight — for ordering and for measuring a rule's span.
  static int minutesOf(TimeOfDay time) => time.hour * 60 + time.minute;
}

/// The API's `dayOfWeek` is 0–6 starting at Sunday (.NET's `DayOfWeek`), which
/// is also how the week reads in Arabic, so no remapping is needed.
class WeekDays {
  WeekDays._();

  static const List<String> arabicLabels = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  static String labelOf(int dayOfWeek) {
    if (dayOfWeek < 0 || dayOfWeek >= arabicLabels.length) return '—';
    return arabicLabels[dayOfWeek];
  }

  /// Dart's [DateTime.weekday] runs 1–7 from Monday; the API runs 0–6 from
  /// Sunday. Converting in one place keeps the off-by-one out of the screens.
  static int fromDateTime(DateTime date) => date.weekday % 7;
}
