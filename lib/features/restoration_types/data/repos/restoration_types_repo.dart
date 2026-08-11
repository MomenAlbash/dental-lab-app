import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/create_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/update_restoration_type_request_model.dart';
import 'package:dio/dio.dart';

class RestorationTypesRepo {
  final ApiService _apiService;
  RestorationTypesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<RestorationTypeModel>>>
  getRestorationTypes() async {
    try {
      final types = await _apiService.getRestorationTypes(token: _token);

      log('Fetched ${types.length} restoration types');
      return right(types);
    } on DioException catch (e) {
      log('DioException while fetching restoration types: ${e.message}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedRestorationTypesList,
        fromJson: RestorationTypeModel.fromJson,
        onFailure: () => ServerFailure.FromDioExecption(e),
      );
    } catch (e) {
      log(
        'General Exception while fetching restoration types: ${e.toString()}',
      );
      return fallbackToCache(
        cacheKey: CacheKeys.cachedRestorationTypesList,
        fromJson: RestorationTypeModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
    }
  }

  Future<Either<Failure, RestorationTypeModel>> createRestorationType(
    CreateRestorationTypeRequestModel createRequestBody,
  ) async {
    try {
      final type = await _apiService.createRestorationType(
        createRequestBody: createRequestBody,
        token: _token,
      );

      log('Created restoration type: ${type.name}');
      return right(type);
    } on DioException catch (e) {
      log('DioException while creating restoration type: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating restoration type: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, RestorationTypeModel>> updateRestorationType({
    required String id,
    required UpdateRestorationTypeRequestModel updateRequestBody,
  }) async {
    try {
      final type = await _apiService.updateRestorationType(
        id: id,
        updateRequestBody: updateRequestBody,
        token: _token,
      );

      log('Updated restoration type: ${type.name}');
      return right(type);
    } on DioException catch (e) {
      log('DioException while updating restoration type: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating restoration type: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteRestorationType(String id) async {
    try {
      await _apiService.deleteRestorationType(id: id, token: _token);

      log('Deleted restoration type: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting restoration type: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting restoration type: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
