import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/lookup_api.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/digital_scan_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_enums.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_filters_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_message_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_request_models.dart';
import 'package:dio/dio.dart';

/// Reads and writes for the scanner-session queue.
///
/// Nothing is cached offline: this is a dispatch board, and a stale copy would
/// have someone driving to a session that was reassigned an hour ago.
class ScannerSessionsRepo {
  ScannerSessionsRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, T>> _guard<T>(
    String what,
    Future<T> Function() request,
  ) async {
    try {
      return right(await request());
    } on DioException catch (e) {
      log('DioException while $what: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while $what: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, List<ScannerSessionModel>>> getSessions({
    ScannerSessionFiltersModel filters = ScannerSessionFiltersModel.empty,
  }) => _guard(
    'fetching scanner sessions',
    () => _apiService.getScannerSessions(filters: filters, token: _token),
  );

  Future<Either<Failure, ScannerSessionModel>> getSessionById(String id) =>
      _guard(
        'fetching a scanner session',
        () => _apiService.getScannerSessionById(id: id, token: _token),
      );

  Future<Either<Failure, List<ZoneRepresentativeModel>>>
  getEligibleRepresentatives(String id) => _guard(
    'fetching eligible representatives',
    () => _apiService.getEligibleRepresentatives(id: id, token: _token),
  );

  /// Assigns [representativeUserId]. Null does not clear the assignment — it
  /// asks the server to pick one itself.
  Future<Either<Failure, ScannerSessionModel>> assignRepresentative({
    required String id,
    String? representativeUserId,
    String? note,
  }) => _guard(
    'assigning a representative',
    () => _apiService.assignRepresentative(
      id: id,
      body: AssignRepresentativeRequestModel(
        representativeUserId: representativeUserId,
        note: note,
      ),
      token: _token,
    ),
  );

  Future<Either<Failure, ScannerSessionModel>> setStatus({
    required String id,
    required ScannerSessionStatus status,
    String? note,
  }) => _guard(
    'setting a scanner session status',
    () => _apiService.setScannerSessionStatus(
      id: id,
      body: SetScannerSessionStatusRequestModel(status: status, note: note),
      token: _token,
    ),
  );

  // ---- The thread about one appointment ---------------------------------

  Future<Either<Failure, List<ScannerSessionMessageModel>>> getMessages(
    String sessionId,
  ) => _guard(
    'fetching scanner session messages',
    () => _apiService.getScannerSessionMessages(
      sessionId: sessionId,
      token: _token,
    ),
  );

  Future<Either<Failure, ScannerSessionMessageModel>> sendMessage({
    required String sessionId,
    required String message,
  }) => _guard(
    'sending a scanner session message',
    () => _apiService.sendScannerSessionMessage(
      sessionId: sessionId,
      message: message,
      token: _token,
    ),
  );

  /// Marks the other side's messages read and answers with the refreshed
  /// thread, so the receipts the user just cleared are the server's own view
  /// rather than a local guess at it.
  Future<Either<Failure, List<ScannerSessionMessageModel>>> markRead(
    String sessionId,
  ) => _guard(
    'marking scanner session messages read',
    () => _apiService.markScannerSessionMessagesRead(
      sessionId: sessionId,
      token: _token,
    ),
  );

  /// Uploads one scan taken during the session.
  ///
  /// [clientUploadKey] is an idempotency key: a retry after a dropped
  /// connection carries the same key and the server stores one file rather
  /// than two — which matters when a scan is tens of megabytes over a phone
  /// connection.
  Future<Either<Failure, DigitalScanModel>> uploadScan({
    required String sessionId,
    required String filePath,
    DigitalScanRole? role,
    String? notes,
    String? clientUploadKey,
  }) => _guard(
    'uploading a scanner session scan',
    () => _apiService.uploadScannerSessionScan(
      sessionId: sessionId,
      filePath: filePath,
      role: role,
      notes: notes,
      clientUploadKey: clientUploadKey,
      token: _token,
    ),
  );
}
