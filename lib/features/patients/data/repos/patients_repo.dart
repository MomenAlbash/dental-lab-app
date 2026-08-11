import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/patients/data/models/create_patient_request_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_filters_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dio/dio.dart';

class PatientsRepo {
  final ApiService _apiService;
  PatientsRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<PatientModel>>> getPatients({
    String? search,
    PatientFiltersModel filters = PatientFiltersModel.empty,
  }) async {
    try {
      final patients = await _apiService.getPatients(
        search: search,
        doctorIds: filters.doctorId == null ? null : [filters.doctorId!],
        clinicIds: filters.clinicId == null ? null : [filters.clinicId!],
        gender: filters.gender?.apiValue,
        token: _token,
      );

      log('Fetched ${patients.length} patients');
      return right(patients);
    } on DioException catch (e) {
      log('DioException while fetching patients: ${e.message}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedPatientsList,
        fromJson: PatientModel.fromJson,
        onFailure: () => ServerFailure.FromDioExecption(e),
      );
    } catch (e) {
      log('General Exception while fetching patients: ${e.toString()}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedPatientsList,
        fromJson: PatientModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
    }
  }

  Future<Either<Failure, PatientModel>> getPatientById(String id) async {
    try {
      final patient = await _apiService.getPatientById(id: id, token: _token);

      log('Fetched patient: ${patient.fullName}');
      return right(patient);
    } on DioException catch (e) {
      log('DioException while fetching patient: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching patient: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, PatientModel>> createPatient(
    CreatePatientRequestModel createPatientRequestBody,
  ) async {
    try {
      final patient = await _apiService.createPatient(
        createPatientRequestBody: createPatientRequestBody,
        token: _token,
      );

      log('Created patient: ${patient.fullName}');
      return right(patient);
    } on DioException catch (e) {
      log('DioException while creating patient: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating patient: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
