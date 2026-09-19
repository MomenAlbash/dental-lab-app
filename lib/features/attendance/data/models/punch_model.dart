import 'package:dental_lab_app/core/helper/api_time_helper.dart';

/// One raw fingerprint punch (`PunchDto`).
///
/// Distinct from an attendance *session*: this is the stamp itself, while a
/// session is the in/out pairing the server derives from a day's stamps. The
/// day-detail screen lists, edits and removes these; the sessions above them
/// are read-only consequences.
class PunchModel {
  const PunchModel({required this.id, this.timestamp, this.isManual = false});

  final String id;
  final DateTime? timestamp;

  /// Entered by hand rather than read off a terminal. The only signal for it
  /// today is the absence of a device on the log row.
  final bool isManual;

  String get timeLabel {
    final value = timestamp;
    if (value == null) return '—';
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  factory PunchModel.fromJson(Map<String, dynamic> json) {
    return PunchModel(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? ''),
      isManual: json['isManual'] as bool? ?? false,
    );
  }
}

/// `AddManualPunchRequest` — a stamp the device missed, entered by hand.
class AddManualPunchRequestModel {
  const AddManualPunchRequestModel({
    required this.employeeId,
    required this.timestamp,
  });

  final String employeeId;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// One employee/day a punch could not be recorded for (`LockedAttendanceDateDto`).
///
/// It fell inside a salary statement that is already approved or paid, so the
/// day is closed — reported back rather than silently dropped, since somebody
/// has to decide whether to revert that statement.
class LockedAttendanceDateModel {
  const LockedAttendanceDateModel({required this.employeeId, this.date});

  final String employeeId;
  final DateTime? date;

  factory LockedAttendanceDateModel.fromJson(Map<String, dynamic> json) {
    return LockedAttendanceDateModel(
      employeeId: json['employeeId'] as String? ?? '',
      date: ApiTime.parseDate(json['date'] as String?),
    );
  }
}

/// What came back from posting a batch of raw device punches
/// (`PunchIngestResultDto`).
class PunchIngestResultModel {
  const PunchIngestResultModel({
    this.recordedCount = 0,
    this.unresolvedDeviceUserIds = const [],
    this.skippedLockedDates = const [],
  });

  final int recordedCount;

  /// Device user ids nobody has mapped to an employee yet — the enrolment
  /// screen's to-do list, and the reason those punches were dropped.
  final List<String> unresolvedDeviceUserIds;

  final List<LockedAttendanceDateModel> skippedLockedDates;

  factory PunchIngestResultModel.fromJson(Map<String, dynamic> json) {
    return PunchIngestResultModel(
      recordedCount: json['recordedCount'] as int? ?? 0,
      unresolvedDeviceUserIds: [
        for (final id
            in json['unresolvedDeviceUserIds'] as List<dynamic>? ?? const [])
          if (id is String) id,
      ],
      skippedLockedDates: [
        for (final entry
            in json['skippedLockedDates'] as List<dynamic>? ?? const [])
          LockedAttendanceDateModel.fromJson(entry as Map<String, dynamic>),
      ],
    );
  }
}
