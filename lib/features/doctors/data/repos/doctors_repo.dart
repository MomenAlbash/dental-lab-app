import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/doctors/data/models/approve_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/create_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_attachment_file_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/update_doctor_request_model.dart';
import 'package:dio/dio.dart';

class DoctorsRepo {
  final ApiService _apiService;
  DoctorsRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<DoctorModel>>> getDoctors() async {
    try {
      final doctors = await _apiService.getDoctors(token: _token);

      log('Fetched ${doctors.length} doctors');
      return right(doctors);
    } on DioException catch (e) {
      log('DioException while fetching doctors: ${e.message}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedDoctorsList,
        fromJson: DoctorModel.fromJson,
        onFailure: () => ServerFailure.FromDioExecption(e),
      );
    } catch (e) {
      log('General Exception while fetching doctors: ${e.toString()}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedDoctorsList,
        fromJson: DoctorModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
    }
  }

  Future<Either<Failure, DoctorModel>> getDoctorById(String id) async {
    try {
      final doctor = await _apiService.getDoctorById(id: id, token: _token);

      log('Fetched doctor: ${doctor.fullName}');
      return right(doctor);
    } on DioException catch (e) {
      log('DioException while fetching doctor: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching doctor: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, DoctorModel>> createDoctor(
    CreateDoctorRequestModel createDoctorRequestBody,
  ) async {
    try {
      final doctor = await _apiService.createDoctor(
        createDoctorRequestBody: createDoctorRequestBody,
        token: _token,
      );

      log('Created doctor: ${doctor.fullName}');
      return right(doctor);
    } on DioException catch (e) {
      log('DioException while creating doctor: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating doctor: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, DoctorModel>> updateDoctor({
    required String id,
    required UpdateDoctorRequestModel updateDoctorRequestBody,
  }) async {
    try {
      final doctor = await _apiService.updateDoctor(
        id: id,
        updateDoctorRequestBody: updateDoctorRequestBody,
        token: _token,
      );

      log('Updated doctor: ${doctor.fullName}');
      return right(doctor);
    } on DioException catch (e) {
      log('DioException while updating doctor: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating doctor: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, DoctorModel>> approveDoctor({
    required String id,
    required ApproveDoctorRequestModel approveDoctorRequestBody,
  }) async {
    try {
      final doctor = await _apiService.approveDoctor(
        id: id,
        approveDoctorRequestBody: approveDoctorRequestBody,
        token: _token,
      );

      log('Approved doctor: ${doctor.fullName}');
      return right(doctor);
    } on DioException catch (e) {
      log('DioException while approving doctor: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while approving doctor: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, DoctorModel>> rejectDoctor({
    required String id,
    required RejectDoctorRequestModel rejectDoctorRequestBody,
  }) async {
    try {
      final doctor = await _apiService.rejectDoctor(
        id: id,
        rejectDoctorRequestBody: rejectDoctorRequestBody,
        token: _token,
      );

      log('Rejected doctor: ${doctor.fullName}');
      return right(doctor);
    } on DioException catch (e) {
      log('DioException while rejecting doctor: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while rejecting doctor: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteDoctor(String id) async {
    try {
      await _apiService.deleteDoctor(id: id, token: _token);

      log('Deleted doctor: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting doctor: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting doctor: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, DoctorAttachmentFileModel>> uploadDoctorFile({
    required String id,
    required String filePath,
  }) async {
    try {
      final file = await _apiService.uploadDoctorFile(
        id: id,
        filePath: filePath,
        token: _token,
      );

      log('Uploaded file for doctor: $id');
      return right(file);
    } on DioException catch (e) {
      log('DioException while uploading doctor file: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while uploading doctor file: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteDoctorFile({
    required String id,
    required String fileId,
  }) async {
    try {
      await _apiService.deleteDoctorFile(id: id, fileId: fileId, token: _token);

      log('Deleted file $fileId for doctor: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting doctor file: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting doctor file: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
