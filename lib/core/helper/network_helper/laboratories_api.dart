import 'dart:developer';

import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/laboratories/data/models/create_laboratory_request_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/update_laboratory_request_model.dart';

/// The `laboratories` endpoints — split out of
/// [ApiService], reached through the same instance.
extension LaboratoriesApi on ApiService {
  // --------------------------------------------------------- laboratories ---

  Future<List<LaboratoryModel>> getLaboratories({String? token}) async {
    log('Fetching laboratories');

    final responseData = await Api().get(url: 'Laboratories', token: token);

    log('Laboratories response data: ${logSafe(responseData)}');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedLaboratoriesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => LaboratoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LaboratoryModel> getOwnLaboratory({String? token}) async {
    log('Fetching own laboratory');

    final responseData = await Api().get(url: 'Laboratories/own', token: token);

    log('Own laboratory response data: ${logSafe(responseData)}');

    return LaboratoryModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<LaboratoryModel> getLaboratoryById({
    required String id,
    String? token,
  }) async {
    log('Fetching laboratory by id: $id');

    final responseData = await Api().get(url: 'Laboratories/$id', token: token);

    log('Laboratory by id response data: ${logSafe(responseData)}');

    return LaboratoryModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<LaboratoryModel> createLaboratory({
    required CreateLaboratoryRequestModel createLaboratoryRequestBody,
    String? token,
  }) async {
    final body = createLaboratoryRequestBody.toJson();

    log('Sending Create Laboratory request with: ${logSafe(body)}');

    final response = await Api().post(
      url: 'Laboratories',
      body: body,
      token: token,
    );

    log('Create Laboratory response data: ${logSafe(response.data)}');

    return LaboratoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LaboratoryModel> updateLaboratory({
    required String id,
    required UpdateLaboratoryRequestModel updateLaboratoryRequestBody,
    String? token,
  }) async {
    final body = updateLaboratoryRequestBody.toJson();

    log('Sending Update Laboratory request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'Laboratories/$id',
      body: body,
      token: token,
    );

    log('Update Laboratory response data: ${logSafe(response.data)}');

    return LaboratoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteLaboratory({required String id, String? token}) async {
    log('Deleting laboratory: $id');

    final response = await Api().delete(url: 'Laboratories/$id', token: token);

    log('Delete Laboratory response data: ${logSafe(response.data)}');
  }


}
