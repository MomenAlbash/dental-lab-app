import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/store_reports/data/models/monthly_feasibility_model.dart';
import 'package:dio/dio.dart';

class StoreReportsRepo {
  StoreReportsRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, MonthlyFeasibilityModel>> getStoreFeasibility({
    int? months,
    List<String>? laboratoryIds,
  }) async {
    try {
      final feasibility = await _apiService.getStoreFeasibility(
        months: months,
        laboratoryIds: laboratoryIds,
        token: _token,
      );

      log(
        'Fetched store feasibility for ${feasibility.currencies.length} currencies',
      );
      return right(feasibility);
    } on DioException catch (e) {
      log('DioException while fetching store feasibility: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while fetching store feasibility: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }
}
