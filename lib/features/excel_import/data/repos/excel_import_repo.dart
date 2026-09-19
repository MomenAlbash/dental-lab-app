import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/questions_api.dart';
import 'package:dental_lab_app/features/excel_import/data/models/import_session_model.dart';
import 'package:dio/dio.dart';

/// Bulk import from a spreadsheet.
///
/// Nothing is cached: an import session is a live progress figure, and a
/// stale copy would tell somebody a run had finished when it had not.
class ExcelImportRepo {
  ExcelImportRepo(this._apiService);

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

  /// The blank spreadsheet to fill in, as bytes.
  Future<Either<Failure, List<int>>> downloadTemplate(
    ImportEntityType entityType,
  ) => _guard(
    'downloading an import template',
    () => _apiService.downloadImportTemplate(
      entityType: entityType,
      token: _token,
    ),
  );

  /// Starts a run.
  ///
  /// Answers with the session, not the result: the server works through the
  /// file in the background, so the caller polls [getSession] afterwards.
  Future<Either<Failure, ImportSessionModel>> upload({
    required ImportEntityType entityType,
    required String filePath,
  }) => _guard(
    'uploading an import file',
    () => _apiService.uploadImportFile(
      entityType: entityType,
      filePath: filePath,
      token: _token,
    ),
  );

  Future<Either<Failure, ImportSessionModel>> getSession(String sessionId) =>
      _guard(
        'fetching an import session',
        () => _apiService.getImportSession(
          sessionId: sessionId,
          token: _token,
        ),
      );

  Future<Either<Failure, List<ImportSessionModel>>> getSessions() => _guard(
    'fetching current import sessions',
    () => _apiService.getImportSessions(token: _token),
  );
}
