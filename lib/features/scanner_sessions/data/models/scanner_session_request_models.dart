import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_enums.dart';

/// Body of `PUT /scanner-sessions/{id}/representative`
/// (`ClinicAssignRepresentativeRequest`).
///
/// A null [representativeUserId] does **not** clear the assignment — it asks
/// the server to pick one itself (zone first, then whoever is free and not
/// vetoed). There is no way to leave a session with nobody assigned through
/// this endpoint.
class AssignRepresentativeRequestModel {
  const AssignRepresentativeRequestModel({
    this.representativeUserId,
    this.note,
  });

  final String? representativeUserId;
  final String? note;

  Map<String, dynamic> toJson() => {
    'representativeUserId': representativeUserId,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}

/// Body of `PUT /scanner-sessions/{id}/status`
/// (`ClinicSetScannerSessionStatusRequest`).
class SetScannerSessionStatusRequestModel {
  const SetScannerSessionStatusRequestModel({required this.status, this.note});

  final ScannerSessionStatus status;
  final String? note;

  Map<String, dynamic> toJson() => {
    'status': status.value,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}
