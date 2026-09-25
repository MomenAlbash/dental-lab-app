import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/laboratory_scope.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/lookup_api.dart';
import 'package:dental_lab_app/features/laboratories/data/models/create_laboratory_request_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/footer_contact_model.dart';
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
        onFailure: () => ServerFailure.fromDioException(e),
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting laboratory: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  // ---- Printed identity -------------------------------------------------

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

  /// Replaces the contact lines printed at the foot of reports and invoices.
  ///
  /// The whole list is sent every time: a row left out is deleted, which is
  /// what makes reordering and removing possible in one save.
  Future<Either<Failure, void>> setFooterContacts({
    required String id,
    required List<SaveFooterContactModel> contacts,
  }) => _guard(
    'setting laboratory footer contacts',
    () => _apiService.setLaboratoryFooterContacts(
      id: id,
      contacts: contacts,
      token: _token,
    ),
  );

  Future<Either<Failure, void>> uploadLogo({
    required String id,
    required String filePath,
  }) => _guard(
    'uploading a laboratory logo',
    () => _apiService.uploadLaboratoryLogo(
      id: id,
      filePath: filePath,
      token: _token,
    ),
  );

  /// Back to no logo at all — not the same as uploading a blank one, since
  /// reports lay out differently with no logo than with an empty box where one
  /// should be.
  Future<Either<Failure, void>> deleteLogo(String id) => _guard(
    'deleting a laboratory logo',
    () => _apiService.deleteLaboratoryLogo(id: id, token: _token),
  );

  /// The laboratories the session is currently scoped to.
  List<String> get selectedLaboratoryIds => LaboratoryScope.ids;

  /// Switches the laboratories every subsequent request is scoped to — one,
  /// or several viewed together (see [LaboratoryScope]).
  Future<void> selectLaboratories(List<LaboratoryModel> laboratories) async {
    await LaboratoryScope.save([
      for (final laboratory in laboratories)
        (id: laboratory.id, name: laboratory.name ?? ''),
    ]);
    log('Scope switched to ${laboratories.length} laboratories');
  }
}
