import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:flutter/material.dart';

/// Payload for `PUT /scanner-availability/exceptions`
/// (`ClinicSaveScannerAvailabilityExceptionRequest`).
///
/// It is a PUT and keys off [date], not an id: saving twice for the same day
/// replaces that day's exception rather than stacking a second one.
class SaveScannerAvailabilityExceptionRequestModel {
  final DateTime date;
  final bool isClosed;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? reason;

  const SaveScannerAvailabilityExceptionRequestModel({
    required this.date,
    required this.isClosed,
    this.startTime,
    this.endTime,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': ApiTime.formatDate(date),
      'isClosed': isClosed,
      // Hours on a closed day would be contradictory, so they are dropped
      // rather than sent alongside it.
      'startTime': isClosed || startTime == null
          ? null
          : ApiTime.formatTime(startTime!),
      'endTime': isClosed || endTime == null
          ? null
          : ApiTime.formatTime(endTime!),
      'reason': reason,
    };
  }
}
