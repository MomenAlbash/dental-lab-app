import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/route_problem_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/save_case_stage_request_models.dart';
import 'package:dio/dio.dart';

/// Reads and edits the laboratory's case-workflow catalogue.
///
/// The read falls back to a cached copy offline — a stale stage list still
/// names the stages correctly.
class CaseStagesRepo {
  final ApiService _apiService;
  CaseStagesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<CaseStageModel>>> getCaseStages() async {
    try {
      final stages = await _apiService.getCaseStages(token: _token);

      log('Fetched ${stages.length} case stages');
      return right(stages);
    } on DioException catch (e) {
      log('DioException while fetching case stages: ${e.message}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedCaseStagesList,
        fromJson: CaseStageModel.fromJson,
        onFailure: () => ServerFailure.fromDioException(e),
      );
    } catch (e) {
      log('General Exception while fetching case stages: ${e.toString()}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedCaseStagesList,
        fromJson: CaseStageModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
    }
  }

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

  Future<Either<Failure, CaseStageModel>> createStage(
    SaveCaseStageRequestModel body,
  ) => _guard(
    'creating a case stage',
    () => _apiService.createCaseStage(body: body, token: _token),
  );

  Future<Either<Failure, CaseStageModel>> updateStage({
    required String id,
    required SaveCaseStageRequestModel body,
  }) => _guard(
    'updating a case stage',
    () => _apiService.updateCaseStage(id: id, body: body, token: _token),
  );

  Future<Either<Failure, void>> deleteStage(String id) => _guard(
    'deleting a case stage',
    () => _apiService.deleteCaseStage(id: id, token: _token),
  );

  /// Writes a new running order onto [stages], lowest first.
  ///
  /// Ordering *is* the flow now — the API carries no transition table, and a
  /// case runs the stages of its intake in `order`. There is no bulk endpoint,
  /// so this is one PUT per stage whose position actually changed; the rest
  /// are left alone rather than rewritten with their own value.
  ///
  /// Every field of the stage is resent, because `PUT /case-statuses/{id}`
  /// replaces the record — sending only the order would blank the rest.
  Future<Either<Failure, void>> saveOrder(List<CaseStageModel> stages) async {
    for (var index = 0; index < stages.length; index++) {
      final stage = stages[index];
      if (stage.order == index) continue;

      final result = await updateStage(
        id: stage.id,
        body: SaveCaseStageRequestModel(
          name: stage.name ?? '',
          nameAr: stage.nameAr,
          order: index,
          // Carried through: the barrier is part of the stage, and a reorder
          // that dropped it would quietly let packing start mid-production.
          timing: stage.timing,
          // Carried through for the same reason as the barrier: a reorder
          // that dropped them would erase the lab.s rework path and its
          // branch, silently.
          sendBackToStageId: stage.sendBackToStageId,
          nextStageId: stage.nextStageId,
          isExternal: stage.isExternal,
          isOptional: stage.isOptional,
          requiresReason: stage.requiresReason,
          appliesTo: stage.appliesTo,
          isActive: stage.isActive,
          badgeVariant: stage.badgeVariant,
          departmentIds: stage.departmentIds,
          userIds: stage.userIds,
          excludedUserIds: stage.excludedUserIds,
        ),
      );

      // Stops at the first failure rather than pressing on: a half-applied
      // order is a workflow whose stages run in an order nobody chose.
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) return left(failure);
    }

    log('Saved a new order for ${stages.length} case stages');
    return right(null);
  }

  /// Checks the drawn workflow for the defects that make a case silently
  /// stop — an unreachable stage, a rework edge that does not point
  /// backwards, and the like. Server-side, not a local re-derivation: the
  /// rules live where the flow is actually walked.
  Future<Either<Failure, List<RouteProblemModel>>> validateWorkflow() => _guard(
    'validating the case workflow',
    () => _apiService.validateCaseStatuses(token: _token),
  );

  /// Seeds a starter workflow. Idempotent on the server, so a second call on
  /// an already-drawn workflow changes nothing.
  Future<Either<Failure, void>> seedDefaults() => _guard(
    'seeding default case stages',
    () => _apiService.seedDefaultCaseStages(token: _token),
  );

  /// The stages a case may skip, narrowed to one intake where given.
  Future<Either<Failure, List<CaseStageModel>>> getOptionalStages({
    int? intake,
  }) => _guard(
    'fetching optional case stages',
    () => _apiService.getOptionalCaseStages(intake: intake, token: _token),
  );

  /// Who staffs one stage.
  ///
  /// Its own call rather than part of the full save: staffing changes far more
  /// often than the workflow's shape, and routing it through the whole-status
  /// body would make every roster edit a chance to clobber the rules.
  Future<Either<Failure, CaseStageModel>> setAssignments({
    required String id,
    List<String>? departmentIds,
    List<String>? userIds,
  }) => _guard(
    'setting case stage assignments',
    () => _apiService.setCaseStageAssignments(
      id: id,
      departmentIds: departmentIds,
      userIds: userIds,
      token: _token,
    ),
  );
}
