import 'dart:developer';

import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_filters_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_request_models.dart';

/// The `scanner sessions` endpoints — split out of
/// [ApiService], reached through the same instance.
extension ScannerSessionsApi on ApiService {
  // ---------------------------------------------------------------------
  // Scanner sessions (MOBILE-SPEC §15.6)
  // ---------------------------------------------------------------------

  /// `GET /scanner-sessions` — the dispatcher's queue.
  Future<List<ScannerSessionModel>> getScannerSessions({
    ScannerSessionFiltersModel filters = ScannerSessionFiltersModel.empty,
    String? token,
  }) async {
    log('Fetching scanner sessions');

    final params = <MapEntry<String, String>>[
      const MapEntry('PageSize', '200'),
    ];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add(MapEntry(key, value));
      }
    }

    add('Search', filters.search);
    add('DoctorId', filters.doctorId);
    add('ZoneId', filters.zoneId);
    add('RepresentativeUserId', filters.representativeUserId);
    add('Status', filters.status?.value.toString());
    add('ReviewStatus', filters.reviewStatus?.value.toString());
    add(
      'RepresentativeResponse',
      filters.representativeResponse?.value.toString(),
    );
    add('DateFrom', filters.dateFrom?.toIso8601String());
    add('DateTo', filters.dateTo?.toIso8601String());

    final query = params
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final responseData = await Api().get(
      url: 'scanner-sessions?$query',
      token: token,
    );

    final items = responseData is Map<String, dynamic>
        ? (responseData['items'] as List<dynamic>? ?? const [])
        : (responseData as List<dynamic>? ?? const []);

    return items
        .whereType<Map<String, dynamic>>()
        .map(ScannerSessionModel.fromJson)
        .toList();
  }

  /// `GET /scanner-sessions/{id}`
  Future<ScannerSessionModel> getScannerSessionById({
    required String id,
    String? token,
  }) async {
    log('Fetching scanner session: $id');

    final data = await Api().get(url: 'scanner-sessions/$id', token: token);

    return ScannerSessionModel.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /scanner-sessions/{id}/eligible-representatives` — who could take
  /// this session, per the doctor's zone.
  Future<List<ZoneRepresentativeModel>> getEligibleRepresentatives({
    required String id,
    String? token,
  }) async {
    log('Fetching eligible representatives for session $id');

    final data = await Api().get(
      url: 'scanner-sessions/$id/eligible-representatives',
      token: token,
    );

    return decodeJsonList(data, ZoneRepresentativeModel.fromJson);
  }

  /// `PUT /scanner-sessions/{id}/representative` — assign, reassign, or clear.
  Future<ScannerSessionModel> assignRepresentative({
    required String id,
    required AssignRepresentativeRequestModel body,
    String? token,
  }) async {
    log('Assigning representative on session $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'scanner-sessions/$id/representative',
      body: body.toJson(),
      token: token,
    );

    return ScannerSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PUT /scanner-sessions/{id}/status`
  Future<ScannerSessionModel> setScannerSessionStatus({
    required String id,
    required SetScannerSessionStatusRequestModel body,
    String? token,
  }) async {
    log('Setting scanner session $id status: ${body.toJson()}');

    final response = await Api().put(
      url: 'scanner-sessions/$id/status',
      body: body.toJson(),
      token: token,
    );

    return ScannerSessionModel.fromJson(response.data as Map<String, dynamic>);
  }


}
