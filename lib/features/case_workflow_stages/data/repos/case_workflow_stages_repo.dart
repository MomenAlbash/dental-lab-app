import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/create_case_workflow_stage_request_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/update_case_workflow_stage_request_model.dart';
import 'package:dio/dio.dart';

class CaseWorkflowStagesRepo {
  final ApiService _apiService;
  CaseWorkflowStagesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<CaseWorkflowStageModel>>> getStages() async {
    try {
      final stages = await _apiService.getCaseWorkflowStages(token: _token);

      log('Fetched ${stages.length} workflow stages');
      return right(stages);
    } on DioException catch (e) {
      log('DioException while fetching stages: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching stages: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseWorkflowStageModel>> createStage(
    CreateCaseWorkflowStageRequestModel createStageRequestBody,
  ) async {
    try {
      final stage = await _apiService.createCaseWorkflowStage(
        createStageRequestBody: createStageRequestBody,
        token: _token,
      );

      log('Created stage: ${stage.name}');
      return right(stage);
    } on DioException catch (e) {
      log('DioException while creating stage: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating stage: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseWorkflowStageModel>> updateStage({
    required String id,
    required UpdateCaseWorkflowStageRequestModel updateStageRequestBody,
  }) async {
    try {
      final stage = await _apiService.updateCaseWorkflowStage(
        id: id,
        updateStageRequestBody: updateStageRequestBody,
        token: _token,
      );

      log('Updated stage: ${stage.name}');
      return right(stage);
    } on DioException catch (e) {
      log('DioException while updating stage: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating stage: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteStage(String id) async {
    try {
      await _apiService.deleteCaseWorkflowStage(id: id, token: _token);

      log('Deleted stage: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting stage: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting stage: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
