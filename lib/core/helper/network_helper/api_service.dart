import 'dart:developer';

import 'package:dental_lab_app/core/helper/api_time_helper.dart';

import 'package:dental_lab_app/features/accounting/data/models/accounting_statistics_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/cashbox_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/create_invoice_request_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/doctor_statement_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/expense_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/invoice_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';
import 'package:dental_lab_app/features/areas/data/models/area_model.dart';
import 'package:dental_lab_app/features/areas/data/models/save_area_request_models.dart';
import 'package:dental_lab_app/features/currencies/data/models/save_currency_request_models.dart';
import 'package:dental_lab_app/features/zones/data/models/save_zone_request_models.dart';
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/features/auth/data/models/login_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_exception_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_rule_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_exception_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_rule_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_day_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/save_case_priority_request_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/route_problem_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/save_case_stage_request_models.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/route_definition_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/save_workflow_stage_request_models.dart';
import 'package:dental_lab_app/features/departments/data/models/department_model.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_page_model.dart';
import 'package:dental_lab_app/features/departments/data/models/save_department_request_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_filters_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_request_models.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_breakdown_models.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_barcode_models.dart';
import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_flow_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_message_model.dart';
import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
import 'package:dental_lab_app/features/cases/data/models/deliver_directly_models.dart';
import 'package:dental_lab_app/features/cases/data/models/send_back_models.dart';
import 'package:dental_lab_app/features/auth/data/models/login_response_model.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/countries/data/models/country_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/create_clinic_request_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/update_clinic_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/approve_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/create_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_attachment_file_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_price_tier_spell_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_movement_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/record_inventory_movement_request_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/save_inventory_item_request_model.dart';
import 'package:dental_lab_app/features/purchases/data/models/create_purchase_request_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_list_item_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/save_case_ticket_template_request_models.dart';
import 'package:dental_lab_app/features/store_reports/data/models/monthly_feasibility_model.dart';
import 'package:dental_lab_app/features/purchases/data/models/purchase_model.dart';
import 'package:dental_lab_app/features/suppliers/data/models/save_supplier_request_model.dart';
import 'package:dental_lab_app/features/suppliers/data/models/supplier_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/exclusion_reason_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/update_doctor_request_model.dart';
import 'package:dental_lab_app/features/employees/data/models/create_employee_request_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_attachment_file_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/models/update_employee_request_model.dart';
import 'package:dental_lab_app/features/patients/data/models/create_patient_request_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/create_price_tier_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/set_price_tier_doctors_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/set_price_tier_prices_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/update_price_tier_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/create_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/doctor_restoration_type_lookup_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/update_restoration_type_request_model.dart';
import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/features/roles/data/models/create_role_request_model.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';
import 'package:dental_lab_app/features/roles/data/models/set_role_permissions_request_model.dart';
import 'package:dental_lab_app/features/roles/data/models/update_role_request_model.dart';
import 'package:dental_lab_app/features/users/data/models/create_user_request_model.dart';
import 'package:dental_lab_app/features/users/data/models/update_user_request_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:dental_lab_app/features/laboratories/data/models/create_laboratory_request_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/update_laboratory_request_model.dart';

class ApiService {
  // ---------------------------------------------------------------- auth ---

