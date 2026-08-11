import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/laboratories/data/models/create_laboratory_request_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/update_laboratory_request_model.dart';
import 'package:dio/dio.dart';

class LaboratoriesRepo {
  final ApiService _apiService;
  LaboratoriesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  /// The laboratory every request is currently scoped to.
  String? get activeLaboratoryId =>
      CacheHelper.getData(key: CacheKeys.laboratoryId) as String?;

  Future<Either<Failure, List<LaboratoryModel>>> getLaboratories() async {
    try {
      final laboratories = await _apiService.getLaboratories(token: _token);

      log('Fetched ${laboratories.length} laboratories');
      return right(laboratories);
    } on DioException catch (e) {
      log('DioException while fetching laboratories: ${e.message}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedLaboratoriesList,
        fromJson: LaboratoryModel.fromJson,
        onFailure: () => ServerFailure.FromDioExecption(e),
      );
    } catch (e) {
      log('General Exception while fetching laboratories: ${e.toString()}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedLaboratoriesList,
        fromJson: LaboratoryModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
    }
  }

  Future<Either<Failure, LaboratoryModel>> getOwnLaboratory() async {
    try {
      final laboratory = await _apiService.getOwnLaboratory(token: _token);

      log('Fetched own laboratory: ${laboratory.name}');
      return right(laboratory);
    } on DioException catch (e) {
      log('DioException while fetching own laboratory: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching own laboratory: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, LaboratoryModel>> getLaboratoryById(String id) async {
    try {
      final laboratory = await _apiService.getLaboratoryById(
        id: id,
        token: _token,
      );

      log('Fetched laboratory: ${laboratory.name}');
      return right(laboratory);
    } on DioException catch (e) {
      log('DioException while fetching laboratory: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching laboratory: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, LaboratoryModel>> createLaboratory(
    CreateLaboratoryRequestModel createLaboratoryRequestBody,
  ) async {
    try {
      final laboratory = await _apiService.createLaboratory(
        createLaboratoryRequestBody: createLaboratoryRequestBody,
        token: _token,
      );

      log('Created laboratory: ${laboratory.name}');
      return right(laboratory);
    } on DioException catch (e) {
      log('DioException while creating laboratory: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating laboratory: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, LaboratoryModel>> updateLaboratory({
    required String id,
    required UpdateLaboratoryRequestModel updateLaboratoryRequestBody,
  }) async {
    try {
      final laboratory = await _apiService.updateLaboratory(
        id: id,
        updateLaboratoryRequestBody: updateLaboratoryRequestBody,
        token: _token,
      );

      log('Updated laboratory: ${laboratory.name}');

      // Keep the cached name in sync when the active lab is the one edited.
      if (id == activeLaboratoryId) {
        await CacheHelper.saveData(
          key: CacheKeys.laboratoryName,
          value: laboratory.name ?? '',
        );
      }

      return right(laboratory);
    } on DioException catch (e) {
      log('DioException while updating laboratory: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating laboratory: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteLaboratory(String id) async {
    try {
      await _apiService.deleteLaboratory(id: id, token: _token);

      log('Deleted laboratory: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting laboratory: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting laboratory: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Switches the laboratory every subsequent request is scoped to (sent as
  /// the `X-Laboratory-Id` header by the [Api] interceptor).
  Future<void> selectLaboratory(LaboratoryModel laboratory) async {
    await CacheHelper.saveData(
      key: CacheKeys.laboratoryId,
      value: laboratory.id,
    );
    await CacheHelper.saveData(
      key: CacheKeys.laboratoryName,
      value: laboratory.name ?? '',
    );
    log('Active laboratory switched to: ${laboratory.name} (${laboratory.id})');
  }
}
