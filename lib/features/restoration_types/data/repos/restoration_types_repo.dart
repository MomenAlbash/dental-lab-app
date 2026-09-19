import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/lookup_api.dart';
import 'package:dental_lab_app/core/helper/network_helper/people_api.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/create_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/doctor_restoration_type_lookup_model.dart';
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
        onFailure: () => ServerFailure.fromDioException(e),
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

  /// The catalog priced for one doctor — what a case-creation form must
  /// quote from once a doctor is chosen. Falls back to the plain list on
  /// failure rather than the cache: a stale *doctor-priced* catalog is a
  /// pricing bug, not a convenience.
  Future<Either<Failure, List<DoctorRestorationTypeLookupModel>>>
  getRestorationTypesLookup({String? doctorId, int? intake}) async {
    try {
      final types = await _apiService.getRestorationTypesLookup(
        doctorId: doctorId,
        intake: intake,
        token: _token,
      );

      log('Fetched ${types.length} doctor-priced restoration types');
      return right(types);
    } on DioException catch (e) {
      log(
        'DioException while fetching doctor-priced restoration types: '
        '${e.message}',
      );
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while fetching doctor-priced restoration types: '
        '${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while updating restoration type: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Replaces the picture the **doctor-facing website** shows for this
  /// restoration type.
  ///
  /// Not the same image as the one a bench stage shows: this one is marketing,
  /// the stage's is a work reference, and letting one stand in for the other
  /// puts a polished catalogue shot where a technician needed a diagram.
  Future<Either<Failure, void>> uploadWebsiteImage({
    required String id,
    required String filePath,
  }) async {
    try {
      await _apiService.uploadRestorationTypeWebsiteImage(
        id: id,
        filePath: filePath,
        token: _token,
      );

      log('Uploaded website image for restoration type: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while uploading a website image: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while uploading a website image: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Clones this type — its prices, its durations and its whole route — into
  /// another laboratory.
  ///
  /// Answers with the **new** type, not the source: a lab that has just cloned
  /// a catalogue entry wants to open the copy and price it, and handing back
  /// the original is how an edit lands in the wrong laboratory.
  Future<Either<Failure, RestorationTypeModel>> copyToLaboratory({
    required String id,
    required String targetLaboratoryId,
  }) async {
    try {
      final copy = await _apiService.copyRestorationType(
        id: id,
        targetLaboratoryId: targetLaboratoryId,
        token: _token,
      );

      log('Copied restoration type $id to laboratory $targetLaboratoryId');
      return right(copy);
    } on DioException catch (e) {
      log('DioException while copying a restoration type: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while copying a restoration type: $e');
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
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting restoration type: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
