import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/activity_api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/employee_activity/data/models/employee_activity_model.dart';
import 'package:dio/dio.dart';

/// The team-activity report.
///
/// Reads history — it does not add a new clock. The per-stage work timers are
/// deliberately off, so these answer "how much moved through whom", never "how
/// long did it take".
///
/// Not cached offline: this is a report people read to make a decision today,
/// and a stale copy is worse than a spinner.
class EmployeeActivityRepo {
  EmployeeActivityRepo(this._apiService);

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

  Future<Either<Failure, EmployeeActivitySummaryModel>> getSummary(
    EmployeeActivityFiltersModel filters,
  ) => _guard(
    'fetching the team activity summary',
    () => _apiService.getActivitySummary(filters: filters, token: _token),
  );

  Future<Either<Failure, List<EmployeeActivityDailyModel>>> getDaily(
    EmployeeActivityFiltersModel filters,
  ) => _guard(
    'fetching daily employee activity',
    () => _apiService.getActivityDaily(filters: filters, token: _token),
  );

  Future<Either<Failure, ActivityTimelineModel>> getTimeline(
    EmployeeActivityFiltersModel filters,
  ) => _guard(
    'fetching the activity timeline',
    () => _apiService.getActivityTimeline(filters: filters, token: _token),
  );

  /// The same report as a spreadsheet — the bytes, for the caller to save or
  /// share.
  Future<Either<Failure, List<int>>> export(
    EmployeeActivityFiltersModel filters,
  ) => _guard(
    'exporting the team activity report',
    () => _apiService.exportActivity(filters: filters, token: _token),
  );
}
