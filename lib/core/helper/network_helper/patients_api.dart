import 'dart:developer';

import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/patients/data/models/create_patient_request_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/set_price_tier_doctors_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/set_price_tier_prices_request_model.dart';

/// The `patients` endpoints — split out of
/// [ApiService], reached through the same instance.
extension PatientsApi on ApiService {
  // ------------------------------------------------------------- patients ---

  Future<List<PatientModel>> getPatients({
    String? search,
    List<String>? doctorIds,
    List<String>? clinicIds,
    int? gender,
    String? token,
  }) async {
    log('Fetching patients');

    final query = <String>[];
    if (search != null && search.isNotEmpty) {
      query.add('Search=${Uri.encodeQueryComponent(search)}');
    }
    for (final id in doctorIds ?? const []) {
      query.add('DoctorIds=${Uri.encodeQueryComponent(id)}');
    }
    for (final id in clinicIds ?? const []) {
      query.add('ClinicIds=${Uri.encodeQueryComponent(id)}');
    }
    if (gender != null) query.add('Gender=$gender');

    final responseData = await Api().get(
      url: query.isEmpty ? 'Patients' : 'Patients?${query.join('&')}',
      token: token,
    );

    log('Patients response data: ${logSafe(responseData)}');

    if (query.isEmpty) {
      await CacheHelper.saveJson(
        key: CacheKeys.cachedPatientsList,
        value: responseData,
      );
    }

    return (responseData as List<dynamic>)
        .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PatientModel> getPatientById({
    required String id,
    String? token,
  }) async {
    log('Fetching patient by id: $id');

    final responseData = await Api().get(url: 'Patients/$id', token: token);

    log('Patient by id response data: ${logSafe(responseData)}');

    return PatientModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<PatientModel> createPatient({
    required CreatePatientRequestModel createPatientRequestBody,
    String? token,
  }) async {
    final body = createPatientRequestBody.toJson();

    log('Sending Create Patient request with: ${logSafe(body)}');

    final response = await Api().post(
      url: 'Patients',
      body: body,
      token: token,
    );

    log('Create Patient response data: ${logSafe(response.data)}');

    return PatientModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Takes a [CreatePatientRequestModel] rather than an update-shaped one on
  /// purpose: the API declares the same `ClinicCreatePatientRequest` schema
  /// for both `POST /Patients` and `PUT /Patients/{id}`, so a second model
  /// would be a copy that could only drift.
  Future<PatientModel> updatePatient({
    required String id,
    required CreatePatientRequestModel patientRequestBody,
    String? token,
  }) async {
    final body = patientRequestBody.toJson();

    log('Sending Update Patient request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'Patients/$id',
      body: body,
      token: token,
    );

    log('Update Patient response data: ${logSafe(response.data)}');

    return PatientModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePatient({required String id, String? token}) async {
    log('Deleting patient: $id');

    final response = await Api().delete(url: 'Patients/$id', token: token);

    log('Delete Patient response data: ${logSafe(response.data)}');
  }

  Future<PriceTierModel> setPriceTierPrices({
    required String id,
    required SetPriceTierPricesRequestModel setPricesRequestBody,
    String? token,
  }) async {
    final body = setPricesRequestBody.toJson();

    log('Sending Set PriceTier prices request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'PriceTiers/$id/prices',
      body: body,
      token: token,
    );

    log('Set PriceTier prices response data: ${logSafe(response.data)}');

    return PriceTierModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PUT /PriceTiers/{id}/doctors` — replaces who is billed at this tier.
  Future<PriceTierModel> setPriceTierDoctors({
    required String id,
    required SetPriceTierDoctorsRequestModel body,
    String? token,
  }) async {
    log('Setting price tier $id doctors: ${body.toJson()}');

    final response = await Api().put(
      url: 'PriceTiers/$id/doctors',
      body: body.toJson(),
      token: token,
    );

    return PriceTierModel.fromJson(response.data as Map<String, dynamic>);
  }


}
