import 'dart:developer';

import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/create_clinic_request_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/update_clinic_request_model.dart';

/// The `clinics` endpoints — split out of
/// [ApiService], reached through the same instance.
extension ClinicsApi on ApiService {
  // --------------------------------------------------------------- clinics ---

  Future<List<ClinicModel>> getClinics({String? token}) async {
    log('Fetching clinics');

    final responseData = await Api().get(url: 'Clinics', token: token);

    log('Clinics response data: ${logSafe(responseData)}');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedClinicsList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => ClinicModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClinicModel> getClinicById({required String id, String? token}) async {
    log('Fetching clinic by id: $id');

    final responseData = await Api().get(url: 'Clinics/$id', token: token);

    log('Clinic by id response data: ${logSafe(responseData)}');

    return ClinicModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<ClinicModel> createClinic({
    required CreateClinicRequestModel createClinicRequestBody,
    String? token,
  }) async {
    final body = createClinicRequestBody.toJson();

    log('Sending Create Clinic request with: ${logSafe(body)}');

    final response = await Api().post(url: 'Clinics', body: body, token: token);

    log('Create Clinic response data: ${logSafe(response.data)}');

    return ClinicModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ClinicModel> updateClinic({
    required String id,
    required UpdateClinicRequestModel updateClinicRequestBody,
    String? token,
  }) async {
    final body = updateClinicRequestBody.toJson();

    log('Sending Update Clinic request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'Clinics/$id',
      body: body,
      token: token,
    );

    log('Update Clinic response data: ${logSafe(response.data)}');

    return ClinicModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteClinic({required String id, String? token}) async {
    log('Deleting clinic: $id');

    final response = await Api().delete(url: 'Clinics/$id', token: token);

    log('Delete Clinic response data: ${logSafe(response.data)}');
  }


}
