import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:flutter/material.dart';

/// One weekly window in which the lab's scanner takes appointments
/// (`ClinicScannerAvailabilityRuleDto`).
///
/// A rule is a recurring template, not a booking: "Tuesdays 09:00–17:00, in
/// 30-minute slots, 2 patients at a time". The server expands it into the
/// concrete days and slots the doctor picks from — see `ScannerDayModel`.
class ScannerAvailabilityRuleModel {
  final String id;

  /// 0–6 starting at Sunday. See [WeekDays].
  final int dayOfWeek;

  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  /// How long one appointment lasts.
  final int slotMinutes;

  /// Dead time left after each slot — cleaning, or the next patient walking
  /// in. Slots are laid out every `slotMinutes + gapMinutes`.
  final int gapMinutes;

  /// How many appointments may share a single slot.
  final int capacity;

  final bool isActive;

  const ScannerAvailabilityRuleModel({
    required this.id,
    this.dayOfWeek = 0,
    this.startTime,
    this.endTime,
    this.slotMinutes = 30,
    this.gapMinutes = 0,
    this.capacity = 1,
    this.isActive = true,
  });

  String get dayLabel => WeekDays.labelOf(dayOfWeek);

  String get timeRangeLabel =>
      '${ApiTime.displayTime(startTime)} - ${ApiTime.displayTime(endTime)}';

  /// How many appointments this rule offers per week — the number the lab
  /// actually cares about when deciding whether to open another day.
  ///
  /// Null when the window is unusable (missing or inverted times), so the UI
  /// can say nothing rather than show a misleading zero.
  int? get slotsPerDay {
    final start = startTime;
    final end = endTime;
    if (start == null || end == null) return null;

    final span = ApiTime.minutesOf(end) - ApiTime.minutesOf(start);
    final step = slotMinutes + gapMinutes;
    if (span <= 0 || step <= 0) return null;

    // The trailing gap after the last slot does not need to fit inside the
    // window — the scanner is free by then.
    return ((span + gapMinutes) ~/ step) * capacity;
  }

  factory ScannerAvailabilityRuleModel.fromJson(Map<String, dynamic> json) {
    return ScannerAvailabilityRuleModel(
      id: json['id'] as String,
      dayOfWeek: json['dayOfWeek'] as int? ?? 0,
      startTime: ApiTime.parseTime(json['startTime'] as String?),
      endTime: ApiTime.parseTime(json['endTime'] as String?),
      slotMinutes: json['slotMinutes'] as int? ?? 30,
      gapMinutes: json['gapMinutes'] as int? ?? 0,
      capacity: json['capacity'] as int? ?? 1,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
