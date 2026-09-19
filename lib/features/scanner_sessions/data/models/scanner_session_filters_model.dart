import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_enums.dart';

/// The query behind the scanner sessions list.
class ScannerSessionFiltersModel {
  const ScannerSessionFiltersModel({
    this.search,
    this.doctorId,
    this.zoneId,
    this.representativeUserId,
    this.status,
    this.reviewStatus,
    this.representativeResponse,
    this.dateFrom,
    this.dateTo,
  });

  static const empty = ScannerSessionFiltersModel();

  /// The dispatcher's default view: everything still expected to happen.
  /// Completed and cancelled sessions are history and would bury the queue.
  static const openOnly = ScannerSessionFiltersModel();

  final String? search;
  final String? doctorId;
  final String? zoneId;
  final String? representativeUserId;
  final ScannerSessionStatus? status;
  final ScannerReviewStatus? reviewStatus;
  final RepresentativeResponse? representativeResponse;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  int get activeCount => [
    search,
    doctorId,
    zoneId,
    representativeUserId,
    status,
    reviewStatus,
    representativeResponse,
    dateFrom,
    dateTo,
  ].where((value) => value != null).length;

  bool get isEmpty => activeCount == 0;

  /// The flags exist because every field is nullable, so `copyWith` alone
  /// could never clear one.
  ScannerSessionFiltersModel copyWith({
    String? search,
    String? doctorId,
    String? zoneId,
    String? representativeUserId,
    ScannerSessionStatus? status,
    ScannerReviewStatus? reviewStatus,
    RepresentativeResponse? representativeResponse,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearSearch = false,
    bool clearDoctorId = false,
    bool clearZoneId = false,
    bool clearRepresentative = false,
    bool clearStatus = false,
    bool clearReviewStatus = false,
    bool clearResponse = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return ScannerSessionFiltersModel(
      search: clearSearch ? null : (search ?? this.search),
      doctorId: clearDoctorId ? null : (doctorId ?? this.doctorId),
      zoneId: clearZoneId ? null : (zoneId ?? this.zoneId),
      representativeUserId: clearRepresentative
          ? null
          : (representativeUserId ?? this.representativeUserId),
      status: clearStatus ? null : (status ?? this.status),
      reviewStatus: clearReviewStatus
          ? null
          : (reviewStatus ?? this.reviewStatus),
      representativeResponse: clearResponse
          ? null
          : (representativeResponse ?? this.representativeResponse),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ScannerSessionFiltersModel &&
      other.search == search &&
      other.doctorId == doctorId &&
      other.zoneId == zoneId &&
      other.representativeUserId == representativeUserId &&
      other.status == status &&
      other.reviewStatus == reviewStatus &&
      other.representativeResponse == representativeResponse &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo;

  @override
  int get hashCode => Object.hash(
    search,
    doctorId,
    zoneId,
    representativeUserId,
    status,
    reviewStatus,
    representativeResponse,
    dateFrom,
    dateTo,
  );
}
