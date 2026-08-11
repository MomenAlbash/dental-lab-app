import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dio/dio.dart';

class CitiesRepo {
  final ApiService _apiService;
  CitiesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<CityModel>>> getCities({
    String? countryId,
  }) async {
    try {
      final cities = await _apiService.getCities(
        countryId: countryId,
        token: _token,
      );

      log('Fetched ${cities.length} cities');
      return right(cities);
    } on DioException catch (e) {
      log('DioException while fetching cities: ${e.message}');
      if (countryId != null) return left(ServerFailure.FromDioExecption(e));
      return fallbackToCache(
        cacheKey: CacheKeys.cachedCitiesList,
        fromJson: CityModel.fromJson,
        onFailure: () => ServerFailure.FromDioExecption(e),
      );
    } catch (e) {
      log('General Exception while fetching cities: ${e.toString()}');
      if (countryId != null) return left(ServerFailure.fromException(e));
      return fallbackToCache(
        cacheKey: CacheKeys.cachedCitiesList,
        fromJson: CityModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
    }
  }

  Future<Either<Failure, CityModel>> createCity({
    required String name,
    String? countryId,
  }) async {
    try {
      final city = await _apiService.createCity(
        name: name,
        countryId: countryId,
        token: _token,
      );

      log('Created city: ${city.name}');
      return right(city);
    } on DioException catch (e) {
      log('DioException while creating city: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating city: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CityModel>> updateCity({
    required String id,
    required String name,
    String? countryId,
  }) async {
    try {
      final city = await _apiService.updateCity(
        id: id,
        name: name,
        countryId: countryId,
        token: _token,
      );

      log('Updated city: ${city.name}');
      return right(city);
    } on DioException catch (e) {
      log('DioException while updating city: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating city: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteCity(String id) async {
    try {
      await _apiService.deleteCity(id: id, token: _token);

      log('Deleted city: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting city: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting city: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
