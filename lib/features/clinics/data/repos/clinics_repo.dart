import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/create_clinic_request_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/update_clinic_request_model.dart';
import 'package:dio/dio.dart';

class ClinicsRepo {
  final ApiService _apiService;
  ClinicsRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<ClinicModel>>> getClinics() async {
    try {
      final clinics = await _apiService.getClinics(token: _token);

      log('Fetched ${clinics.length} clinics');
      return right(clinics);
    } on DioException catch (e) {
      log('DioException while fetching clinics: ${e.message}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedClinicsList,
        fromJson: ClinicModel.fromJson,
        onFailure: () => ServerFailure.FromDioExecption(e),
      );
    } catch (e) {
      log('General Exception while fetching clinics: ${e.toString()}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedClinicsList,
        fromJson: ClinicModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
    }
  }

  Future<Either<Failure, ClinicModel>> getClinicById(String id) async {
    try {
      final clinic = await _apiService.getClinicById(id: id, token: _token);

      log('Fetched clinic: ${clinic.name}');
      return right(clinic);
    } on DioException catch (e) {
      log('DioException while fetching clinic: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching clinic: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, ClinicModel>> createClinic(
    CreateClinicRequestModel createClinicRequestBody,
  ) async {
    try {
      final clinic = await _apiService.createClinic(
        createClinicRequestBody: createClinicRequestBody,
        token: _token,
      );

      log('Created clinic: ${clinic.name}');
      return right(clinic);
    } on DioException catch (e) {
      log('DioException while creating clinic: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating clinic: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, ClinicModel>> updateClinic({
    required String id,
    required UpdateClinicRequestModel updateClinicRequestBody,
  }) async {
    try {
      final clinic = await _apiService.updateClinic(
        id: id,
        updateClinicRequestBody: updateClinicRequestBody,
        token: _token,
      );

      log('Updated clinic: ${clinic.name}');
      return right(clinic);
    } on DioException catch (e) {
      log('DioException while updating clinic: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating clinic: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteClinic(String id) async {
    try {
      await _apiService.deleteClinic(id: id, token: _token);

      log('Deleted clinic: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting clinic: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting clinic: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
