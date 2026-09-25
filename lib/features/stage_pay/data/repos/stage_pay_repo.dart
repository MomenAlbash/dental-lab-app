import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/stage_pay_api.dart';
import 'package:dental_lab_app/features/stage_pay/data/models/stage_pay_models.dart';
import 'package:dio/dio.dart';

/// Stage-based pay: the price of each production stage, and what each
/// employee earned by finishing them.
class StagePayRepo {
  StagePayRepo(this._apiService);

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

  Future<Either<Failure, List<StagePayRestorationTypeModel>>> getRates() =>
      _guard(
        'fetching stage pay rates',
        () => _apiService.getStagePayRates(token: _token),
      );

  Future<Either<Failure, void>> saveRates(SaveStagePayRatesRequestModel body) =>
      _guard(
        'saving stage pay rates',
        () => _apiService.saveStagePayRates(body: body, token: _token),
      );

  Future<Either<Failure, List<EmployeeStageEarningModel>>> getEarnings({
    required DateTime from,
    required DateTime to,
    String? employeeId,
  }) => _guard(
    'fetching stage earnings',
    () => _apiService.getStageEarnings(
      from: from,
      to: to,
      employeeId: employeeId,
      token: _token,
    ),
  );

  Future<Either<Failure, LossPreviewModel>> getLossPreview({
    required String caseId,
    required String restorationId,
    required String targetStageId,
  }) => _guard(
    'fetching a loss preview',
    () => _apiService.getLossPreview(
      caseId: caseId,
      restorationId: restorationId,
      targetStageId: targetStageId,
      token: _token,
    ),
  );
}
