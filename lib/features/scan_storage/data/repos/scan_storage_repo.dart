import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/activity_api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/scan_storage/data/models/scan_storage_model.dart';
import 'package:dio/dio.dart';

/// The laboratory's scan storage: what it holds, what the sweep would take,
/// and what is waiting to go to the NAS.
///
/// Nothing is cached offline. Every figure here is about disk as it is *right
/// now*, and a stale copy would have someone deleting against numbers that
/// have already moved.
class ScanStorageRepo {
  ScanStorageRepo(this._apiService);

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

  Future<Either<Failure, ScanStorageModel>> getStorage() => _guard(
    'fetching scan storage',
    () => _apiService.getScanStorage(token: _token),
  );

  /// Runs the retention sweep now.
  ///
  /// Takes only what the lab's own rules allow — age, and whether the case is
  /// closed — so a lab that is over budget with nothing eligible gets a run
  /// that frees nothing. The result says so rather than reporting a bare
  /// count.
  Future<Either<Failure, ScanRetentionRunResultModel>> runSweep() => _guard(
    'running the scan retention sweep',
    () => _apiService.runScanRetention(token: _token),
  );

  /// Deletes one file's bytes. The row stays — a case filed two years ago
  /// still says what was scanned and why it went.
  Future<Either<Failure, ScanRetentionRunResultModel>> removeFile(String id) =>
      _guard(
        'removing a scan file',
        () => _apiService.removeScanFile(id: id, token: _token),
      );

  Future<Either<Failure, List<PendingNasArchiveModel>>> getPendingArchive() =>
      _guard(
        'fetching scans pending NAS archive',
        () => _apiService.getPendingNasArchive(token: _token),
      );

  /// Tells the server the copies are safely on the NAS, at which point it
  /// frees the bytes.
  ///
  /// **Only after the copy is verified.** The two-step flow exists so a failed
  /// copy costs nothing.
  Future<Either<Failure, ScanRetentionRunResultModel>> confirmArchive(
    ConfirmNasArchiveRequestModel body,
  ) => _guard(
    'confirming a NAS archive',
    () => _apiService.confirmNasArchive(body: body, token: _token),
  );
}
