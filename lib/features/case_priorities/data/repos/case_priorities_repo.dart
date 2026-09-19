import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
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
        onFailure: () => ServerFailure.fromDioException(e),
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
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
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while seeding case priorities: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  /// One doctor's allowances across every priority, for the current month.
  Future<Either<Failure, DoctorPriorityQuotaModel>> getDoctorPriorityQuota(
    String doctorId,
  ) async {
    try {
      final quota = await _apiService.getDoctorPriorityQuota(
        doctorId: doctorId,
        token: _token,
      );

      log('Fetched priority quota for doctor $doctorId');
      return right(quota);
    } on DioException catch (e) {
      log('DioException while fetching priority quota: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching priority quota: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Which of [doctorIds] carry their own allowance for [priorityId], and how
  /// many could not be read.
  ///
  /// There is no endpoint that answers "who is on this priority", only one
  /// that answers "what are this doctor's allowances", so the question is
  /// asked once per doctor and the answers are folded together here rather
  /// than in the screen. Run in small batches: a lab with a hundred doctors
  /// firing a hundred simultaneous requests is how a server starts refusing
  /// them.
  ///
  /// A doctor whose quota could not be fetched is reported in `unreadable`
  /// instead of being quietly counted as unassigned — the caller can say so.
  Future<({Set<String> assignedIds, int unreadable})>
  getDoctorsWithPriorityOverride({
    required String priorityId,
    required List<String> doctorIds,
  }) async {
    const batchSize = 6;
    final assigned = <String>{};
    var unreadable = 0;

    for (var start = 0; start < doctorIds.length; start += batchSize) {
      final batch = doctorIds.skip(start).take(batchSize);

      final results = await Future.wait(batch.map(getDoctorPriorityQuota));

      for (final result in results) {
        result.fold((_) => unreadable++, (quota) {
          if (quota.lineFor(priorityId)?.isOverridden ?? false) {
            assigned.add(quota.doctorId);
          }
        });
      }
    }

    log('Priority $priorityId is set for ${assigned.length} doctors');
    return (assignedIds: assigned, unreadable: unreadable);
  }

  /// Sets one doctor's allowance for one priority.
  Future<Either<Failure, DoctorPriorityQuotaModel>> setDoctorPriorityAllowance({
    required String doctorId,
    required SetPriorityAllowanceRequestModel body,
  }) async {
    try {
      final quota = await _apiService.setDoctorPriorityAllowance(
        doctorId: doctorId,
        body: body,
        token: _token,
      );

      log('Set priority allowance for doctor $doctorId');
      return right(quota);
    } on DioException catch (e) {
      log('DioException while setting priority allowance: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while setting priority allowance: $e');
      return left(ServerFailure.fromException(e));
    }
  }
}

/// The laboratory-wide view of who gets what, and the two ways to change it.
extension PriorityAllowancesRepo on CasePrioritiesRepo {
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

  /// Every doctor's standing for the current period, in one query.
  Future<Either<Failure, PriorityOverviewModel>> getOverview({
    String? search,
  }) => _guard(
    'fetching the priority overview',
    () => _apiService.getPriorityOverview(search: search, token: _token),
  );

  /// Only the doctors with an override at this level — the absence of a row
  /// is the meaningful state.
  Future<Either<Failure, List<PriorityAllowanceModel>>> getAllowances(
    String priorityId,
  ) => _guard(
    'fetching priority allowances',
    () =>
        _apiService.getPriorityAllowances(priorityId: priorityId, token: _token),
  );

  /// Writes one level's terms onto a set of doctors. Doctors not listed keep
  /// what they had — this is not a replace.
  Future<Either<Failure, List<PriorityAllowanceModel>>> setAllowances({
    required String priorityId,
    required BulkSetPriorityAllowanceRequestModel body,
  }) => _guard(
    'setting priority allowances',
    () => _apiService.setPriorityAllowances(
      priorityId: priorityId,
      body: body,
      token: _token,
    ),
  );

  /// Bumps one doctor's allowance at one level.
  Future<Either<Failure, DoctorPriorityQuotaModel>> increaseAllowance({
    required String doctorId,
    required String priorityId,
    required IncreasePriorityAllowanceRequestModel body,
  }) => _guard(
    'increasing a priority allowance',
    () => _apiService.increaseDoctorPriorityAllowance(
      doctorId: doctorId,
      priorityId: priorityId,
      body: body,
      token: _token,
    ),
  );
}
