import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/lookup_api.dart';
import 'package:dental_lab_app/core/helper/network_helper/people_api.dart';
import 'package:dental_lab_app/features/doctors/data/models/approve_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/create_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_attachment_file_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_lookup_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_price_tier_spell_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/exclusion_reason_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/update_doctor_request_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
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
        onFailure: () => ServerFailure.fromDioException(e),
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting doctor: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, List<ZoneRepresentativeModel>>>
  getExcludedRepresentatives(String doctorId) async {
    try {
      final reps = await _apiService.getExcludedRepresentatives(
        doctorId: doctorId,
        token: _token,
      );

      log(
        'Fetched ${reps.length} excluded representatives for doctor $doctorId',
      );
      return right(reps);
    } on DioException catch (e) {
      log('DioException while fetching excluded representatives: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while fetching excluded representatives: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> excludeRepresentative({
    required String doctorId,
    required String userId,
    String? reason,
  }) async {
    try {
      await _apiService.excludeRepresentative(
        doctorId: doctorId,
        userId: userId,
        body: ExclusionReasonRequestModel(reason: reason),
        token: _token,
      );

      log('Excluded representative $userId for doctor $doctorId');
      return right(null);
    } on DioException catch (e) {
      log('DioException while excluding representative: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while excluding representative: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> removeExcludedRepresentative({
    required String doctorId,
    required String userId,
  }) async {
    try {
      await _apiService.removeExcludedRepresentative(
        doctorId: doctorId,
        userId: userId,
        token: _token,
      );

      log('Removed exclusion of $userId for doctor $doctorId');
      return right(null);
    } on DioException catch (e) {
      log('DioException while removing exclusion: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while removing exclusion: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, List<DoctorPriceTierSpellModel>>> getPriceTierHistory(
    String doctorId,
  ) async {
    try {
      final history = await _apiService.getDoctorPriceTierHistory(
        doctorId: doctorId,
        token: _token,
      );

      log('Fetched ${history.length} price-tier spells for doctor $doctorId');
      return right(history);
    } on DioException catch (e) {
      log('DioException while fetching price-tier history: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while fetching price-tier history: ${e.toString()}',
      );
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting doctor file: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  // ---- Pickers ----------------------------------------------------------

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

  /// Doctors as a picker sees them — a name, a phone and the clinic that tells
  /// namesakes apart.
  ///
  /// Deliberately not [getDoctors]: that carries balances, zones, case counts
  /// and a scope, and paging all of it down to fill a dropdown is what makes a
  /// case form slow to open.
  Future<Either<Failure, List<DoctorLookupModel>>> getLookup({
    String? search,
  }) => _guard(
    'fetching the doctor lookup',
    () => _apiService.getDoctorsLookup(search: search, token: _token),
  );

  /// The number the next doctor will get.
  ///
  /// Read from the server rather than counted from the list: the lab numbers
  /// doctors in one sequence, and two people on the form at once must not be
  /// shown the same number.
  Future<Either<Failure, int>> getNextNumber() => _guard(
    'fetching the next doctor number',
    () => _apiService.getNextDoctorNumber(token: _token),
  );
}

/// The doctor's photo.
extension DoctorImageRepo on DoctorsRepo {
  /// Which zone this doctor sits in — resolved by the server from their area
  /// or from a manual pin, and the answer to "who may take their sessions".
  ///
  /// Null is an ordinary answer: a doctor whose area has not been mapped yet
  /// belongs to no zone.
  Future<Either<Failure, ZoneModel?>> getZone(String doctorId) async {
    try {
      final zone = await _apiService.getDoctorZone(
        doctorId: doctorId,
        token: _token,
      );
      return right(zone);
    } on DioException catch (e) {
      log('DioException while fetching a doctor zone: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching a doctor zone: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, DoctorModel>> uploadImage({
    required String id,
    required String filePath,
  }) async {
    try {
      final doctor = await _apiService.uploadDoctorImage(
        id: id,
        filePath: filePath,
        token: _token,
      );

      log('Uploaded image for doctor: $id');
      return right(doctor);
    } on DioException catch (e) {
      log('DioException while uploading a doctor image: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while uploading a doctor image: $e');
      return left(ServerFailure.fromException(e));
    }
  }

}
