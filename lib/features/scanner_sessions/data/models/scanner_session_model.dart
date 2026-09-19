import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_enums.dart';

/// A representative who could take a scanner session
/// (`ClinicZoneRepresentativeDto`).
///
/// [userId] — not an employee id: a representative is a login
/// (`UserType.Representative`), and someone with no login cannot be assigned
/// anything. `employeeId`/`employeeName` were never real keys on this DTO —
/// every representative picker read blank names and empty ids until this was
/// fixed.
class ZoneRepresentativeModel {
  const ZoneRepresentativeModel({
    required this.id,
    required this.userId,
    this.name,
    this.phoneNumber,
    this.isPrimary = false,
  });

  final String id;
  final String userId;
  final String? name;
  final String? phoneNumber;

  /// The zone's first choice. A presentation hint for ordering the list — it
  /// grants nothing the others do not.
  final bool isPrimary;

  factory ZoneRepresentativeModel.fromJson(Map<String, dynamic> json) {
    return ZoneRepresentativeModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

/// A scanner session — a doctor asking the lab to send someone to scan
/// (`ClinicScannerSessionDto`).
///
/// **The API reports only the current assignee.** MOBILE-SPEC §15.6 describes
/// a `representatives[]` array carrying one row per attempt, so a dispatcher
/// could see who declined and why. The live DTO has no such field: it exposes
/// the flat convenience fields only. The refusal history therefore cannot be
/// shown, and this model does not pretend otherwise.
class ScannerSessionModel {
  const ScannerSessionModel({
    required this.id,
    this.sessionNumber,
    this.doctorId,
    this.doctorName,
    this.doctorNumber,
    this.clinicId,
    this.clinicName,
    this.doctorAddress,
    this.doctorLatitude,
    this.doctorLongitude,
    this.zoneId,
    this.zoneName,
    this.scheduledAt,
    this.durationMinutes = 0,
    this.status,
    this.assignedRepresentativeId,
    this.assignedRepresentativeName,
    this.representativeResponse,
    this.representativeResponseNote,
    this.representativeRespondedAt,
    this.reminderSentAt,
    this.patientName,
    this.notes,
    this.reviewStatus,
    this.redoCount = 0,
    this.reviewNote,
    this.reviewedAt,
    this.hasScans = false,
    this.createdAt,
  });

  final String id;
  final String? sessionNumber;
  final String? doctorId;
  final String? doctorName;
  final int? doctorNumber;
  final String? clinicId;
  final String? clinicName;

  final String? doctorAddress;
  final double? doctorLatitude;
  final double? doctorLongitude;

  final String? zoneId;
  final String? zoneName;

  final DateTime? scheduledAt;
  final int durationMinutes;

  final ScannerSessionStatus? status;

  final String? assignedRepresentativeId;
  final String? assignedRepresentativeName;

  /// How the current assignee answered. Computed by the server from the open
  /// attempt — it says who has it now, never who has had it.
  final RepresentativeResponse? representativeResponse;

  final String? representativeResponseNote;
  final DateTime? representativeRespondedAt;

  /// Stamped per attempt on the server, so a newly assigned representative is
  /// still reminded even though the previous one already was.
  final DateTime? reminderSentAt;

  final String? patientName;
  final String? notes;

  final ScannerReviewStatus? reviewStatus;

  /// How many times Control sent the scan back. Worth surfacing: a third redo
  /// is a conversation, not a queue item.
  final int redoCount;

  final String? reviewNote;
  final DateTime? reviewedAt;

  /// Whether the session has at least one scan file attached
  /// (`ClinicScannerSessionDto.scans`) — the real signal for "there is
  /// something here for Control to act on". `reviewStatus` was assumed to be
  /// that signal, but the field does not exist on the live DTO at all and
  /// always parses as null, which left the review action unreachable.
  final bool hasScans;

  final DateTime? createdAt;

  /// True when nobody is coming unless the dispatcher acts — either no one is
  /// assigned, or the person assigned declined.
  bool get needsAttention {
    if (!(status?.isOpen ?? false)) return false;
    if (assignedRepresentativeId == null) return true;
    return representativeResponse?.needsReassignment ?? false;
  }

  /// The doctor's location, when the server sent a usable pair. Null rather
  /// than (0,0) — the Gulf of Guinea is not where the clinic is.
  ({double latitude, double longitude})? get coordinates {
    final lat = doctorLatitude;
    final lng = doctorLongitude;
    if (lat == null || lng == null) return null;
    if (lat == 0 && lng == 0) return null;
    return (latitude: lat, longitude: lng);
  }

  String get title {
    final number = sessionNumber?.trim();
    if (number != null && number.isNotEmpty) return number;
    return 'جلسة بدون رقم';
  }

  factory ScannerSessionModel.fromJson(Map<String, dynamic> json) {
    return ScannerSessionModel(
      id: json['id'] as String? ?? '',
      sessionNumber: json['sessionNumber'] as String?,
      doctorId: json['doctorId'] as String?,
      doctorName: json['doctorName'] as String?,
      doctorNumber: json['doctorNumber'] as int?,
      clinicId: json['clinicId'] as String?,
      clinicName: json['clinicName'] as String?,
      doctorAddress: json['doctorAddress'] as String?,
      doctorLatitude: (json['doctorLatitude'] as num?)?.toDouble(),
      doctorLongitude: (json['doctorLongitude'] as num?)?.toDouble(),
      zoneId: json['zoneId'] as String?,
      zoneName: json['zoneName'] as String?,
      scheduledAt: DateTime.tryParse(json['scheduledAt'] as String? ?? ''),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      status: ScannerSessionStatus.fromValue(json['status'] as int?),
      assignedRepresentativeId: json['assignedRepresentativeId'] as String?,
      assignedRepresentativeName: json['assignedRepresentativeName'] as String?,
      representativeResponse: RepresentativeResponse.fromValue(
        json['representativeResponse'] as int?,
      ),
      representativeResponseNote: json['representativeResponseNote'] as String?,
      representativeRespondedAt: DateTime.tryParse(
        json['representativeRespondedAt'] as String? ?? '',
      ),
      reminderSentAt: DateTime.tryParse(
        json['reminderSentAt'] as String? ?? '',
      ),
      patientName: json['patientName'] as String?,
      notes: json['notes'] as String?,
      reviewStatus: ScannerReviewStatus.fromValue(json['reviewStatus'] as int?),
      redoCount: json['redoCount'] as int? ?? 0,
      reviewNote: json['reviewNote'] as String?,
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
      hasScans: (json['scans'] as List<dynamic>?)?.isNotEmpty ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
