import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dio/dio.dart';

class CitiesRepo {
  final ApiService _apiService;
  CitiesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<CityModel>>> getCities() async {
    try {
      final cities = await _apiService.getCities(token: _token);

      log('Fetched ${cities.length} cities');
      return right(cities);
    } on DioException catch (e) {
      log('DioException while fetching cities: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching cities: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
