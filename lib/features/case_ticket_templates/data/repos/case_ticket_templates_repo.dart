import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_list_item_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/save_case_ticket_template_request_models.dart';
import 'package:dio/dio.dart';

class CaseTicketTemplatesRepo {
  CaseTicketTemplatesRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<CaseTicketTemplateListItemModel>>>
  getCaseTicketTemplates({String? laboratoryId}) async {
    try {
      final templates = await _apiService.getCaseTicketTemplates(
        laboratoryId: laboratoryId,
        token: _token,
      );

      log('Fetched ${templates.length} case ticket templates');
      return right(templates);
    } on DioException catch (e) {
      log('DioException while fetching case ticket templates: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while fetching case ticket templates: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseTicketTemplateModel>> getCaseTicketTemplateById(
    String id,
  ) async {
    try {
      final template = await _apiService.getCaseTicketTemplateById(
        id: id,
        token: _token,
      );

      log('Fetched case ticket template: ${template.name}');
      return right(template);
    } on DioException catch (e) {
      log('DioException while fetching case ticket template: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while fetching case ticket template: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseTicketTemplateModel>> createCaseTicketTemplate({
    required CreateCaseTicketTemplateRequestModel requestBody,
    String? laboratoryId,
  }) async {
    try {
      final template = await _apiService.createCaseTicketTemplate(
        body: requestBody,
        laboratoryId: laboratoryId,
        token: _token,
      );

      log('Created case ticket template: ${template.name}');
      return right(template);
    } on DioException catch (e) {
      log('DioException while creating case ticket template: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while creating case ticket template: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseTicketTemplateModel>> updateCaseTicketTemplate({
    required String id,
    required UpdateCaseTicketTemplateRequestModel requestBody,
  }) async {
    try {
      final template = await _apiService.updateCaseTicketTemplate(
        id: id,
        body: requestBody,
        token: _token,
      );

      log('Updated case ticket template: $id');
      return right(template);
    } on DioException catch (e) {
      log('DioException while updating case ticket template: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while updating case ticket template: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteCaseTicketTemplate(String id) async {
    try {
      await _apiService.deleteCaseTicketTemplate(id: id, token: _token);
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting case ticket template: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while deleting case ticket template: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseTicketTemplateModel>> setDefaultCaseTicketTemplate(
    String id,
  ) async {
    try {
      final template = await _apiService.setDefaultCaseTicketTemplate(
        id: id,
        token: _token,
      );

      log('Set default case ticket template: $id');
      return right(template);
    } on DioException catch (e) {
      log(
        'DioException while setting default case ticket template: ${e.message}',
      );
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while setting default case ticket template: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }
}
