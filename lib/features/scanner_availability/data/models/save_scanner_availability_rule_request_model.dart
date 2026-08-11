import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:flutter/material.dart';

/// Create/update payload for a weekly scanner rule
/// (`ClinicSaveScannerAvailabilityRuleRequest`). The API uses the same body
/// for both, so one model covers them.
class SaveScannerAvailabilityRuleRequestModel {
  final int dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int slotMinutes;
  final int gapMinutes;
  final int capacity;
  final bool isActive;

  const SaveScannerAvailabilityRuleRequestModel({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.slotMinutes = 30,
    this.gapMinutes = 0,
    this.capacity = 1,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': ApiTime.formatTime(startTime),
      'endTime': ApiTime.formatTime(endTime),
      'slotMinutes': slotMinutes,
      'gapMinutes': gapMinutes,
      'capacity': capacity,
      'isActive': isActive,
    };
  }
}
