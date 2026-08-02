import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/countries/data/models/country_model.dart';
import 'package:dio/dio.dart';

class CountriesRepo {
  final ApiService _apiService;
  CountriesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<CountryModel>>> getCountries() async {
    try {
      final countries = await _apiService.getCountries(token: _token);

      log('Fetched ${countries.length} countries');
      return right(countries);
    } on DioException catch (e) {
      log('DioException while fetching countries: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching countries: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CountryModel>> createCountry(String name) async {
    try {
      final country = await _apiService.createCountry(name: name, token: _token);

      log('Created country: ${country.name}');
      return right(country);
    } on DioException catch (e) {
      log('DioException while creating country: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating country: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CountryModel>> updateCountry({
    required String id,
    required String name,
  }) async {
    try {
      final country = await _apiService.updateCountry(
        id: id,
        name: name,
        token: _token,
      );

      log('Updated country: ${country.name}');
      return right(country);
    } on DioException catch (e) {
      log('DioException while updating country: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating country: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteCountry(String id) async {
    try {
      await _apiService.deleteCountry(id: id, token: _token);

      log('Deleted country: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting country: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting country: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