  Future<LoginResponseModel> userLogin({
    required LoginRequestModel loginRequestBody,
  }) async {
    final body = loginRequestBody.toJson();

    log('Sending Login request with: $body');

    final response = await Api().post(url: 'ClinicAuth/login', body: body);

    log('Login response data: ${response.data}');

    return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? token,
  }) async {
    log('Sending Change Password request');

    final response = await Api().post(
      url: 'ClinicAuth/change-password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      token: token,
    );

    log('Change Password response data: ${response.data}');
  }

  // --------------------------------------------------------- laboratories ---

  Future<List<LaboratoryModel>> getLaboratories({String? token}) async {
    log('Fetching laboratories');

    final responseData = await Api().get(url: 'Laboratories', token: token);

    log('Laboratories response data: $responseData');

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

    log('Own laboratory response data: $responseData');

    return LaboratoryModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<LaboratoryModel> getLaboratoryById({
    required String id,
    String? token,
  }) async {
    log('Fetching laboratory by id: $id');

    final responseData = await Api().get(url: 'Laboratories/$id', token: token);

    log('Laboratory by id response data: $responseData');

    return LaboratoryModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<LaboratoryModel> createLaboratory({
    required CreateLaboratoryRequestModel createLaboratoryRequestBody,
    String? token,
  }) async {
    final body = createLaboratoryRequestBody.toJson();

    log('Sending Create Laboratory request with: $body');

    final response = await Api().post(
      url: 'Laboratories',
      body: body,
      token: token,
    );

    log('Create Laboratory response data: ${response.data}');

    return LaboratoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LaboratoryModel> updateLaboratory({
    required String id,
    required UpdateLaboratoryRequestModel updateLaboratoryRequestBody,
    String? token,
  }) async {
    final body = updateLaboratoryRequestBody.toJson();

    log('Sending Update Laboratory request with: $body');

    final response = await Api().put(
      url: 'Laboratories/$id',
      body: body,
      token: token,
    );

    log('Update Laboratory response data: ${response.data}');

    return LaboratoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteLaboratory({required String id, String? token}) async {
    log('Deleting laboratory: $id');

    final response = await Api().delete(url: 'Laboratories/$id', token: token);

    log('Delete Laboratory response data: ${response.data}');
  }

  // --------------------------------------------------------------- clinics ---

  Future<List<ClinicModel>> getClinics({String? token}) async {
    log('Fetching clinics');

    final responseData = await Api().get(url: 'Clinics', token: token);

    log('Clinics response data: $responseData');

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

    log('Clinic by id response data: $responseData');

    return ClinicModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<ClinicModel> createClinic({
    required CreateClinicRequestModel createClinicRequestBody,
    String? token,
  }) async {
    final body = createClinicRequestBody.toJson();

    log('Sending Create Clinic request with: $body');

    final response = await Api().post(url: 'Clinics', body: body, token: token);

    log('Create Clinic response data: ${response.data}');

    return ClinicModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ClinicModel> updateClinic({
    required String id,
    required UpdateClinicRequestModel updateClinicRequestBody,
    String? token,
  }) async {
    final body = updateClinicRequestBody.toJson();

    log('Sending Update Clinic request with: $body');

    final response = await Api().put(
      url: 'Clinics/$id',
      body: body,
      token: token,
    );

    log('Update Clinic response data: ${response.data}');

    return ClinicModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteClinic({required String id, String? token}) async {
    log('Deleting clinic: $id');

    final response = await Api().delete(url: 'Clinics/$id', token: token);

    log('Delete Clinic response data: ${response.data}');
  }

  // ---------------------------------------------------------------- cities ---

  Future<List<CityModel>> getCities({String? countryId, String? token}) async {
    log('Fetching cities');

    final url = countryId == null ? 'Cities' : 'Cities?countryId=$countryId';
    final responseData = await Api().get(url: url, token: token);

    log('Cities response data: $responseData');

    if (countryId == null) {
      await CacheHelper.saveJson(
        key: CacheKeys.cachedCitiesList,
        value: responseData,
      );
    }

    return (responseData as List<dynamic>)
        .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CityModel> createCity({
    required String name,
    String? countryId,
    String? token,
  }) async {
    log('Sending Create City request with: $name');

    final response = await Api().post(
      url: 'Cities',
      body: {'name': name, 'countryId': countryId},
      token: token,
    );

    log('Create City response data: ${response.data}');

    return CityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CityModel> updateCity({
    required String id,
    required String name,
    String? countryId,
    String? token,
  }) async {
    log('Sending Update City request with: $name');

    final response = await Api().put(
      url: 'Cities/$id',
      body: {'name': name, 'countryId': countryId},
      token: token,
    );

    log('Update City response data: ${response.data}');

    return CityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCity({required String id, String? token}) async {
    log('Deleting city: $id');

    final response = await Api().delete(url: 'Cities/$id', token: token);

    log('Delete City response data: ${response.data}');
  }

  // ----------------------------------------------------------------- areas ---

  Future<List<AreaModel>> getAreas({String? cityId, String? token}) async {
    log('Fetching areas (cityId: $cityId)');

    final url = cityId == null ? 'Areas' : 'Areas?cityId=$cityId';
    final responseData = await Api().get(url: url, token: token);

    return (responseData as List<dynamic>)
        .map((e) => AreaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AreaModel> createArea({
    required CreateAreaRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create Area request with: $body');

    final response = await Api().post(url: 'Areas', body: body, token: token);

    return AreaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AreaModel> updateArea({
    required String id,
    required UpdateAreaRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update Area request with: $body');

    final response = await Api().put(
      url: 'Areas/$id',
      body: body,
      token: token,
    );

    return AreaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteArea({required String id, String? token}) async {
    log('Deleting area: $id');

    final response = await Api().delete(url: 'Areas/$id', token: token);

    log('Delete Area response data: ${response.data}');
  }

  // ----------------------------------------------------------------- zones ---

  Future<List<ZoneModel>> getZones({
    bool includeInactive = false,
    List<String>? laboratoryIds,
    String? token,
  }) async {
    log('Fetching zones (includeInactive: $includeInactive)');

    final params = <String>['includeInactive=$includeInactive'];
    for (final id in laboratoryIds ?? const <String>[]) {
      params.add('laboratoryIds=${Uri.encodeQueryComponent(id)}');
    }

    final responseData = await Api().get(
      url: 'Zones?${params.join('&')}',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ZoneModel> getZoneById({required String id, String? token}) async {
    log('Fetching zone by id: $id');

    final responseData = await Api().get(url: 'Zones/$id', token: token);

    return ZoneModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<ZoneModel> createZone({
    required CreateZoneRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create Zone request with: $body');

    final response = await Api().post(url: 'Zones', body: body, token: token);

    return ZoneModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ZoneModel> updateZone({
    required String id,
    required UpdateZoneRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update Zone request with: $body');

    final response = await Api().put(
      url: 'Zones/$id',
      body: body,
      token: token,
    );

    return ZoneModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteZone({required String id, String? token}) async {
    log('Deleting zone: $id');

    final response = await Api().delete(url: 'Zones/$id', token: token);

    log('Delete Zone response data: ${response.data}');
  }

  // ------------------------------------------------------------ accounting ---

  /// `GET /Accounting/invoices`. Every filter is optional; the query is
  /// built with only the ones given rather than sending `null` params.
  Future<List<InvoiceModel>> getInvoices({
    String? doctorId,
    String? from,
    String? to,
    InvoiceStatus? status,
    String? search,
    String? token,
  }) async {
    log('Fetching invoices');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('doctorId', doctorId);
    add('from', from);
    add('to', to);
    add('search', search);
    if (status != null) params.add('status=${status.value}');

    final url = params.isEmpty
        ? 'Accounting/invoices'
        : 'Accounting/invoices?${params.join('&')}';
    final responseData = await Api().get(url: url, token: token);

    return (responseData as List<dynamic>)
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InvoiceModel> getInvoiceById({
    required String id,
    String? token,
  }) async {
    log('Fetching invoice by id: $id');

    final responseData = await Api().get(
      url: 'Accounting/invoices/$id',
      token: token,
    );

    return InvoiceModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// `GET /Accounting/statistics`.
  Future<AccountingStatisticsModel> getAccountingStatistics({
    String? doctorId,
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching accounting statistics');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('doctorId', doctorId);
    add('from', from);
    add('to', to);

    final url = params.isEmpty
        ? 'Accounting/statistics'
        : 'Accounting/statistics?${params.join('&')}';
    final responseData = await Api().get(url: url, token: token);

    return AccountingStatisticsModel.fromJson(
      responseData as Map<String, dynamic>,
    );
  }

  /// `GET /Accounting/payments` — the lab's payment history.
  Future<List<PaymentModel>> getPayments({
    String? doctorId,
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching payments');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('doctorId', doctorId);
    add('from', from);
    add('to', to);

    final url = params.isEmpty
        ? 'Accounting/payments'
        : 'Accounting/payments?${params.join('&')}';
    final responseData = await Api().get(url: url, token: token);

    return (responseData as List<dynamic>)
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /Accounting/payments/pending`.
  Future<List<PaymentModel>> getPendingPayments({String? token}) async {
    log('Fetching pending payments');

    final responseData = await Api().get(
      url: 'Accounting/payments/pending',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /Accounting/payments/{id}/verify?approve=`.
  Future<PaymentModel> verifyPayment({
    required String id,
    required bool approve,
    String? notes,
    String? token,
  }) async {
    log('Verifying payment $id (approve: $approve)');

    final response = await Api().post(
      url: 'Accounting/payments/$id/verify?approve=$approve',
      body: {'notes': notes},
      token: token,
    );

    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Accounting/payments/manual` — multipart; [receiptFilePath] is
  /// optional (a doctor may pay in person with nothing to attach).
  Future<PaymentModel> createManualPayment({
    required String invoiceId,
    required String doctorId,
    required double amount,
    PaymentMethod? method,
    String? notes,
    String? receiptFilePath,
    String? token,
  }) async {
    log('Recording manual payment for invoice $invoiceId');

    final formData = FormData.fromMap({
      'InvoiceId': invoiceId,
      'DoctorId': doctorId,
      'Amount': amount,
      if (method != null) 'Method': method.value,
      'Notes': ?notes,
      if (receiptFilePath != null)
        'receipt': await MultipartFile.fromFile(receiptFilePath),
    });

    final response = await Api().post(
      url: 'Accounting/payments/manual',
      body: formData,
      isFormData: true,
      token: token,
    );

    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /Accounting/expenses`.
  Future<List<ExpenseModel>> getExpenses({
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching expenses');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('from', from);
    add('to', to);

    final url = params.isEmpty
        ? 'Accounting/expenses'
        : 'Accounting/expenses?${params.join('&')}';
    final responseData = await Api().get(url: url, token: token);

    return (responseData as List<dynamic>)
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExpenseModel> createExpense({
    required CreateExpenseRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create Expense request with: $body');

    final response = await Api().post(
      url: 'Accounting/expenses',
      body: body,
      token: token,
    );

    return ExpenseModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---- Cash box ---------------------------------------------------------
  //
  // The laboratory's actual drawer: an opening balance per currency, plus
  // every verified payment, expense and manual movement since. One ledger per
  // currency, never blended — see [CashBoxLedgerModel].

  /// `GET /Accounting/cashbox/ledger` — one ledger per currency.
  Future<List<CashBoxLedgerModel>> getCashboxLedger({
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching cashbox ledger');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('from', from);
    add('to', to);

    final responseData = await Api().get(
      url: params.isEmpty
          ? 'Accounting/cashbox/ledger'
          : 'Accounting/cashbox/ledger?${params.join('&')}',
      token: token,
    );

    return _decodeList(responseData, CashBoxLedgerModel.fromJson);
  }

  /// `GET /Accounting/cashbox/opening-balances`.
  Future<List<CashBoxOpeningBalanceModel>> getCashboxOpeningBalances({
    String? token,
  }) async {
    log('Fetching cashbox opening balances');

    final responseData = await Api().get(
      url: 'Accounting/cashbox/opening-balances',
      token: token,
    );

    return _decodeList(responseData, CashBoxOpeningBalanceModel.fromJson);
  }

  /// `POST /Accounting/cashbox/opening-balance` — sets (or replaces) what the
  /// box held in one currency before the ledger begins.
  Future<CashBoxOpeningBalanceModel> setCashboxOpeningBalance({
    required SetCashBoxOpeningBalanceRequestModel body,
    String? token,
  }) async {
    log('Setting cashbox opening balance: ${body.toJson()}');

    final response = await Api().post(
      url: 'Accounting/cashbox/opening-balance',
      body: body.toJson(),
      token: token,
    );

    return CashBoxOpeningBalanceModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `POST /Accounting/cashbox/entries` — a manual cash movement.
  Future<CashBoxLedgerEntryModel> createCashboxEntry({
    required CreateCashBoxEntryRequestModel body,
    String? token,
  }) async {
    log('Creating cashbox entry: ${body.toJson()}');

    final response = await Api().post(
      url: 'Accounting/cashbox/entries',
      body: body.toJson(),
      token: token,
    );

    return CashBoxLedgerEntryModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `DELETE /Accounting/cashbox/entries/{id}` — five minutes for an ordinary
  /// user, any time for an admin. Only a manual entry has an id to pass.
  Future<void> deleteCashboxEntry({required String id, String? token}) async {
    log('Deleting cashbox entry $id');

    await Api().delete(url: 'Accounting/cashbox/entries/$id', token: token);
  }

  /// `POST /Accounting/doctors/{doctorId}/settle` — settles every outstanding
  /// invoice a doctor has **in one currency**, in one action.
  ///
  /// Per currency because money is never blended across currencies anywhere in
  /// this app; and with no receipt, because one file cannot stand for the N
  /// invoices this closes.
  Future<DoctorStatementModel> settleDoctorBalance({
    required String doctorId,
    required String currencyId,
    PaymentMethod? method,
    String? notes,
    String? token,
  }) async {
    log('Settling doctor $doctorId in currency $currencyId');

    final response = await Api().post(
      url: 'Accounting/doctors/$doctorId/settle',
      body: {
        'currencyId': currencyId,
        if (method != null) 'method': method.value,
        'notes': ?notes,
      },
      token: token,
    );

    return DoctorStatementModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /Accounting/payments/{id}` — permanent, and gated on
  /// `Finance:FullAccess` server-side.
  Future<void> deletePayment({required String id, String? token}) async {
    log('Deleting payment $id');

    await Api().delete(url: 'Accounting/payments/$id', token: token);
  }

  /// `DELETE /Accounting/invoices/{id}` — admin only, within five minutes of
  /// issue, and only while the invoice has no payments against it.
  Future<void> deleteInvoice({required String id, String? token}) async {
    log('Deleting invoice $id');

    await Api().delete(url: 'Accounting/invoices/$id', token: token);
  }

  /// `GET /Currencies` — every currency, used both by the currencies
  /// management screen and to populate every other feature's currency
  /// picker (expenses, restoration-type pricing, case restorations, ...).
  Future<List<CurrencyModel>> getCurrencies({String? token}) async {
    log('Fetching currencies');

    final responseData = await Api().get(url: 'Currencies', token: token);

    return (responseData as List<dynamic>)
        .map((e) => CurrencyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CurrencyModel> createCurrency({
    required CreateCurrencyRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create Currency request with: $body');

    final response = await Api().post(
      url: 'Currencies',
      body: body,
      token: token,
    );

    return CurrencyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CurrencyModel> updateCurrency({
    required String id,
    required UpdateCurrencyRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update Currency request with: $body');

    final response = await Api().put(
      url: 'Currencies/$id',
      body: body,
      token: token,
    );

    return CurrencyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCurrency({required String id, String? token}) async {
    log('Deleting currency: $id');

    final response = await Api().delete(url: 'Currencies/$id', token: token);

    log('Delete Currency response data: ${response.data}');
  }

  /// `GET /Accounting/doctors/{doctorId}/statement`.
  Future<DoctorStatementModel> getDoctorStatement({
    required String doctorId,
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching doctor statement: $doctorId');

    final params = <String>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add('$key=${Uri.encodeQueryComponent(value)}');
      }
    }

    add('from', from);
    add('to', to);

    final url = params.isEmpty
        ? 'Accounting/doctors/$doctorId/statement'
        : 'Accounting/doctors/$doctorId/statement?${params.join('&')}';
    final responseData = await Api().get(url: url, token: token);

    return DoctorStatementModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// `POST /Accounting/invoices`.
  Future<InvoiceModel> createInvoice({
    required CreateInvoiceRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create Invoice request with: $body');

    final response = await Api().post(
      url: 'Accounting/invoices',
      body: body,
      token: token,
    );

    return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Accounting/invoices/from-case/{caseId}` — generates the case's
  /// invoice, or returns the one already generated for it (idempotent).
  Future<InvoiceModel> createInvoiceFromCase({
    required String caseId,
    double? discountValue,
    double? discountPercentage,
    String? token,
  }) async {
    log('Generating invoice for case: $caseId');

    final response = await Api().post(
      url: 'Accounting/invoices/from-case/$caseId',
      body: {
        'discountValue': discountValue,
        'discountPercentage': discountPercentage,
      },
      token: token,
    );

    return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /Reports/invoices/{id}/pdf` — raw bytes. Bypasses [Api.get]'s
  /// JSON-oriented decoding (it never sets a binary `responseType`) and goes
  /// through [Api.dio] directly instead, so the same auth interceptor still
  /// attaches the bearer token this endpoint needs.
  ///
  /// Lives under `Reports`, not `Accounting`: every printable document the API
  /// renders (the case sheet, the CSV export, this) sits on that controller,
  /// and the old `Accounting/invoices/{id}/pdf` route no longer exists.
  Future<List<int>> downloadInvoicePdf({
    required String id,
    String? token,
  }) async {
    log('Downloading invoice PDF: $id');

    final response = await Api.dio.get<List<int>>(
      'Reports/invoices/$id/pdf',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );

    return response.data ?? const [];
  }

  // ------------------------------------------------------------- countries ---

  Future<List<CountryModel>> getCountries({String? token}) async {
    log('Fetching countries');

    final responseData = await Api().get(url: 'Countries', token: token);

    log('Countries response data: $responseData');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedCountriesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => CountryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CountryModel> createCountry({
    required String name,
    String? token,
  }) async {
    log('Sending Create Country request with: $name');

    final response = await Api().post(
      url: 'Countries',
      body: {'name': name},
      token: token,
    );

    log('Create Country response data: ${response.data}');

    return CountryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CountryModel> updateCountry({
    required String id,
    required String name,
    String? token,
  }) async {
    log('Sending Update Country request with: $name');

    final response = await Api().put(
      url: 'Countries/$id',
      body: {'name': name},
      token: token,
    );

    log('Update Country response data: ${response.data}');

    return CountryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCountry({required String id, String? token}) async {
    log('Deleting country: $id');

    final response = await Api().delete(url: 'Countries/$id', token: token);

    log('Delete Country response data: ${response.data}');
  }

  // --------------------------------------------------------------- doctors ---

  Future<List<DoctorModel>> getDoctors({String? token}) async {
    log('Fetching doctors');

    final responseData = await Api().get(url: 'Doctors', token: token);

    log('Doctors response data: $responseData');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedDoctorsList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorModel> getDoctorById({required String id, String? token}) async {
    log('Fetching doctor by id: $id');

    final responseData = await Api().get(url: 'Doctors/$id', token: token);

    log('Doctor by id response data: $responseData');

    return DoctorModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<DoctorModel> createDoctor({
    required CreateDoctorRequestModel createDoctorRequestBody,
    String? token,
  }) async {
    final body = createDoctorRequestBody.toJson();

    log('Sending Create Doctor request with: $body');

    final response = await Api().post(url: 'Doctors', body: body, token: token);

    log('Create Doctor response data: ${response.data}');

    return DoctorModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DoctorModel> updateDoctor({
    required String id,
    required UpdateDoctorRequestModel updateDoctorRequestBody,
    String? token,
  }) async {
    final body = updateDoctorRequestBody.toJson();

    log('Sending Update Doctor request with: $body');

    final response = await Api().put(
      url: 'Doctors/$id',
      body: body,
      token: token,
    );

    log('Update Doctor response data: ${response.data}');

    return DoctorModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Doctors/{id}/approve` — accepts a self-registered doctor,
  /// optionally linking them to a clinic in the same call.
  Future<DoctorModel> approveDoctor({
    required String id,
    required ApproveDoctorRequestModel approveDoctorRequestBody,
    String? token,
  }) async {
    final body = approveDoctorRequestBody.toJson();

    log('Sending Approve Doctor request with: $body');

    final response = await Api().post(
      url: 'Doctors/$id/approve',
      body: body,
      token: token,
    );

    log('Approve Doctor response data: ${response.data}');

    return DoctorModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Doctors/{id}/reject` — turns a registration down. The API requires
  /// a reason, which is shown back on the doctor's page.
  Future<DoctorModel> rejectDoctor({
    required String id,
    required RejectDoctorRequestModel rejectDoctorRequestBody,
    String? token,
  }) async {
    final body = rejectDoctorRequestBody.toJson();

    log('Sending Reject Doctor request with: $body');

    final response = await Api().post(
      url: 'Doctors/$id/reject',
      body: body,
      token: token,
    );

    log('Reject Doctor response data: ${response.data}');

    return DoctorModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDoctor({required String id, String? token}) async {
    log('Deleting doctor: $id');

    final response = await Api().delete(url: 'Doctors/$id', token: token);

    log('Delete Doctor response data: ${response.data}');
  }

  Future<DoctorAttachmentFileModel> uploadDoctorFile({
    required String id,
    required String filePath,
    String? token,
  }) async {
    log('Uploading file for doctor: $id');

    final formData = FormData.fromMap({
      'Id': id,
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await Api().post(
      url: 'Doctors/$id/files',
      body: formData,
      isFormData: true,
      token: token,
    );

    log('Upload Doctor file response data: ${response.data}');

    return DoctorAttachmentFileModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteDoctorFile({
    required String id,
    required String fileId,
    String? token,
  }) async {
    log('Deleting file $fileId for doctor: $id');

    final response = await Api().delete(
      url: 'Doctors/$id/files/$fileId',
      token: token,
    );

    log('Delete Doctor file response data: ${response.data}');
  }

  /// `GET /doctors/{doctorId}/zone` — the territory this doctor falls under.
  ///
  /// Resolved server-side from their area, or from a manual pin where one was
  /// set: which of the two it came from is not something the client can work
  /// out from the doctor's own record, and the answer decides which
  /// representatives may take their scanner sessions.
  ///
  /// Null when the doctor sits in no zone at all — an ordinary state for a
  /// doctor whose area has not been mapped yet, not an error.
  Future<ZoneModel?> getDoctorZone({
    required String doctorId,
    String? token,
  }) async {
    log('Fetching zone for doctor: $doctorId');

    final data = await Api().get(url: 'doctors/$doctorId/zone', token: token);
    if (data is! Map<String, dynamic>) return null;

    return ZoneModel.fromJson(data);
  }

  /// `GET /doctors/{doctorId}/excluded-representatives` — representatives
  /// vetoed from this doctor's own scanner sessions, regardless of zone.
  Future<List<ZoneRepresentativeModel>> getExcludedRepresentatives({
    required String doctorId,
    String? token,
  }) async {
    log('Fetching excluded representatives for doctor: $doctorId');

    final responseData = await Api().get(
      url: 'doctors/$doctorId/excluded-representatives',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => ZoneRepresentativeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `PUT /doctors/{doctorId}/excluded-representatives/{userId}` —
  /// representative [userId] is never candidated for this doctor again.
  Future<void> excludeRepresentative({
    required String doctorId,
    required String userId,
    required ExclusionReasonRequestModel body,
    String? token,
  }) async {
    log(
      'Excluding representative $userId for doctor $doctorId: ${body.toJson()}',
    );

    await Api().put(
      url: 'doctors/$doctorId/excluded-representatives/$userId',
      body: body.toJson(),
      token: token,
    );
  }

  /// `DELETE /doctors/{doctorId}/excluded-representatives/{userId}`.
  Future<void> removeExcludedRepresentative({
    required String doctorId,
    required String userId,
    String? token,
  }) async {
    log('Removing exclusion of $userId for doctor $doctorId');

    await Api().delete(
      url: 'doctors/$doctorId/excluded-representatives/$userId',
      token: token,
    );
  }

  /// `GET /Doctors/{id}/price-tier-history` — every stretch of time the
  /// doctor spent on a price tier, oldest and newest alike.
  Future<List<DoctorPriceTierSpellModel>> getDoctorPriceTierHistory({
    required String doctorId,
    String? token,
  }) async {
    log('Fetching price-tier history for doctor: $doctorId');

    final responseData = await Api().get(
      url: 'Doctors/$doctorId/price-tier-history',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map(
          (e) => DoctorPriceTierSpellModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  // ------------------------------------------------------------- employees ---

  Future<List<EmployeeModel>> getEmployees({String? token}) async {
    log('Fetching employees');

    final responseData = await Api().get(url: 'Employees', token: token);

    log('Employees response data: $responseData');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedEmployeesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EmployeeModel> getEmployeeById({
    required String id,
    String? token,
  }) async {
    log('Fetching employee by id: $id');

    final responseData = await Api().get(url: 'Employees/$id', token: token);

    log('Employee by id response data: $responseData');

    return EmployeeModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<EmployeeModel> createEmployee({
    required CreateEmployeeRequestModel createEmployeeRequestBody,
    String? token,
  }) async {
    final fields = createEmployeeRequestBody.toFormMap();

    log('Sending Create Employee request with: $fields');

    final formData = FormData.fromMap(fields);

    final response = await Api().post(
      url: 'Employees',
      body: formData,
      isFormData: true,
      token: token,
    );

    log('Create Employee response data: ${response.data}');

    return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmployeeModel> updateEmployee({
    required String id,
    required UpdateEmployeeRequestModel updateEmployeeRequestBody,
    String? token,
  }) async {
    final body = updateEmployeeRequestBody.toJson();

    log('Sending Update Employee request with: $body');

    final response = await Api().put(
      url: 'Employees/$id',
      body: body,
      token: token,
    );

    log('Update Employee response data: ${response.data}');

    return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteEmployee({required String id, String? token}) async {
    log('Deleting employee: $id');

    final response = await Api().delete(url: 'Employees/$id', token: token);

    log('Delete Employee response data: ${response.data}');
  }

  Future<EmployeeAttachmentFileModel> uploadEmployeeFile({
    required String id,
    required String filePath,
    String? token,
  }) async {
    log('Uploading file for employee: $id');

    final formData = FormData.fromMap({
      'Id': id,
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await Api().post(
      url: 'Employees/$id/files',
      body: formData,
      isFormData: true,
      token: token,
    );

    log('Upload Employee file response data: ${response.data}');

    return EmployeeAttachmentFileModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteEmployeeFile({
    required String id,
    required String fileId,
    String? token,
  }) async {
    log('Deleting file $fileId for employee: $id');

    final response = await Api().delete(
      url: 'Employees/$id/files/$fileId',
      token: token,
    );

    log('Delete Employee file response data: ${response.data}');
  }

  // ----------------------------------------------------------------- roles ---

  Future<List<RoleModel>> getRoles({String? token}) async {
    log('Fetching roles');

    final responseData = await Api().get(url: 'Roles', token: token);

    log('Roles response data: $responseData');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedRolesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RoleModel> getRoleById({required String id, String? token}) async {
    log('Fetching role by id: $id');

    final responseData = await Api().get(url: 'Roles/$id', token: token);

    return RoleModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<RoleModel> createRole({
    required CreateRoleRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create Role request with: $body');

    final response = await Api().post(url: 'Roles', body: body, token: token);

    log('Create Role response data: ${response.data}');

    return RoleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoleModel> updateRole({
    required String id,
    required UpdateRoleRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update Role request with: $body');

    final response = await Api().put(
      url: 'Roles/$id',
      body: body,
      token: token,
    );

    log('Update Role response data: ${response.data}');

    return RoleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRole({required String id, String? token}) async {
    log('Deleting role: $id');

    final response = await Api().delete(url: 'Roles/$id', token: token);

    log('Delete Role response data: ${response.data}');
  }

  /// `GET /Roles/permissions` — the modules available to grant, scoped to
  /// [userType] since the server publishes a different set per app.
  Future<List<PermissionName>> getRolePermissionCatalog({
    required RoleUserType userType,
    String? token,
  }) async {
    log('Fetching role permission catalog for userType: ${userType.name}');

    final responseData = await Api().get(
      url: 'Roles/permissions?userType=${userType.value}',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => PermissionName.fromValue(e as int?))
        .whereType<PermissionName>()
        .toList();
  }

  Future<RoleModel> setRolePermissions({
    required String id,
    required SetRolePermissionsRequestModel setRequestBody,
    String? token,
  }) async {
    final body = setRequestBody.toJson();

    log('Setting permissions for role $id: $body');

    final response = await Api().put(
      url: 'Roles/$id/permissions',
      body: body,
      token: token,
    );

    return RoleModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ----------------------------------------------------------------- users ---

  Future<List<UserModel>> getUsers({
    String? laboratoryId,
    String? doctorId,
    String? employeeId,
    String? token,
  }) async {
    log('Fetching users');

    final query = <String>[];
    if (laboratoryId != null && laboratoryId.isNotEmpty) {
      query.add('laboratoryId=${Uri.encodeQueryComponent(laboratoryId)}');
    }
    if (doctorId != null && doctorId.isNotEmpty) {
      query.add('doctorId=${Uri.encodeQueryComponent(doctorId)}');
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      query.add('employeeId=${Uri.encodeQueryComponent(employeeId)}');
    }

    final responseData = await Api().get(
      url: query.isEmpty ? 'Users' : 'Users?${query.join('&')}',
      token: token,
    );

    log('Users response data: $responseData');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedUsersList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> getUserById({required String id, String? token}) async {
    log('Fetching user by id: $id');

    final responseData = await Api().get(url: 'Users/$id', token: token);

    log('User by id response data: $responseData');

    return UserModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<UserModel> createUser({
    required CreateUserRequestModel createUserRequestBody,
    String? token,
  }) async {
    final body = createUserRequestBody.toJson();

    log('Sending Create User request with: $body');

    final response = await Api().post(url: 'Users', body: body, token: token);

    log('Create User response data: ${response.data}');

    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> updateUser({
    required String id,
    required UpdateUserRequestModel updateUserRequestBody,
    String? token,
  }) async {
    final body = updateUserRequestBody.toJson();

    log('Sending Update User request with: $body');

    final response = await Api().put(
      url: 'Users/$id',
      body: body,
      token: token,
    );

    log('Update User response data: ${response.data}');

    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteUser({required String id, String? token}) async {
    log('Deleting user: $id');

    final response = await Api().delete(url: 'Users/$id', token: token);

    log('Delete User response data: ${response.data}');
  }

  Future<void> activateUser({required String id, String? token}) async {
    log('Activating user: $id');

    final response = await Api().post(
      url: 'Users/$id/activate',
      body: const <String, dynamic>{},
      token: token,
    );

    log('Activate User response data: ${response.data}');
  }

  Future<void> deactivateUser({required String id, String? token}) async {
    log('Deactivating user: $id');

    final response = await Api().post(
      url: 'Users/$id/deactivate',
      body: const <String, dynamic>{},
      token: token,
    );

    log('Deactivate User response data: ${response.data}');
  }

  Future<void> resetUserPassword({
    required String id,
    required String newPassword,
    String? token,
  }) async {
    log('Resetting password for user: $id');

    final response = await Api().post(
      url: 'Users/$id/reset-password',
      body: {'newPassword': newPassword},
      token: token,
    );

    log('Reset User password response data: ${response.data}');
  }

  // ----------------------------------------------------- restoration types ---

  Future<List<RestorationTypeModel>> getRestorationTypes({
    String? token,
  }) async {
    log('Fetching restoration types');

    final responseData = await Api().get(url: 'RestorationTypes', token: token);

    log('Restoration types response data: $responseData');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedRestorationTypesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => RestorationTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /RestorationTypes/lookup?doctorId=&intake=` — the catalog priced
  /// for one doctor (their tier/negotiated/list rate). This is what a
  /// case-creation form must quote from, not the plain list above — quoting
  /// a different total than the invoice charges is the one pricing bug a
  /// lab never forgives.
  ///
  /// [intake] is the `RouteStageAppliesTo` value (2 = traditional, 3 =
  /// digital), not `ImpressionMethod`'s own (1/2) — the caller converts.
  Future<List<DoctorRestorationTypeLookupModel>> getRestorationTypesLookup({
    String? doctorId,
    int? intake,
    String? token,
  }) async {
    log('Fetching doctor-priced restoration types: doctorId=$doctorId');

    final params = <String>[];
    if (doctorId != null && doctorId.isNotEmpty) {
      params.add('doctorId=${Uri.encodeQueryComponent(doctorId)}');
    }
    if (intake != null) params.add('intake=$intake');
    final query = params.isEmpty ? '' : '?${params.join('&')}';

    final responseData = await Api().get(
      url: 'RestorationTypes/lookup$query',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map(
          (e) => DoctorRestorationTypeLookupModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<RestorationTypeModel> createRestorationType({
    required CreateRestorationTypeRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create RestorationType request with: $body');

    final response = await Api().post(
      url: 'RestorationTypes',
      body: body,
      token: token,
    );

    log('Create RestorationType response data: ${response.data}');

    return RestorationTypeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RestorationTypeModel> updateRestorationType({
    required String id,
    required UpdateRestorationTypeRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update RestorationType request with: $body');

    final response = await Api().put(
      url: 'RestorationTypes/$id',
      body: body,
      token: token,
    );

    log('Update RestorationType response data: ${response.data}');

    return RestorationTypeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRestorationType({
    required String id,
    String? token,
  }) async {
    log('Deleting restoration type: $id');

    final response = await Api().delete(
      url: 'RestorationTypes/$id',
      token: token,
    );

    log('Delete RestorationType response data: ${response.data}');
  }

  // ------------------------------------------------------- case priorities ---

  /// [includeInactive] is what the management screen uses — everywhere inside
  /// cases reads the active set, so a retired priority is never offered.
  Future<List<CasePriorityModel>> getCasePriorities({
    bool includeInactive = false,
    String? token,
  }) async {
    log('Fetching case priorities (includeInactive: $includeInactive)');

    final responseData = await Api().get(
      url: 'case-priorities?includeInactive=$includeInactive',
      token: token,
    );

    log('Case priorities response data: $responseData');

    await CacheHelper.saveJson(
      key: includeInactive
          ? CacheKeys.cachedAllCasePrioritiesList
          : CacheKeys.cachedCasePrioritiesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => CasePriorityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CasePriorityModel> createCasePriority({
    required SaveCasePriorityRequestModel saveRequestBody,
    String? token,
  }) async {
    final body = saveRequestBody.toJson();

    log('Sending Create CasePriority request with: $body');

    final response = await Api().post(
      url: 'case-priorities',
      body: body,
      token: token,
    );

    log('Create CasePriority response data: ${response.data}');

    return CasePriorityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CasePriorityModel> updateCasePriority({
    required String id,
    required SaveCasePriorityRequestModel saveRequestBody,
    String? token,
  }) async {
    final body = saveRequestBody.toJson();

    log('Sending Update CasePriority request with: $body');

    final response = await Api().put(
      url: 'case-priorities/$id',
      body: body,
      token: token,
    );

    log('Update CasePriority response data: ${response.data}');

    return CasePriorityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCasePriority({required String id, String? token}) async {
    log('Deleting case priority: $id');

    final response = await Api().delete(
      url: 'case-priorities/$id',
      token: token,
    );

    log('Delete CasePriority response data: ${response.data}');
  }

  /// Creates the lab's starting set of priorities. Only meaningful while the
  /// list is still empty — the API owns what "defaults" means.
  Future<List<CasePriorityModel>> seedDefaultCasePriorities({
    String? token,
  }) async {
    log('Seeding default case priorities');

    final response = await Api().post(
      url: 'case-priorities/seed-defaults',
      body: const <String, dynamic>{},
      token: token,
    );

    log('Seed CasePriorities response data: ${response.data}');

    return (response.data as List<dynamic>)
        .map((e) => CasePriorityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------- priority quotas ---
  //
  // A doctor's own free allowance per priority, overriding the laboratory's
  // default. **One doctor and one priority per call** — there is no bulk
  // endpoint, so handing an allowance to a whole city costs one request per
  // doctor.
  // ---------------------------------------------------------------------

  /// `GET /doctors/{doctorId}/priority-quota`
  Future<DoctorPriorityQuotaModel> getDoctorPriorityQuota({
    required String doctorId,
    String? token,
  }) async {
    log('Fetching priority quota for doctor: $doctorId');

    final data = await Api().get(
      url: 'doctors/$doctorId/priority-quota',
      token: token,
    );

    return DoctorPriorityQuotaModel.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /doctors/{doctorId}/priority-quota/{priorityId}/increase`
  ///
  /// Bumps one doctor's allowance at one level — permanently or for this
  /// period only, free or against an invoice. See
  /// [IncreasePriorityAllowanceRequestModel] for why those are two separate
  /// choices rather than one.
  Future<DoctorPriorityQuotaModel> increaseDoctorPriorityAllowance({
    required String doctorId,
    required String priorityId,
    required IncreasePriorityAllowanceRequestModel body,
    String? token,
  }) async {
    log('Increasing priority $priorityId for doctor $doctorId');

    final response = await Api().post(
      url: 'doctors/$doctorId/priority-quota/$priorityId/increase',
      body: body.toJson(),
      token: token,
    );

    return DoctorPriorityQuotaModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `GET /case-priorities/overview` — every doctor's standing, one query.
  Future<PriorityOverviewModel> getPriorityOverview({
    String? search,
    String? token,
  }) async {
    log('Fetching priority overview');

    final query = search == null || search.isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(search)}';

    final data = await Api().get(
      url: 'case-priorities/overview$query',
      token: token,
    );

    return PriorityOverviewModel.fromJson(
      data as Map<String, dynamic>? ?? const {},
    );
  }

  /// `GET /case-priorities/{id}/allowances` — only the doctors with an
  /// override at this level. The absence of a row means standard terms.
  Future<List<PriorityAllowanceModel>> getPriorityAllowances({
    required String priorityId,
    String? token,
  }) async {
    log('Fetching allowances for priority: $priorityId');

    final data = await Api().get(
      url: 'case-priorities/$priorityId/allowances',
      token: token,
    );

    return _decodeList(data, PriorityAllowanceModel.fromJson);
  }

  /// `PUT /case-priorities/{id}/allowances` — writes one level's terms onto a
  /// set of doctors. Not a replace: doctors not listed keep what they had.
  Future<List<PriorityAllowanceModel>> setPriorityAllowances({
    required String priorityId,
    required BulkSetPriorityAllowanceRequestModel body,
    String? token,
  }) async {
    log('Setting allowances for priority $priorityId');

    final response = await Api().put(
      url: 'case-priorities/$priorityId/allowances',
      body: body.toJson(),
      token: token,
    );

    return _decodeList(response.data, PriorityAllowanceModel.fromJson);
  }

  /// `PUT /doctors/{doctorId}/priority-quota`
  Future<DoctorPriorityQuotaModel> setDoctorPriorityAllowance({
    required String doctorId,
    required SetPriorityAllowanceRequestModel body,
    String? token,
  }) async {
    log('Setting priority allowance for $doctorId: ${body.toJson()}');

    final response = await Api().put(
      url: 'doctors/$doctorId/priority-quota',
      body: body.toJson(),
      token: token,
    );

    return DoctorPriorityQuotaModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // --------------------------------------------------- scanner availability ---

  Future<List<ScannerAvailabilityRuleModel>> getScannerRules({
    String? token,
  }) async {
    log('Fetching scanner availability rules');

    final responseData = await Api().get(
      url: 'scanner-availability/rules',
      token: token,
    );

    log('Scanner rules response data: $responseData');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedScannerRulesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map(
          (e) =>
              ScannerAvailabilityRuleModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ScannerAvailabilityRuleModel> createScannerRule({
    required SaveScannerAvailabilityRuleRequestModel saveRequestBody,
    String? token,
  }) async {
    final body = saveRequestBody.toJson();

    log('Sending Create ScannerRule request with: $body');

    final response = await Api().post(
      url: 'scanner-availability/rules',
      body: body,
      token: token,
    );

    log('Create ScannerRule response data: ${response.data}');

    return ScannerAvailabilityRuleModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ScannerAvailabilityRuleModel> updateScannerRule({
    required String id,
    required SaveScannerAvailabilityRuleRequestModel saveRequestBody,
    String? token,
  }) async {
    final body = saveRequestBody.toJson();

    log('Sending Update ScannerRule request with: $body');

    final response = await Api().put(
      url: 'scanner-availability/rules/$id',
      body: body,
      token: token,
    );

    log('Update ScannerRule response data: ${response.data}');

    return ScannerAvailabilityRuleModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteScannerRule({required String id, String? token}) async {
    log('Deleting scanner rule: $id');

    final response = await Api().delete(
      url: 'scanner-availability/rules/$id',
      token: token,
    );

    log('Delete ScannerRule response data: ${response.data}');
  }

  /// [from] and [to] are `yyyy-MM-dd`; the window is required, since an
  /// unbounded list of date overrides is not something the API offers.
  Future<List<ScannerAvailabilityExceptionModel>> getScannerExceptions({
    required String from,
    required String to,
    String? token,
  }) async {
    log('Fetching scanner exceptions from $from to $to');

    final responseData = await Api().get(
      url: 'scanner-availability/exceptions?from=$from&to=$to',
      token: token,
    );

    log('Scanner exceptions response data: $responseData');

    return (responseData as List<dynamic>)
        .map(
          (e) => ScannerAvailabilityExceptionModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Upserts the exception for its date — the API keys off the date, not an
  /// id, so this both creates and edits.
  Future<ScannerAvailabilityExceptionModel> saveScannerException({
    required SaveScannerAvailabilityExceptionRequestModel saveRequestBody,
    String? token,
  }) async {
    final body = saveRequestBody.toJson();

    log('Sending Save ScannerException request with: $body');

    final response = await Api().put(
      url: 'scanner-availability/exceptions',
      body: body,
      token: token,
    );

    log('Save ScannerException response data: ${response.data}');

    return ScannerAvailabilityExceptionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteScannerException({
    required String id,
    String? token,
  }) async {
    log('Deleting scanner exception: $id');

    final response = await Api().delete(
      url: 'scanner-availability/exceptions/$id',
      token: token,
    );

    log('Delete ScannerException response data: ${response.data}');
  }

  /// The rules and exceptions resolved into concrete days and slots — what the
  /// doctor is offered. Read-only: the lab changes it by changing the rules.
  Future<List<ScannerDayModel>> getScannerCalendar({
    required String from,
    required String to,
    String? token,
  }) async {
    log('Fetching scanner calendar from $from to $to');

    final responseData = await Api().get(
      url: 'scanner-availability/calendar?from=$from&to=$to',
      token: token,
    );

    log('Scanner calendar response data: $responseData');

    return (responseData as List<dynamic>)
        .map((e) => ScannerDayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ----------------------------------------------------------- price tiers ---

  Future<List<PriceTierModel>> getPriceTiers({String? token}) async {
    log('Fetching price tiers');

    final responseData = await Api().get(url: 'PriceTiers', token: token);

    log('Price tiers response data: $responseData');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedPriceTiersList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => PriceTierModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PriceTierModel> getPriceTierById({
    required String id,
    String? token,
  }) async {
    log('Fetching price tier by id: $id');

    final responseData = await Api().get(url: 'PriceTiers/$id', token: token);

    log('Price tier response data: $responseData');

    return PriceTierModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<PriceTierModel> createPriceTier({
    required CreatePriceTierRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create PriceTier request with: $body');

    final response = await Api().post(
      url: 'PriceTiers',
      body: body,
      token: token,
    );

    log('Create PriceTier response data: ${response.data}');

    return PriceTierModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PriceTierModel> updatePriceTier({
    required String id,
    required UpdatePriceTierRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update PriceTier request with: $body');

    final response = await Api().put(
      url: 'PriceTiers/$id',
      body: body,
      token: token,
    );

    log('Update PriceTier response data: ${response.data}');

    return PriceTierModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePriceTier({required String id, String? token}) async {
    log('Deleting price tier: $id');

    final response = await Api().delete(url: 'PriceTiers/$id', token: token);

    log('Delete PriceTier response data: ${response.data}');
  }

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

    log('Patients response data: $responseData');

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

    log('Patient by id response data: $responseData');

    return PatientModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<PatientModel> createPatient({
    required CreatePatientRequestModel createPatientRequestBody,
    String? token,
  }) async {
    final body = createPatientRequestBody.toJson();

    log('Sending Create Patient request with: $body');

    final response = await Api().post(
      url: 'Patients',
      body: body,
      token: token,
    );

    log('Create Patient response data: ${response.data}');

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

    log('Sending Update Patient request with: $body');

    final response = await Api().put(
      url: 'Patients/$id',
      body: body,
      token: token,
    );

    log('Update Patient response data: ${response.data}');

    return PatientModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePatient({required String id, String? token}) async {
    log('Deleting patient: $id');

    final response = await Api().delete(url: 'Patients/$id', token: token);

    log('Delete Patient response data: ${response.data}');
  }

  Future<PriceTierModel> setPriceTierPrices({
    required String id,
    required SetPriceTierPricesRequestModel setPricesRequestBody,
    String? token,
  }) async {
    final body = setPricesRequestBody.toJson();

    log('Sending Set PriceTier prices request with: $body');

    final response = await Api().put(
      url: 'PriceTiers/$id/prices',
      body: body,
      token: token,
    );

    log('Set PriceTier prices response data: ${response.data}');

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

  // ----------------------------------------------------------------- cases ---

  /// [stageIds] narrows to the lab's own workflow stages and is **repeatable**
  /// — which is why the query is built as an ordered list of entries rather
  /// than a map: a map cannot hold `StageIds` twice.
  ///
  /// The date window filters on *reception*, not the due date; the API's old
  /// `DueDateFrom`/`DueDateTo` params are gone and were silently ignored.
  /// The `ClinicCaseFilter` query params shared by `GET /Cases` and
  /// `GET /Reports/cases` — the CSV export takes the same filter shape, so
  /// building it once keeps the two from silently drifting apart.
  static List<MapEntry<String, String>> _caseFilterParams({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    List<String>? stageIds,
    List<String>? restorationStageIds,
    List<String>? overriddenRestorationIds,
    bool matchAnyAssignedStage = false,
    List<String>? laboratoryIds,
    String? receivedFrom,
    String? receivedTo,
    int? phaseTab,
    String? slaParam,
  }) {
    final params = <MapEntry<String, String>>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add(MapEntry(key, value));
      }
    }

    add('Search', search);
    add('DoctorId', doctorId);
    add('ClinicId', clinicId);
    add('PatientId', patientId);
    add('PriorityId', priorityId);
    add('ReceivedFrom', receivedFrom);
    add('ReceivedTo', receivedTo);
    // A field of its own, not folded into `Phase`/`Phases`: those two already
    // carry older meanings the server still honours for callers that never
    // send a tab, and layering a third meaning onto them would need a document
    // to disambiguate which of them a given request meant.
    add('PhaseTab', phaseTab?.toString());
    // Exactly one of IsLate/DueToday/NoExpectedCompletion, and only when the
    // segment is on: the three exclude one another server-side.
    add(slaParam ?? '', slaParam == null ? null : 'true');
    for (final stageId in stageIds ?? const <String>[]) {
      add('StageIds', stageId);
    }
    for (final stageId in restorationStageIds ?? const <String>[]) {
      add('RestorationStageIds', stageId);
    }
    // Specific restorations handed to this login by a temporary override —
    // restoration ids, not stage ids, so they match only that one piece.
    for (final restorationId in overriddenRestorationIds ?? const <String>[]) {
      add('OverriddenCaseRestorationIds', restorationId);
    }
    // "My tasks" means any one of the three matches, not all of them: the
    // server ANDs the stage lists unless told otherwise.
    if (matchAnyAssignedStage) add('MatchAnyAssignedStage', 'true');
    // Repeated key, not a comma-joined list — that is how the endpoint
    // declares its array parameters. Sending none leaves the case list scoped
    // to the `X-Laboratory-Id` header, which is the ordinary single-lab view;
    // the server pins a user without `Branches` to that header regardless.
    for (final laboratoryId in laboratoryIds ?? const <String>[]) {
      add('LaboratoryIds', laboratoryId);
    }

    return params;
  }

  /// [stageIds] narrows to the lab's own workflow stages and is **repeatable**
  /// — which is why the query is built as an ordered list of entries rather
  /// than a map: a map cannot hold `StageIds` twice.
  ///
  /// The date window filters on *reception*, not the due date; the API's old
  /// `DueDateFrom`/`DueDateTo` params are gone and were silently ignored.
  Future<List<CaseListItemModel>> getCases({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    List<String>? stageIds,
    List<String>? restorationStageIds,
    List<String>? overriddenRestorationIds,
    bool matchAnyAssignedStage = false,
    List<String>? laboratoryIds,
    String? receivedFrom,
    String? receivedTo,
    int? phaseTab,
    String? slaParam,
    String? token,
  }) async {
    log('Fetching cases');

    final params = <MapEntry<String, String>>[
      const MapEntry('PageSize', '200'),
      ..._caseFilterParams(
        search: search,
        doctorId: doctorId,
        clinicId: clinicId,
        patientId: patientId,
        priorityId: priorityId,
        stageIds: stageIds,
        restorationStageIds: restorationStageIds,
        overriddenRestorationIds: overriddenRestorationIds,
        matchAnyAssignedStage: matchAnyAssignedStage,
        laboratoryIds: laboratoryIds,
        receivedFrom: receivedFrom,
        receivedTo: receivedTo,
        phaseTab: phaseTab,
        slaParam: slaParam,
      ),
    ];

    final query = params
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final responseData = await Api().get(url: 'Cases?$query', token: token);

    log('Cases response data: $responseData');

    // The endpoint returns a paged result: { items: [...], ... }.
    final items = responseData is Map<String, dynamic>
        ? (responseData['items'] as List<dynamic>? ?? const [])
        : (responseData as List<dynamic>);

    final isUnfiltered =
        search == null &&
        doctorId == null &&
        clinicId == null &&
        patientId == null &&
        priorityId == null &&
        (stageIds == null || stageIds.isEmpty) &&
        (restorationStageIds == null || restorationStageIds.isEmpty) &&
        (overriddenRestorationIds == null ||
            overriddenRestorationIds.isEmpty) &&
        !matchAnyAssignedStage &&
        receivedFrom == null &&
        receivedTo == null &&
        // A tab or an SLA segment narrows the list exactly as a filter does;
        // caching a narrowed page as "the case list" would hand the offline
        // fallback a slice and call it everything.
        phaseTab == null &&
        slaParam == null;
    if (isUnfiltered) {
      await CacheHelper.saveJson(key: CacheKeys.cachedCasesList, value: items);
    }

    return items
        .map((e) => CaseListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /Cases/phase-counts` — how many cases sit behind each lifecycle tab.
  ///
  /// Takes the same filters the list is showing **except** the tab itself:
  /// counting is what this exists to do instead of applying it, so a tab bar
  /// built from it shows the size of every tab, not just the open one.
  Future<CasePhaseCountsModel> getCasePhaseCounts({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    List<String>? stageIds,
    List<String>? restorationStageIds,
    List<String>? overriddenRestorationIds,
    bool matchAnyAssignedStage = false,
    List<String>? laboratoryIds,
    String? receivedFrom,
    String? receivedTo,
    String? slaParam,
    String? token,
  }) async {
    log('Fetching case phase counts');

    final params = _caseFilterParams(
      search: search,
      doctorId: doctorId,
      clinicId: clinicId,
      patientId: patientId,
      priorityId: priorityId,
      stageIds: stageIds,
      restorationStageIds: restorationStageIds,
      overriddenRestorationIds: overriddenRestorationIds,
      matchAnyAssignedStage: matchAnyAssignedStage,
      laboratoryIds: laboratoryIds,
      receivedFrom: receivedFrom,
      receivedTo: receivedTo,
      slaParam: slaParam,
    );
    final query = params
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final responseData = await Api().get(
      url: 'Cases/phase-counts${query.isEmpty ? '' : '?$query'}',
      token: token,
    );

    return CasePhaseCountsModel.fromJson(
      responseData as Map<String, dynamic>? ?? const {},
    );
  }

  /// `GET /Cases/sla-counts` — the three date badges, under the same filters
  /// the list is showing except the SLA segment itself and the phase tab.
  Future<CaseSlaCountsModel> getCaseSlaCounts({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    List<String>? stageIds,
    List<String>? restorationStageIds,
    List<String>? overriddenRestorationIds,
    bool matchAnyAssignedStage = false,
    List<String>? laboratoryIds,
    String? receivedFrom,
    String? receivedTo,
    String? token,
  }) async {
    log('Fetching case SLA counts');

    final params = _caseFilterParams(
      search: search,
      doctorId: doctorId,
      clinicId: clinicId,
      patientId: patientId,
      priorityId: priorityId,
      stageIds: stageIds,
      restorationStageIds: restorationStageIds,
      overriddenRestorationIds: overriddenRestorationIds,
      matchAnyAssignedStage: matchAnyAssignedStage,
      laboratoryIds: laboratoryIds,
      receivedFrom: receivedFrom,
      receivedTo: receivedTo,
    );
    final query = params
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final responseData = await Api().get(
      url: 'Cases/sla-counts${query.isEmpty ? '' : '?$query'}',
      token: token,
    );

    return CaseSlaCountsModel.fromJson(
      responseData as Map<String, dynamic>? ?? const {},
    );
  }

  /// `GET /Cases/my-workflow-assignments` — the stages this login may act on.
  ///
  /// Server-resolved: it is the union of being named personally and belonging
  /// to a department the stage lists, through the employee's *active*
  /// membership spell — none of which the client holds.
  Future<MyWorkflowAssignmentsModel> getMyWorkflowAssignments({
    String? token,
  }) async {
    log('Fetching my workflow assignments');

    final responseData = await Api().get(
      url: 'Cases/my-workflow-assignments',
      token: token,
    );

    return MyWorkflowAssignmentsModel.fromJson(
      responseData as Map<String, dynamic>? ?? const {},
    );
  }

  /// `GET /Reports/cases` — the case list as a CSV file, filtered the same
  /// way `GET /Cases` is. Raw bytes: goes through [Api.dio] directly, the
  /// same as [downloadInvoicePdf], since [Api.get] only ever decodes JSON.
  Future<List<int>> exportCasesCsv({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    List<String>? stageIds,
    List<String>? laboratoryIds,
    String? receivedFrom,
    String? receivedTo,
    String? token,
  }) async {
    log('Exporting cases CSV');

    final params = _caseFilterParams(
      search: search,
      doctorId: doctorId,
      clinicId: clinicId,
      patientId: patientId,
      priorityId: priorityId,
      stageIds: stageIds,
      laboratoryIds: laboratoryIds,
      receivedFrom: receivedFrom,
      receivedTo: receivedTo,
    );
    final query = params
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final response = await Api.dio.get<List<int>>(
      'Reports/cases${query.isEmpty ? '' : '?$query'}',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );

    return response.data ?? const [];
  }

  /// `GET /Reports/cases/{id}/pdf` — raw bytes, same pattern as
  /// [downloadInvoicePdf].
  Future<List<int>> downloadCasePdf({required String id, String? token}) async {
    log('Downloading case PDF: $id');

    final response = await Api.dio.get<List<int>>(
      'Reports/cases/$id/pdf',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );

    return response.data ?? const [];
  }

  // ------------------------------------------------------ case workflow ---

  /// The laboratory's case-stage catalogue — what replaced the old fixed
  /// `CaseStatus` enum.
  Future<List<CaseStageModel>> getCaseStages({String? token}) async {
    log('Fetching case stages');

    final responseData = await Api().get(url: 'case-statuses', token: token);

    log('Case stages response data: $responseData');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedCaseStagesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => CaseStageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CaseDetailModel> getCaseById({
    required String id,
    String? token,
  }) async {
    log('Fetching case by id: $id');

    final responseData = await Api().get(url: 'Cases/$id', token: token);

    log('Case by id response data: $responseData');

    return CaseDetailModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// `GET /Cases/expected-completion-preview` — what the draft would promise.
  ///
  /// Computed by the same code that will date the case at creation, including
  /// the fallback to a slower priority level when the chosen one has no
  /// duration configured — a rule the client cannot see from the catalogue, so
  /// a figure worked out here would quietly disagree with the case once filed.
  ///
  /// Null means no restoration type on the draft has any duration at all:
  /// nothing to promise, not a blank to fill in.
  Future<DateTime?> getExpectedCompletionPreview({
    String? priorityId,
    List<String> restorationTypeIds = const [],
    String? token,
  }) async {
    log(
      'Previewing expected completion for ${restorationTypeIds.length} types',
    );

    final params = <String>[
      if (priorityId != null && priorityId.isNotEmpty)
        'priorityId=${Uri.encodeQueryComponent(priorityId)}',
      for (final id in restorationTypeIds)
        'restorationTypeIds=${Uri.encodeQueryComponent(id)}',
    ];

    final responseData = await Api().get(
      url:
          'Cases/expected-completion-preview${params.isEmpty ? '' : '?${params.join('&')}'}',
      token: token,
    );

    final map = responseData as Map<String, dynamic>?;
    return DateTime.tryParse(map?['expectedCompletionAt'] as String? ?? '');
  }

  /// `GET /Cases/{id}/flow` — the whole lifecycle, assembled by the server.
  ///
  /// The six fixed checkpoints, and nested under `InProduction` the case's own
  /// stages, every restoration's own route, and the stages that wait for all
  /// of them — each node already carrying whether it is done, current, pending
  /// or skipped. Nothing here is recomputed on the client: the plan a case
  /// travels is frozen when the case is created, so walking the restoration
  /// type's live catalogue instead would draw the wrong board for any case in
  /// flight when a lab edits a route.
  Future<CaseFlowModel> getCaseFlow({required String id, String? token}) async {
    log('Fetching flow for case: $id');

    final responseData = await Api().get(url: 'Cases/$id/flow', token: token);

    return CaseFlowModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// `GET /Cases/by-number/{caseNumber}` — resolves a scanned case barcode.
  Future<CaseDetailModel> getCaseByNumber({
    required String caseNumber,
    String? token,
  }) async {
    log('Fetching case by number: $caseNumber');

    final responseData = await Api().get(
      url: 'Cases/by-number/${Uri.encodeComponent(caseNumber)}',
      token: token,
    );

    return CaseDetailModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// `GET /Cases/restorations/by-number/{restorationNumber}` — resolves a
  /// scanned restoration barcode. Answers with the whole case, plus which
  /// restoration on it was scanned.
  Future<ScannedRestorationModel> getRestorationByNumber({
    required String restorationNumber,
    String? token,
  }) async {
    log('Fetching restoration by number: $restorationNumber');

    final responseData = await Api().get(
      url:
          'Cases/restorations/by-number/'
          '${Uri.encodeComponent(restorationNumber)}',
      token: token,
    );

    return ScannedRestorationModel.fromJson(
      responseData as Map<String, dynamic>,
    );
  }

  /// `GET /Cases/{id}/print-ticket` — the thermal ticket's data, including the
  /// `qrPayload` the case's own barcode encodes.
  Future<CasePrintTicketModel> getCasePrintTicket({
    required String id,
    String? token,
  }) async {
    log('Fetching print ticket for case: $id');

    final responseData = await Api().get(
      url: 'Cases/$id/print-ticket',
      token: token,
    );

    return CasePrintTicketModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<CaseDetailModel> createCase({
    required CreateCaseRequestModel createCaseRequestBody,
    String? token,
  }) async {
    final body = createCaseRequestBody.toJson();

    log('Sending Create Case request with: $body');

    final response = await Api().post(url: 'Cases', body: body, token: token);

    log('Create Case response data: ${response.data}');

    return CaseDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCase({required String id, String? token}) async {
    log('Deleting case: $id');

    final response = await Api().delete(url: 'Cases/$id', token: token);

    log('Delete Case response data: ${response.data}');
  }

  Future<void> setRestorationStage({
    required String caseId,
    required String restorationId,
    required String stageId,
    String? note,
    SendBackReason reason = const SendBackReason(),
    String? token,
  }) async {
    log('Setting stage $stageId for restoration $restorationId (case $caseId)');

    final response = await Api().put(
      url: 'Cases/$caseId/restorations/$restorationId/stage',
      // The reason only matters on a send-back; a forward move sends none.
      body: {'stageId': stageId, 'note': note, ...reason.toJson()},
      token: token,
    );

    log('Set Restoration stage response data: ${response.data}');
  }

  /// Moves the case to another of the lab's workflow stages.
  ///
  /// [caseStatusId] is the id of a stage, not an enum member. The target must
  /// be reachable by an edge from where the case is — the server enforces
  /// that, and it also refuses any hand-move across production for everyone,
  /// admins included.
  ///
  /// Returns nothing: the response shape is not contracted, and the caller
  /// refetches the case anyway.
  Future<void> moveCaseStage({
    required String id,
    required String caseStatusId,
    String? note,
    String? rejectionReason,
    String? token,
  }) async {
    log('Moving case $id to stage $caseStatusId');

    final response = await Api().put(
      url: 'Cases/$id/status',
      body: {
        'caseStatusId': caseStatusId,
        'note': note,
        'rejectionReason': rejectionReason,
      },
      token: token,
    );

    log('Move case stage response data: ${response.data}');
  }

  /// `PUT /Cases/{id}/restorations/{restorationId}/stage/reject`
  ///
  /// Declines a proposed move: the piece stays exactly where it is, and the
  /// refusal — with the stage that was attempted — is written to its history,
  /// so the timeline shows what was asked for as well as what happened.
  Future<void> rejectRestorationStage({
    required String caseId,
    required String restorationId,
    required String attemptedStageId,
    required String reason,
    String? token,
  }) async {
    log('Rejecting stage $attemptedStageId for restoration $restorationId');

    await Api().put(
      url: 'Cases/$caseId/restorations/$restorationId/stage/reject',
      body: {'attemptedStageId': attemptedStageId, 'reason': reason},
      token: token,
    );
  }

  /// `GET /Cases/{id}/restorations/{restorationId}/forward-targets`
  ///
  /// Where a piece may be sent **next**. Server-driven for the same reason the
  /// rework list is: the next step is the stage's declared `nextStageId`, or
  /// the following position in the frozen plan's order — and with parallel
  /// steps there can be more than one. A client walking the type's live route
  /// gets both of those wrong the moment a lab edits the route mid-case.
  Future<List<CaseWorkflowStageModel>> getForwardTargets({
    required String caseId,
    required String restorationId,
    String? token,
  }) async {
    log('Fetching forward targets for restoration $restorationId');

    final data = await Api().get(
      url: 'Cases/$caseId/restorations/$restorationId/forward-targets',
      token: token,
    );

    return _decodeList(data, CaseWorkflowStageModel.fromJson);
  }

  // ---- CasePhase checkpoints -------------------------------------------

  /// `GET /Cases/{id}/restorations/{restorationId}/rework-targets`
  ///
  /// Where a rejected piece may be sent back to. Server-driven: it is the
  /// stage's declared `sendBackToStageId`, or every earlier stage when none
  /// was declared, and the rules behind that are the server's.
  Future<List<CaseWorkflowStageModel>> getReworkTargets({
    required String caseId,
    required String restorationId,
    String? token,
  }) async {
    log('Fetching rework targets for restoration $restorationId');

    final data = await Api().get(
      url: 'Cases/$caseId/restorations/$restorationId/rework-targets',
      token: token,
    );

    return _decodeList(data, CaseWorkflowStageModel.fromJson);
  }
  //
  // The fixed six-value lifecycle (New → Received → InProduction →
  // QualityCheck → Ready → Delivered) is not lab-drawn and is not moved by
  // picking a stage: each step past it is its own action. A case sitting in
  // `New` has no stage moves on offer at all — recording the material is what
  // opens its workflow, which is why the pre-production stages looked stuck.

  /// `PUT /Cases/{id}/material-received`
  Future<void> receiveCaseMaterial({
    required String id,
    String? note,
    String? token,
  }) async {
    log('Recording material received for case $id');

    await Api().put(
      url: 'Cases/$id/material-received',
      body: {'note': note},
      token: token,
    );
  }

  /// `PUT /Cases/{id}/material-received/undo`
  ///
  /// Takes the case back to `New`. The escape hatch for the front desk
  /// recording an arrival against the wrong case — which happens, and which
  /// without this leaves the case in a phase nothing can walk back.
  Future<void> undoCaseMaterialReceived({
    required String id,
    String? token,
  }) async {
    log('Undoing material received for case $id');

    await Api().put(
      url: 'Cases/$id/material-received/undo',
      body: const <String, dynamic>{},
      token: token,
    );
  }

  /// `PUT /Cases/{id}/quality-check/pass`
  Future<void> passCaseQualityCheck({
    required String id,
    String? note,
    String? token,
  }) async {
    log('Passing quality check for case $id');

    await Api().put(
      url: 'Cases/$id/quality-check/pass',
      body: {'note': note},
      token: token,
    );
  }

  /// `PUT /Cases/{id}/trying/approve`
  Future<void> approveCaseTrying({
    required String id,
    String? note,
    String? token,
  }) async {
    log('Approving trying for case $id');

    await Api().put(
      url: 'Cases/$id/trying/approve',
      body: {'note': note},
      token: token,
    );
  }

  /// `PUT /Cases/deliver-directly` — "تم التسليم" for many cases at once.
  ///
  /// Each case is walked through every remaining step of its route on its
  /// own; one refusing does not stop the others, so the answer is a row per
  /// case rather than one success or failure.
  Future<List<DeliverDirectlyResultModel>> deliverCasesDirectly({
    required List<String> caseIds,
    String? note,
    String? token,
  }) async {
    log('Delivering ${caseIds.length} cases directly');

    final response = await Api().put(
      url: 'Cases/deliver-directly',
      body: {'caseIds': caseIds, 'note': note},
      token: token,
    );
    final data = response.data;
    if (data is! List) return const [];
    return [
      for (final row in data)
        if (row is Map<String, dynamic>)
          DeliverDirectlyResultModel.fromJson(row),
    ];
  }

  /// `PUT /Cases/{id}/deliver-directly` — the single-case twin, which also
  /// records how the work leaves the lab.
  ///
  /// Returns nothing: the caller refetches the case anyway.
  Future<void> deliverCaseDirectly({
    required String id,
    String? note,
    CollectionMethod collectionMethod = CollectionMethod.none,
    String? token,
  }) async {
    log('Delivering case $id directly');

    await Api().put(
      url: 'Cases/$id/deliver-directly',
      body: {'note': note, 'collectionMethod': collectionMethod.value},
      token: token,
    );
  }

  /// `PUT /Cases/{id}/trying/reject`
  ///
  /// The other half of trying: the doctor refused the fit. Each flagged piece
  /// names the stage it goes back to and may carry its own note, and the case
  /// itself drops back into production — so this is one request, not a reject
  /// per restoration followed by a case move.
  Future<void> rejectCaseTrying({
    required String id,
    required List<TryingRejectLine> restorations,
    String? note,
    String? token,
  }) async {
    log('Rejecting trying for case $id (${restorations.length} restorations)');

    await Api().put(
      url: 'Cases/$id/trying/reject',
      body: {
        'note': note,
        'restorations': [
          for (final restoration in restorations) restoration.toJson(),
        ],
      },
      token: token,
    );
  }

  /// `PUT /Cases/{id}/delay-reason`
  Future<void> setCaseDelayReason({
    required String id,
    required String reason,
    String? note,
    String? token,
  }) async {
    log('Recording a delay reason for case $id');

    await Api().put(
      url: 'Cases/$id/delay-reason',
      body: {'reason': reason, 'note': note},
      token: token,
    );
  }

  Future<CaseFileModel> uploadCaseFile({
    required String id,
    required String filePath,
    String? token,
  }) async {
    log('Uploading file for case: $id');

    final formData = FormData.fromMap({
      'Id': id,
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await Api().post(
      url: 'Cases/$id/files',
      body: formData,
      isFormData: true,
      token: token,
    );

    log('Upload Case file response data: ${response.data}');

    return CaseFileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CaseMessageModel>> getCaseMessages({
    required String id,
    String? token,
  }) async {
    log('Fetching messages for case: $id');

    final responseData = await Api().get(
      url: 'Cases/$id/messages',
      token: token,
    );

    log('Case messages response data: $responseData');

    return (responseData as List<dynamic>)
        .map((e) => CaseMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CaseMessageModel> sendCaseMessage({
    required String id,
    String? message,
    String? replyToMessageId,
    String? filePath,
    String? token,
  }) async {
    log('Sending message for case: $id');

    final formData = FormData.fromMap({
      'Message': ?message,
      'ReplyToMessageId': ?replyToMessageId,
      if (filePath != null) 'File': await MultipartFile.fromFile(filePath),
    });

    final response = await Api().post(
      url: 'Cases/$id/messages',
      body: formData,
      isFormData: true,
      token: token,
    );

    log('Send Case message response data: ${response.data}');

    return CaseMessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /Cases/{id}/messages/{messageId}` — the API allows this for an
  /// admin or the message's own sender, and rejects anyone else.
  Future<void> deleteCaseMessage({
    required String id,
    required String messageId,
    String? token,
  }) async {
    log('Deleting message $messageId for case: $id');

    final response = await Api().delete(
      url: 'Cases/$id/messages/$messageId',
      token: token,
    );

    log('Delete Case message response data: ${response.data}');
  }

  Future<void> deleteCaseFile({
    required String id,
    required String fileId,
    String? token,
  }) async {
    log('Deleting file $fileId for case: $id');

    final response = await Api().delete(
      url: 'Cases/$id/files/$fileId',
      token: token,
    );

    log('Delete Case file response data: ${response.data}');
  }

  // ---------------------------------------------------------------------
  // Case workflow editing (MOBILE-SPEC §15.5b)
  // ---------------------------------------------------------------------

  /// `POST /case-statuses`
  Future<CaseStageModel> createCaseStage({
    required SaveCaseStageRequestModel body,
    String? token,
  }) async {
    log('Creating case stage: ${body.toJson()}');

    final response = await Api().post(
      url: 'case-statuses',
      body: body.toJson(),
      token: token,
    );

    return CaseStageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PUT /case-statuses/{id}`
  Future<CaseStageModel> updateCaseStage({
    required String id,
    required SaveCaseStageRequestModel body,
    String? token,
  }) async {
    log('Updating case stage $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'case-statuses/$id',
      body: body.toJson(),
      token: token,
    );

    return CaseStageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /case-statuses/{id}`
  Future<void> deleteCaseStage({required String id, String? token}) async {
    log('Deleting case stage: $id');

    await Api().delete(url: 'case-statuses/$id', token: token);
  }

  /// `GET /case-statuses/optional` — the stages a case may skip.
  ///
  /// Narrowed by [intake] where given: a route carries a traditional head and
  /// a digital head, and the optional steps of one are not offered on the
  /// other.
  Future<List<CaseStageModel>> getOptionalCaseStages({
    int? intake,
    String? token,
  }) async {
    log('Fetching optional case stages');

    final responseData = await Api().get(
      url: 'case-statuses/optional${intake == null ? '' : '?intake=$intake'}',
      token: token,
    );

    return _decodeList(responseData, CaseStageModel.fromJson);
  }

  /// `PUT /case-statuses/{id}/assignments` — who staffs this stage.
  ///
  /// A separate, smaller request than the full save on purpose: staffing is
  /// edited constantly and by different people than the ones who draw the
  /// workflow, and pushing it through the whole-status body would make every
  /// roster change a chance to clobber the rules.
  ///
  /// Each list **replaces** its set when present; passing null leaves that
  /// side alone. [userIds] are logins, not employee ids.
  Future<CaseStageModel> setCaseStageAssignments({
    required String id,
    List<String>? departmentIds,
    List<String>? userIds,
    String? token,
  }) async {
    log('Setting assignments for case status: $id');

    final response = await Api().put(
      url: 'case-statuses/$id/assignments',
      body: {'departmentIds': departmentIds, 'userIds': userIds},
      token: token,
    );

    return CaseStageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /case-statuses/validate` — the defects that make a case silently
  /// stop, computed server-side against the drawn flow.
  Future<List<RouteProblemModel>> validateCaseStatuses({String? token}) async {
    log('Validating case-status workflow');

    final responseData = await Api().get(
      url: 'case-statuses/validate',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => RouteProblemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /case-statuses/seed-defaults` — idempotent starter workflow.
  Future<void> seedDefaultCaseStages({String? token}) async {
    log('Seeding default case stages');

    await Api().post(
      url: 'case-statuses/seed-defaults',
      body: const {},
      token: token,
    );
  }

  // ---------------------------------------------------------------------
  // Restoration route stages (`/restoration-type-stages`). Renamed server-side
  // from `/CaseWorkflowStages`, which now 404s — the old path is what made the
  // restoration-route screen fail to open at all.
  //
  // A different catalogue from `/case-statuses`: these are the manufacturing
  // stages of one restoration *type's* route, and they carry the concern only
  // production has — a checkpoint that may reject. `appliesTo` is the one
  // gate left that decides whether a stage is cut onto a given case at all;
  // per-priority durations moved to the restoration type itself.
  // ---------------------------------------------------------------------

  /// `GET /restoration-type-stages`
  Future<List<CaseWorkflowStageModel>> getWorkflowStages({
    String? restorationTypeId,
    String? token,
  }) async {
    log('Fetching workflow stages for type: $restorationTypeId');

    final query = restorationTypeId == null || restorationTypeId.isEmpty
        ? ''
        : '?restorationTypeId=${Uri.encodeQueryComponent(restorationTypeId)}';

    final data = await Api().get(
      url: 'restoration-type-stages$query',
      token: token,
    );

    return _decodeList(data, CaseWorkflowStageModel.fromJson);
  }

  /// `GET /restoration-type-stages/next` — the step that follows
  /// [currentStageId] on this type's route.
  ///
  /// A **list**, not one stage: stages sharing an `order` run in parallel, so
  /// the next step can hold several. The server resolves it the same way the
  /// stage-move endpoint does (honouring any `nextStageId` override), which is
  /// why the move must be aimed with this rather than with arithmetic on
  /// `order` — the client would disagree with the server the moment a lab
  /// declares a forward override.
  ///
  /// An empty list means the restoration is at the end of its route.
  Future<List<CaseWorkflowStageModel>> getNextRestorationStages({
    required String restorationTypeId,
    String? currentStageId,
    ImpressionMethod? intake,
    String? token,
  }) async {
    log('Fetching next stage after $currentStageId on type $restorationTypeId');

    final params = <String>[
      'restorationTypeId=${Uri.encodeQueryComponent(restorationTypeId)}',
      if (currentStageId != null && currentStageId.isNotEmpty)
        'currentStageId=${Uri.encodeQueryComponent(currentStageId)}',
      // The route carries a traditional head and a digital head; without the
      // intake the server cannot tell which one this case is running.
      if (intake != null)
        'intake=${intake == ImpressionMethod.digital ? RouteStageAppliesTo.digitalOnly.value : RouteStageAppliesTo.traditionalOnly.value}',
    ];

    final data = await Api().get(
      url: 'restoration-type-stages/next?${params.join('&')}',
      token: token,
    );

    return _decodeList(data, CaseWorkflowStageModel.fromJson);
  }

  /// `POST /restoration-type-stages`
  Future<CaseWorkflowStageModel> createWorkflowStage({
    required CreateWorkflowStageRequestModel body,
    String? token,
  }) async {
    log('Creating workflow stage: ${body.toJson()}');

    final response = await Api().post(
      url: 'restoration-type-stages',
      body: body.toJson(),
      token: token,
    );

    return CaseWorkflowStageModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `PUT /restoration-type-stages/{id}`
  Future<CaseWorkflowStageModel> updateWorkflowStage({
    required String id,
    required UpdateWorkflowStageRequestModel body,
    String? token,
  }) async {
    log('Updating workflow stage $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'restoration-type-stages/$id',
      body: body.toJson(),
      token: token,
    );

    return CaseWorkflowStageModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `GET /routing/routes/{restorationTypeId}` — the route's stages and the
  /// server's own live verdict on whether it runs.
  Future<RouteDefinitionModel> getRouteDefinition({
    required String restorationTypeId,
    String? token,
  }) async {
    log('Fetching route definition for $restorationTypeId');

    final data = await Api().get(
      url: 'routing/routes/$restorationTypeId',
      token: token,
    );

    return RouteDefinitionModel.fromJson(data as Map<String, dynamic>);
  }

  /// `DELETE /restoration-type-stages/{id}`
  Future<void> deleteWorkflowStage({required String id, String? token}) async {
    log('Deleting workflow stage: $id');

    await Api().delete(url: 'restoration-type-stages/$id', token: token);
  }

  // ---------------------------------------------------------------------
  // Departments (`/Departments`)
  //
  // The bridge between the org chart and the routes: a department holds the
  // people, and it holds the restoration stages those people work. A stage set
  // to "assign to a department" has nothing to name without these.
  // ---------------------------------------------------------------------

  /// `GET /Departments`
  Future<List<DepartmentModel>> getDepartments({
    bool includeInactive = false,
    String? token,
  }) async {
    log('Fetching departments (includeInactive: $includeInactive)');

    final data = await Api().get(
      url: 'Departments?includeInactive=$includeInactive',
      token: token,
    );

    return _decodeList(data, DepartmentModel.fromJson);
  }

  /// `GET /Departments/{id}`
  Future<DepartmentModel> getDepartment({
    required String id,
    String? token,
  }) async {
    log('Fetching department: $id');

    final data = await Api().get(url: 'Departments/$id', token: token);

    return DepartmentModel.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /Departments`
  Future<DepartmentModel> createDepartment({
    required SaveDepartmentRequestModel body,
    String? token,
  }) async {
    log('Creating department: ${body.toJson()}');

    final response = await Api().post(
      url: 'Departments',
      body: body.toJson(),
      token: token,
    );

    return DepartmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PUT /Departments/{id}`
  Future<DepartmentModel> updateDepartment({
    required String id,
    required SaveDepartmentRequestModel body,
    String? token,
  }) async {
    log('Updating department $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'Departments/$id',
      body: body.toJson(),
      token: token,
    );

    return DepartmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /Departments/{id}` — frees the department's stages rather than
  /// deleting them, per the endpoint's own description.
  Future<void> deleteDepartment({required String id, String? token}) async {
    log('Deleting department: $id');

    await Api().delete(url: 'Departments/$id', token: token);
  }

  // ---------------------------------------------------------------------
  // Scanner sessions (MOBILE-SPEC §15.6)
  // ---------------------------------------------------------------------

  /// `GET /scanner-sessions` — the dispatcher's queue.
  Future<List<ScannerSessionModel>> getScannerSessions({
    ScannerSessionFiltersModel filters = ScannerSessionFiltersModel.empty,
    String? token,
  }) async {
    log('Fetching scanner sessions');

    final params = <MapEntry<String, String>>[
      const MapEntry('PageSize', '200'),
    ];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add(MapEntry(key, value));
      }
    }

    add('Search', filters.search);
    add('DoctorId', filters.doctorId);
    add('ZoneId', filters.zoneId);
    add('RepresentativeUserId', filters.representativeUserId);
    add('Status', filters.status?.value.toString());
    add('ReviewStatus', filters.reviewStatus?.value.toString());
    add(
      'RepresentativeResponse',
      filters.representativeResponse?.value.toString(),
    );
    add('DateFrom', filters.dateFrom?.toIso8601String());
    add('DateTo', filters.dateTo?.toIso8601String());

    final query = params
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final responseData = await Api().get(
      url: 'scanner-sessions?$query',
      token: token,
    );

    final items = responseData is Map<String, dynamic>
        ? (responseData['items'] as List<dynamic>? ?? const [])
        : (responseData as List<dynamic>? ?? const []);

    return items
        .whereType<Map<String, dynamic>>()
        .map(ScannerSessionModel.fromJson)
        .toList();
  }

  /// `GET /scanner-sessions/{id}`
  Future<ScannerSessionModel> getScannerSessionById({
    required String id,
    String? token,
  }) async {
    log('Fetching scanner session: $id');

    final data = await Api().get(url: 'scanner-sessions/$id', token: token);

    return ScannerSessionModel.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /scanner-sessions/{id}/eligible-representatives` — who could take
  /// this session, per the doctor's zone.
  Future<List<ZoneRepresentativeModel>> getEligibleRepresentatives({
    required String id,
    String? token,
  }) async {
    log('Fetching eligible representatives for session $id');

    final data = await Api().get(
      url: 'scanner-sessions/$id/eligible-representatives',
      token: token,
    );

    return _decodeList(data, ZoneRepresentativeModel.fromJson);
  }

  /// `PUT /scanner-sessions/{id}/representative` — assign, reassign, or clear.
  Future<ScannerSessionModel> assignRepresentative({
    required String id,
    required AssignRepresentativeRequestModel body,
    String? token,
  }) async {
    log('Assigning representative on session $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'scanner-sessions/$id/representative',
      body: body.toJson(),
      token: token,
    );

    return ScannerSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PUT /scanner-sessions/{id}/status`
  Future<ScannerSessionModel> setScannerSessionStatus({
    required String id,
    required SetScannerSessionStatusRequestModel body,
    String? token,
  }) async {
    log('Setting scanner session $id status: ${body.toJson()}');

    final response = await Api().put(
      url: 'scanner-sessions/$id/status',
      body: body.toJson(),
      token: token,
    );

    return ScannerSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Dashboard
  //
  // Eight read-only endpoints, all scoped to the active laboratory by the
  // `X-Laboratory-Id` header the Api interceptor already injects. Each is
  // fetched independently so one slow or failing section cannot blank the
  // whole home screen — see `DashboardCubit`.
  // ---------------------------------------------------------------------

  /// Decodes a JSON array response into models, tolerating a `null` body.
  List<T> _decodeList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  /// `GET /Dashboard/summary`
  Future<DashboardSummaryModel> getDashboardSummary({String? token}) async {
    log('Fetching dashboard summary');

    final data = await Api().get(url: 'Dashboard/summary', token: token);

    return DashboardSummaryModel.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /Dashboard/cases-by-priority`
  Future<List<CasePriorityCountModel>> getDashboardCasesByPriority({
    String? token,
  }) async {
    log('Fetching dashboard cases by priority');

    final data = await Api().get(
      url: 'Dashboard/cases-by-priority',
      token: token,
    );

    return _decodeList(data, CasePriorityCountModel.fromJson);
  }

  /// `GET /Dashboard/cases-by-stage`
  Future<List<CaseStageCountModel>> getDashboardCasesByStage({
    String? token,
  }) async {
    log('Fetching dashboard cases by stage');

    final data = await Api().get(url: 'Dashboard/cases-by-stage', token: token);

    return _decodeList(data, CaseStageCountModel.fromJson);
  }

  /// `GET /Dashboard/cases-by-phase` — the funnel that reconciles.
  ///
  /// Unlike the stage counts, every case is in exactly one phase, so this
  /// column sums to the laboratory's total. See [CasePhaseCountModel].
  Future<List<CasePhaseCountModel>> getDashboardCasesByPhase({
    String? token,
  }) async {
    log('Fetching dashboard cases by phase');

    final data = await Api().get(url: 'Dashboard/cases-by-phase', token: token);

    return _decodeList(data, CasePhaseCountModel.fromJson);
  }

  /// `GET /Dashboard/case-flow` — arrivals against deliveries, per day.
  Future<List<CaseFlowPointModel>> getDashboardCaseFlow({
    int? days,
    String? token,
  }) async {
    log('Fetching dashboard case flow');

    final data = await Api().get(
      url: 'Dashboard/case-flow${days == null ? '' : '?days=$days'}',
      token: token,
    );

    return _decodeList(data, CaseFlowPointModel.fromJson);
  }

  /// `GET /Dashboard/user-case-work` — what each user actually moved.
  Future<List<UserCaseWorkModel>> getDashboardUserCaseWork({
    DateTime? fromDate,
    DateTime? toDate,
    String? token,
  }) async {
    log('Fetching dashboard user case work');

    final params = <String>[
      if (fromDate != null) 'fromDate=${ApiTime.formatDate(fromDate)}',
      if (toDate != null) 'toDate=${ApiTime.formatDate(toDate)}',
    ];

    final data = await Api().get(
      url:
          'Dashboard/user-case-work${params.isEmpty ? '' : '?${params.join('&')}'}',
      token: token,
    );

    return _decodeList(data, UserCaseWorkModel.fromJson);
  }

  /// `GET /Dashboard/revenue-by-month`
  Future<List<MonthlyRevenueModel>> getDashboardRevenueByMonth({
    int? months,
    String? token,
  }) async {
    log('Fetching dashboard revenue by month');

    final query = months == null ? '' : '?months=$months';
    final data = await Api().get(
      url: 'Dashboard/revenue-by-month$query',
      token: token,
    );

    return _decodeList(data, MonthlyRevenueModel.fromJson);
  }

  /// `GET /Dashboard/recent-cases` — returns a paged result whose rows are the
  /// same `ClinicCaseListItemDto` the cases list uses, so it reuses
  /// [CaseListItemModel] rather than introducing a near-duplicate model.
  Future<List<CaseListItemModel>> getDashboardRecentCases({
    int? count,
    String? token,
  }) async {
    log('Fetching dashboard recent cases');

    final query = count == null ? '' : '?count=$count';
    final data = await Api().get(
      url: 'Dashboard/recent-cases$query',
      token: token,
    );

    final items = data is Map<String, dynamic> ? data['items'] : data;

    return _decodeList(items, CaseListItemModel.fromJson);
  }

  /// `GET /Dashboard/top-doctors`
  Future<List<TopDoctorModel>> getDashboardTopDoctors({
    int? count,
    String? token,
  }) async {
    log('Fetching dashboard top doctors');

    final query = count == null ? '' : '?count=$count';
    final data = await Api().get(
      url: 'Dashboard/top-doctors$query',
      token: token,
    );

    return _decodeList(data, TopDoctorModel.fromJson);
  }

  /// `GET /Dashboard/upcoming-due-cases`
  Future<List<UpcomingDueCaseModel>> getDashboardUpcomingDueCases({
    int? days,
    String? token,
  }) async {
    log('Fetching dashboard upcoming due cases');

    final query = days == null ? '' : '?days=$days';
    final data = await Api().get(
      url: 'Dashboard/upcoming-due-cases$query',
      token: token,
    );

    return _decodeList(data, UpcomingDueCaseModel.fromJson);
  }

  /// `GET /Dashboard/recent-activity`
  Future<List<RecentActivityModel>> getDashboardRecentActivity({
    int? count,
    String? token,
  }) async {
    log('Fetching dashboard recent activity');

    final query = count == null ? '' : '?count=$count';
    final data = await Api().get(
      url: 'Dashboard/recent-activity$query',
      token: token,
    );

    return _decodeList(data, RecentActivityModel.fromJson);
  }

  // ---------------------------------------------------------- notifications ---

  /// `POST /Notifications/device-token`.
  ///
  /// The server side of this is not confirmed working yet — callers must
  /// treat a failure here as non-fatal (log it, do not surface it to the
  /// user), since push simply won't arrive until it is, but nothing else in
  /// the app depends on it.
  Future<void> registerDeviceToken({
    required String deviceToken,
    required DevicePlatform platform,
    String? token,
  }) async {
    log('Registering device token for push (${platform.name})');

    await Api().post(
      url: 'Notifications/device-token',
      body: {'token': deviceToken, 'platform': platform.value},
      token: token,
    );
  }

  /// `GET /Notifications/paged`
  ///
  /// The endpoint declares no response schema, so the answer is accepted in
  /// either plausible shape — an envelope or a bare list. See
  /// [NotificationPageModel] for why that is a reading rather than defensive
  /// padding.
  Future<NotificationPageModel> getNotificationsPaged({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 30,
    String? token,
  }) async {
    log('Fetching notifications page $page');

    final data = await Api().get(
      url:
          'Notifications/paged?UnreadOnly=$unreadOnly'
          '&Page=$page&PageSize=$pageSize',
      token: token,
    );

    if (data is List) return NotificationPageModel.fromList(data);
    return NotificationPageModel.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /Notifications/broadcast` — a push to many people at once.
  ///
  /// The one write in this app with no undo: sent is sent.
  Future<void> broadcastNotification({
    required BroadcastNotificationRequestModel body,
    String? token,
  }) async {
    log('Broadcasting a notification to ${body.audience.name}');

    await Api().post(
      url: 'Notifications/broadcast',
      body: body.toJson(),
      token: token,
    );
  }

  /// `GET /Notifications`
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    String? token,
  }) async {
    log('Fetching notifications (unreadOnly: $unreadOnly)');

    final data = await Api().get(
      url: 'Notifications?unreadOnly=$unreadOnly',
      token: token,
    );

    if (!unreadOnly) {
      await CacheHelper.saveJson(
        key: CacheKeys.cachedNotificationsList,
        value: data,
      );
    }

    return _decodeList(data, NotificationModel.fromJson);
  }

  /// `POST /Notifications/{id}/read`
  Future<void> markNotificationRead({required String id, String? token}) async {
    log('Marking notification as read: $id');

    await Api().post(
      url: 'Notifications/$id/read',
      body: const <String, dynamic>{},
      token: token,
    );
  }

  /// `POST /Notifications/read-all`
  Future<void> markAllNotificationsRead({String? token}) async {
    log('Marking all notifications as read');

    await Api().post(
      url: 'Notifications/read-all',
      body: const <String, dynamic>{},
      token: token,
    );
  }

  // ---------------------------------------------------------------------
  // Inventory (`/Inventory`)
  // ---------------------------------------------------------------------

  Future<List<InventoryItemModel>> getInventoryItems({
    bool includeInactive = false,
    String? token,
  }) async {
    log('Fetching inventory items (includeInactive: $includeInactive)');

    final responseData = await Api().get(
      url: 'Inventory?includeInactive=$includeInactive',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InventoryItemModel> createInventoryItem({
    required SaveInventoryItemRequestModel body,
    String? token,
  }) async {
    log('Creating inventory item: ${body.toJson()}');

    final response = await Api().post(
      url: 'Inventory',
      body: body.toJson(),
      token: token,
    );

    return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<InventoryItemModel> updateInventoryItem({
    required String id,
    required SaveInventoryItemRequestModel body,
    String? token,
  }) async {
    log('Updating inventory item $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'Inventory/$id',
      body: body.toJson(),
      token: token,
    );

    return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteInventoryItem({required String id, String? token}) async {
    log('Deleting inventory item: $id');

    await Api().delete(url: 'Inventory/$id', token: token);
  }

  /// `GET /Inventory/{id}/movements` — this item's full stock history.
  Future<List<InventoryMovementModel>> getInventoryMovements({
    required String id,
    String? token,
  }) async {
    log('Fetching inventory movements for item: $id');

    final responseData = await Api().get(
      url: 'Inventory/$id/movements',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => InventoryMovementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /Inventory/{id}/movements` — a manual movement (consumption or a
  /// correction); a purchase records its own and never calls this.
  Future<InventoryMovementModel> recordInventoryMovement({
    required String id,
    required RecordInventoryMovementRequestModel body,
    String? token,
  }) async {
    log('Recording inventory movement for item $id: ${body.toJson()}');

    final response = await Api().post(
      url: 'Inventory/$id/movements',
      body: body.toJson(),
      token: token,
    );

    return InventoryMovementModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ---------------------------------------------------------------------
  // Suppliers (`/Suppliers`)
  // ---------------------------------------------------------------------

  Future<List<SupplierModel>> getSuppliers({
    bool includeInactive = false,
    String? token,
  }) async {
    log('Fetching suppliers (includeInactive: $includeInactive)');

    final responseData = await Api().get(
      url: 'Suppliers?includeInactive=$includeInactive',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => SupplierModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupplierModel> createSupplier({
    required SaveSupplierRequestModel body,
    String? token,
  }) async {
    log('Creating supplier: ${body.toJson()}');

    final response = await Api().post(
      url: 'Suppliers',
      body: body.toJson(),
      token: token,
    );

    return SupplierModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SupplierModel> updateSupplier({
    required String id,
    required SaveSupplierRequestModel body,
    String? token,
  }) async {
    log('Updating supplier $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'Suppliers/$id',
      body: body.toJson(),
      token: token,
    );

    return SupplierModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSupplier({required String id, String? token}) async {
    log('Deleting supplier: $id');

    await Api().delete(url: 'Suppliers/$id', token: token);
  }

  // ---------------------------------------------------------------------
  // Purchases (`/Purchases`) — no `/{id}` route: a purchase is recorded and
  // read back, never edited or deleted.
  // ---------------------------------------------------------------------

  Future<List<PurchaseModel>> getPurchases({
    String? from,
    String? to,
    String? token,
  }) async {
    log('Fetching purchases (from: $from, to: $to)');

    final params = <String>[
      if (from != null && from.isNotEmpty) 'from=$from',
      if (to != null && to.isNotEmpty) 'to=$to',
    ];

    final responseData = await Api().get(
      url: params.isEmpty ? 'Purchases' : 'Purchases?${params.join('&')}',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PurchaseModel> createPurchase({
    required CreatePurchaseRequestModel body,
    String? token,
  }) async {
    log('Recording purchase: ${body.toJson()}');

    final response = await Api().post(
      url: 'Purchases',
      body: body.toJson(),
      token: token,
    );

    return PurchaseModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Store reports (`/store/feasibility`)
  // ---------------------------------------------------------------------

  /// `GET /store/feasibility` — الجدوى الاقتصادية الشهرية, one series per
  /// currency. [months] is how many months back to include; null leaves it
  /// to the server's own default.
  Future<MonthlyFeasibilityModel> getStoreFeasibility({
    int? months,
    List<String>? laboratoryIds,
    String? token,
  }) async {
    log('Fetching store feasibility (months: $months)');

    final params = <String>[
      if (months != null) 'months=$months',
      for (final id in laboratoryIds ?? const <String>[])
        'laboratoryIds=${Uri.encodeQueryComponent(id)}',
    ];

    final responseData = await Api().get(
      url: params.isEmpty
          ? 'store/feasibility'
          : 'store/feasibility?${params.join('&')}',
      token: token,
    );

    return MonthlyFeasibilityModel.fromJson(
      responseData as Map<String, dynamic>,
    );
  }

  // ---------------------------------------------------------------------
  // Case ticket templates (`/CaseTicketTemplates`) — the thermal-ticket
  // layout library, gated by `Branches` same as every other per-laboratory
  // settings screen (order-form template, footer contacts, logo).
  // ---------------------------------------------------------------------

  Future<List<CaseTicketTemplateListItemModel>> getCaseTicketTemplates({
    String? laboratoryId,
    String? token,
  }) async {
    log('Fetching case ticket templates (laboratoryId: $laboratoryId)');

    final responseData = await Api().get(
      url: laboratoryId == null
          ? 'CaseTicketTemplates'
          : 'CaseTicketTemplates?laboratoryId=$laboratoryId',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map(
          (e) => CaseTicketTemplateListItemModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<CaseTicketTemplateModel> getCaseTicketTemplateById({
    required String id,
    String? token,
  }) async {
    log('Fetching case ticket template: $id');

    final responseData = await Api().get(
      url: 'CaseTicketTemplates/$id',
      token: token,
    );

    return CaseTicketTemplateModel.fromJson(
      responseData as Map<String, dynamic>,
    );
  }

  Future<CaseTicketTemplateModel> createCaseTicketTemplate({
    required CreateCaseTicketTemplateRequestModel body,
    String? laboratoryId,
    String? token,
  }) async {
    log('Creating case ticket template: ${body.toJson()}');

    final response = await Api().post(
      url: laboratoryId == null
          ? 'CaseTicketTemplates'
          : 'CaseTicketTemplates?laboratoryId=$laboratoryId',
      body: body.toJson(),
      token: token,
    );

    return CaseTicketTemplateModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<CaseTicketTemplateModel> updateCaseTicketTemplate({
    required String id,
    required UpdateCaseTicketTemplateRequestModel body,
    String? token,
  }) async {
    log('Updating case ticket template $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'CaseTicketTemplates/$id',
      body: body.toJson(),
      token: token,
    );

    return CaseTicketTemplateModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteCaseTicketTemplate({
    required String id,
    String? token,
  }) async {
    log('Deleting case ticket template: $id');

    await Api().delete(url: 'CaseTicketTemplates/$id', token: token);
  }

  Future<CaseTicketTemplateModel> setDefaultCaseTicketTemplate({
    required String id,
    String? token,
  }) async {
    log('Setting default case ticket template: $id');

    final response = await Api().post(
      url: 'CaseTicketTemplates/$id/set-default',
      body: const <String, dynamic>{},
      token: token,
    );

    return CaseTicketTemplateModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
