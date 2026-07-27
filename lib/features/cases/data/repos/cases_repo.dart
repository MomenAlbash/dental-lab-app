import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
import 'package:dio/dio.dart';

class CasesRepo {
  final ApiService _apiService;
  CasesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<CaseListItemModel>>> getCases({
    String? search,
  }) async {
    try {
      final cases = await _apiService.getCases(search: search, token: _token);

      log('Fetched ${cases.length} cases');
      return right(cases);
    } on DioException catch (e) {
      log('DioException while fetching cases: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching cases: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseDetailModel>> getCaseById(String id) async {
    try {
      final caseDetail = await _apiService.getCaseById(id: id, token: _token);

      log('Fetched case: ${caseDetail.caseNumber}');
      return right(caseDetail);
    } on DioException catch (e) {
      log('DioException while fetching case: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching case: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseDetailModel>> createCase(
    CreateCaseRequestModel createCaseRequestBody,
  ) async {
    try {
      final caseDetail = await _apiService.createCase(
        createCaseRequestBody: createCaseRequestBody,
        token: _token,
      );

      log('Created case: ${caseDetail.caseNumber}');
      return right(caseDetail);
    } on DioException catch (e) {
      log('DioException while creating case: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating case: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteCase(String id) async {
    try {
      await _apiService.deleteCase(id: id, token: _token);

      log('Deleted case: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting case: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting case: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> setStage({
    required String id,
    required String stageId,
    String? note,
  }) async {
    try {
      await _apiService.setCaseStage(
        id: id,
        stageId: stageId,
        note: note,
        token: _token,
      );

      log('Set stage for case: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while setting case stage: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while setting case stage: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseFileModel>> uploadFile({
    required String id,
    required String filePath,
  }) async {
    try {
      final file = await _apiService.uploadCaseFile(
        id: id,
        filePath: filePath,
        token: _token,
      );

      log('Uploaded file for case: $id');
      return right(file);
    } on DioException catch (e) {
      log('DioException while uploading case file: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while uploading case file: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteFile({
    required String id,
    required String fileId,
  }) async {
    try {
      await _apiService.deleteCaseFile(id: id, fileId: fileId, token: _token);

      log('Deleted file $fileId for case: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting case file: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting case file: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
