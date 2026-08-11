import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/save_case_priority_request_model.dart';
import 'package:dio/dio.dart';

class CasePrioritiesRepo {
  final ApiService _apiService;
  CasePrioritiesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  /// Each scope falls back to its own cache — serving the active-only list to
  /// an `includeInactive` caller would silently drop the retired priorities
  /// that its cases are still filed under.
  Either<Failure, List<CasePriorityModel>> _fallback({
    required bool includeInactive,
    required Failure Function() onFailure,
  }) {
    return fallbackToCache(
      cacheKey: includeInactive
          ? CacheKeys.cachedAllCasePrioritiesList
          : CacheKeys.cachedCasePrioritiesList,
      fromJson: CasePriorityModel.fromJson,
      onFailure: onFailure,
    );
  }

  Future<Either<Failure, List<CasePriorityModel>>> getCasePriorities({
    bool includeInactive = false,
  }) async {
    try {
      final priorities = await _apiService.getCasePriorities(
        includeInactive: includeInactive,
        token: _token,
      );

      log('Fetched ${priorities.length} case priorities');
      return right(priorities);
    } on DioException catch (e) {
      log('DioException while fetching case priorities: ${e.message}');
      return _fallback(
        includeInactive: includeInactive,
        onFailure: () => ServerFailure.FromDioExecption(e),
      );
    } catch (e) {
      log('General Exception while fetching case priorities: ${e.toString()}');
      return _fallback(
        includeInactive: includeInactive,
        onFailure: () => ServerFailure.fromException(e),
      );
    }
  }

  Future<Either<Failure, CasePriorityModel>> createCasePriority(
    SaveCasePriorityRequestModel saveRequestBody,
  ) async {
    try {
      final priority = await _apiService.createCasePriority(
        saveRequestBody: saveRequestBody,
        token: _token,
      );

      log('Created case priority: ${priority.name}');
      return right(priority);
    } on DioException catch (e) {
      log('DioException while creating case priority: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating case priority: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CasePriorityModel>> updateCasePriority({
    required String id,
    required SaveCasePriorityRequestModel saveRequestBody,
  }) async {
    try {
      final priority = await _apiService.updateCasePriority(
        id: id,
        saveRequestBody: saveRequestBody,
        token: _token,
      );

      log('Updated case priority: ${priority.name}');
      return right(priority);
    } on DioException catch (e) {
      log('DioException while updating case priority: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating case priority: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteCasePriority(String id) async {
    try {
      await _apiService.deleteCasePriority(id: id, token: _token);

      log('Deleted case priority: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting case priority: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting case priority: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, List<CasePriorityModel>>>
  seedDefaultCasePriorities() async {
    try {
      final priorities = await _apiService.seedDefaultCasePriorities(
        token: _token,
      );

      log('Seeded ${priorities.length} default case priorities');
      return right(priorities);
    } on DioException catch (e) {
      log('DioException while seeding case priorities: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while seeding case priorities: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
