import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/people_api.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/route_definition_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/save_workflow_stage_request_models.dart';
import 'package:dio/dio.dart';

/// Reads and edits the stages of a restoration type's route.
///
/// Not cached offline: editing a route against a stale picture would delete or
/// duplicate stages another user added, and the route is what production runs
/// on.
class WorkflowStagesRepo {
  WorkflowStagesRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

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

  /// The stages of one restoration type's route. Omitting
  /// [restorationTypeId] returns the whole laboratory's catalogue.
  Future<Either<Failure, List<CaseWorkflowStageModel>>> getStages({
    String? restorationTypeId,
  }) => _guard(
    'fetching workflow stages',
    () => _apiService.getWorkflowStages(
      restorationTypeId: restorationTypeId,
      token: _token,
    ),
  );

  Future<Either<Failure, CaseWorkflowStageModel>> createStage(
    CreateWorkflowStageRequestModel body,
  ) => _guard(
    'creating a workflow stage',
    () => _apiService.createWorkflowStage(body: body, token: _token),
  );

  Future<Either<Failure, CaseWorkflowStageModel>> updateStage({
    required String id,
    required UpdateWorkflowStageRequestModel body,
  }) => _guard(
    'updating a workflow stage',
    () => _apiService.updateWorkflowStage(id: id, body: body, token: _token),
  );

  /// Replaces the backdrop a stage shows the bench.
  ///
  /// A work reference — the diagram or photo a technician checks against — not
  /// the restoration type's catalogue shot, which lives on the doctor-facing
  /// website and is a different image for a different reader.
  Future<Either<Failure, void>> uploadStageImage({
    required String id,
    required String filePath,
  }) => _guard(
    'uploading a workflow stage image',
    () => _apiService.uploadRestorationStageImage(
      id: id,
      filePath: filePath,
      token: _token,
    ),
  );

  Future<Either<Failure, void>> deleteStage(String id) => _guard(
    'deleting a workflow stage',
    () => _apiService.deleteWorkflowStage(id: id, token: _token),
  );

  /// The route as the server sees it: its stages and its own live verdict.
  Future<Either<Failure, RouteDefinitionModel>> getRouteDefinition(
    String restorationTypeId,
  ) => _guard(
    'fetching a route definition',
    () => _apiService.getRouteDefinition(
      restorationTypeId: restorationTypeId,
      token: _token,
    ),
  );
}
