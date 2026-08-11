import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_message_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_status.dart';
import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
import 'package:dio/dio.dart';

class CasesRepo {
  final ApiService _apiService;
  CasesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  String? _isoDate(DateTime? date) => date?.toIso8601String();

  /// Enforces the status filter on the rows we ended up with. The API does not
  /// reliably narrow by `CaseStatus` — an unrecognised query param comes back
  /// as the full list, which read as "the filter does nothing". Re-applying it
  /// here also covers the cache-fallback path, where no query ran at all.
  List<CaseListItemModel> _applyStatus(
    List<CaseListItemModel> cases,
    CaseStatus? status,
  ) {
    if (status == null) return cases;
    return cases.where((c) => c.caseStatus == status).toList();
  }

  Future<Either<Failure, List<CaseListItemModel>>> getCases({
    String? search,
    CaseFiltersModel filters = CaseFiltersModel.empty,
  }) async {
    try {
      final cases = await _apiService.getCases(
        search: search,
        doctorId: filters.doctorId,
        clinicId: filters.clinicId,
        patientId: filters.patientId,
        priorityId: filters.priorityId,
        caseStatus: filters.caseStatus?.apiValue,
        dueDateFrom: _isoDate(filters.dueDateFrom),
        dueDateTo: _isoDate(filters.dueDateTo),
        token: _token,
      );

      log('Fetched ${cases.length} cases');
      return right(_applyStatus(cases, filters.caseStatus));
    } on DioException catch (e) {
      log('DioException while fetching cases: ${e.message}');
      final cached = fallbackToCache(
        cacheKey: CacheKeys.cachedCasesList,
        fromJson: CaseListItemModel.fromJson,
        onFailure: () => ServerFailure.FromDioExecption(e),
      );
      return cached.map((cases) => _applyStatus(cases, filters.caseStatus));
    } catch (e) {
      log('General Exception while fetching cases: ${e.toString()}');
      final cached = fallbackToCache(
        cacheKey: CacheKeys.cachedCasesList,
        fromJson: CaseListItemModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
      return cached.map((cases) => _applyStatus(cases, filters.caseStatus));
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

  /// Sets the stage of one restoration within the case — stages are scoped
  /// to a restoration (and, through it, to its restoration type), not to the
  /// case as a whole.
  Future<Either<Failure, void>> setRestorationStage({
    required String caseId,
    required String restorationId,
    required String stageId,
    String? note,
  }) async {
    try {
      await _apiService.setRestorationStage(
        caseId: caseId,
        restorationId: restorationId,
        stageId: stageId,
        note: note,
        token: _token,
      );

      log('Set stage for restoration $restorationId (case $caseId)');
      return right(null);
    } on DioException catch (e) {
      log('DioException while setting restoration stage: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while setting restoration stage: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Sets the case's overall status — a fixed lifecycle owned by the case
  /// itself, distinct from any restoration's workflow stage.
  Future<Either<Failure, CaseDetailModel>> setCaseStatus({
    required String id,
    required CaseStatus status,
    String? note,
  }) async {
    try {
      final caseDetail = await _apiService.setCaseStatus(
        id: id,
        caseStatus: status.apiValue,
        note: note,
        token: _token,
      );

      log('Set status ${status.apiValue} for case $id');
      return right(caseDetail);
    } on DioException catch (e) {
      log('DioException while setting case status: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while setting case status: ${e.toString()}');
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

  Future<Either<Failure, List<CaseMessageModel>>> getMessages(String id) async {
    try {
      final messages = await _apiService.getCaseMessages(id: id, token: _token);

      log('Fetched ${messages.length} messages for case: $id');
      return right(messages);
    } on DioException catch (e) {
      log('DioException while fetching case messages: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching case messages: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseMessageModel>> sendMessage({
    required String id,
    String? message,
    String? replyToMessageId,
    String? filePath,
  }) async {
    try {
      final sent = await _apiService.sendCaseMessage(
        id: id,
        message: message,
        replyToMessageId: replyToMessageId,
        filePath: filePath,
        token: _token,
      );

      log('Sent message for case: $id');
      return right(sent);
    } on DioException catch (e) {
      log('DioException while sending case message: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while sending case message: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteMessage({
    required String id,
    required String messageId,
  }) async {
    try {
      await _apiService.deleteCaseMessage(
        id: id,
        messageId: messageId,
        token: _token,
      );

      log('Deleted message $messageId for case: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting case message: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting case message: ${e.toString()}');
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
