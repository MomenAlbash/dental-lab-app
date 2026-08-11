import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:flutter/material.dart';

/// An override for one specific date
/// (`ClinicScannerAvailabilityExceptionDto`).
///
/// Two shapes, told apart by [isClosed]: the scanner is shut that day (a
/// holiday, maintenance), or it runs different hours than the weekly rule
/// would give it.
class ScannerAvailabilityExceptionModel {
  final String id;
  final DateTime? date;
  final bool isClosed;

  /// Only meaningful when [isClosed] is false — the hours that replace the
  /// weekly rule for this date.
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  /// Shown to the doctor as the reason the day is unavailable, so it is worth
  /// filling in on a closure.
  final String? reason;

  const ScannerAvailabilityExceptionModel({
    required this.id,
    this.date,
    this.isClosed = true,
    this.startTime,
    this.endTime,
    this.reason,
  });

  String get dateLabel => date == null ? '—' : ApiTime.formatDate(date!);

  String get summaryLabel {
    if (isClosed) return 'مغلق';
    return '${ApiTime.displayTime(startTime)} - ${ApiTime.displayTime(endTime)}';
  }

  factory ScannerAvailabilityExceptionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ScannerAvailabilityExceptionModel(
      id: json['id'] as String,
      date: ApiTime.parseDate(json['date'] as String?),
      isClosed: json['isClosed'] as bool? ?? true,
      startTime: ApiTime.parseTime(json['startTime'] as String?),
      endTime: ApiTime.parseTime(json['endTime'] as String?),
      reason: json['reason'] as String?,
    );
  }
}
