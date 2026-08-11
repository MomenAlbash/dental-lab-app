import 'dart:developer';

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
import 'package:dental_lab_app/features/case_priorities/data/models/save_case_priority_request_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_message_model.dart';
import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
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
import 'package:dental_lab_app/features/doctors/data/models/update_doctor_request_model.dart';
import 'package:dental_lab_app/features/employees/data/models/create_employee_request_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_attachment_file_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/models/update_employee_request_model.dart';
import 'package:dental_lab_app/features/patients/data/models/create_patient_request_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/create_price_tier_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/set_price_tier_prices_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/update_price_tier_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/create_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/update_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';
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

    final responseData = await Api().get(Url: 'Laboratories', token: token);

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

    final responseData = await Api().get(Url: 'Laboratories/own', token: token);

    log('Own laboratory response data: $responseData');

    return LaboratoryModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<LaboratoryModel> getLaboratoryById({
    required String id,
    String? token,
  }) async {
    log('Fetching laboratory by id: $id');

    final responseData = await Api().get(Url: 'Laboratories/$id', token: token);

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

    final responseData = await Api().get(Url: 'Clinics', token: token);

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

    final responseData = await Api().get(Url: 'Clinics/$id', token: token);

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
    final responseData = await Api().get(Url: url, token: token);

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

  // ------------------------------------------------------------- countries ---

  Future<List<CountryModel>> getCountries({String? token}) async {
    log('Fetching countries');

    final responseData = await Api().get(Url: 'Countries', token: token);

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

    final responseData = await Api().get(Url: 'Doctors', token: token);

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

    final responseData = await Api().get(Url: 'Doctors/$id', token: token);

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

  // ------------------------------------------------------------- employees ---

  Future<List<EmployeeModel>> getEmployees({String? token}) async {
    log('Fetching employees');

    final responseData = await Api().get(Url: 'Employees', token: token);

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

    final responseData = await Api().get(Url: 'Employees/$id', token: token);

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

    final responseData = await Api().get(Url: 'Roles', token: token);

    log('Roles response data: $responseData');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedRolesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
        .toList();
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
      Url: query.isEmpty ? 'Users' : 'Users?${query.join('&')}',
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

    final responseData = await Api().get(Url: 'Users/$id', token: token);

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

    final responseData = await Api().get(Url: 'RestorationTypes', token: token);

    log('Restoration types response data: $responseData');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedRestorationTypesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => RestorationTypeModel.fromJson(e as Map<String, dynamic>))
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
      Url: 'case-priorities?includeInactive=$includeInactive',
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

  // --------------------------------------------------- scanner availability ---

  Future<List<ScannerAvailabilityRuleModel>> getScannerRules({
    String? token,
  }) async {
    log('Fetching scanner availability rules');

    final responseData = await Api().get(
      Url: 'scanner-availability/rules',
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
      Url: 'scanner-availability/exceptions?from=$from&to=$to',
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
      Url: 'scanner-availability/calendar?from=$from&to=$to',
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

    final responseData = await Api().get(Url: 'PriceTiers', token: token);

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

    final responseData = await Api().get(Url: 'PriceTiers/$id', token: token);

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
      Url: query.isEmpty ? 'Patients' : 'Patients?${query.join('&')}',
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

    final responseData = await Api().get(Url: 'Patients/$id', token: token);

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

  // ----------------------------------------------------------------- cases ---

  Future<List<CaseListItemModel>> getCases({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    int? caseStatus,
    String? dueDateFrom,
    String? dueDateTo,
    String? token,
  }) async {
    log('Fetching cases');

    final params = <String, String>{'PageSize': '200'};
    if (search != null && search.isNotEmpty) params['Search'] = search;
    if (doctorId != null) params['DoctorId'] = doctorId;
    if (clinicId != null) params['ClinicId'] = clinicId;
    if (patientId != null) params['PatientId'] = patientId;
    if (priorityId != null) params['PriorityId'] = priorityId;
    if (caseStatus != null) params['CaseStatus'] = '$caseStatus';
    if (dueDateFrom != null) params['DueDateFrom'] = dueDateFrom;
    if (dueDateTo != null) params['DueDateTo'] = dueDateTo;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final responseData = await Api().get(Url: 'Cases?$query', token: token);

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
        dueDateFrom == null &&
        dueDateTo == null;
    if (isUnfiltered) {
      await CacheHelper.saveJson(key: CacheKeys.cachedCasesList, value: items);
    }

    return items
        .map((e) => CaseListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CaseDetailModel> getCaseById({
    required String id,
    String? token,
  }) async {
    log('Fetching case by id: $id');

    final responseData = await Api().get(Url: 'Cases/$id', token: token);

    log('Case by id response data: $responseData');

    return CaseDetailModel.fromJson(responseData as Map<String, dynamic>);
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
    String? token,
  }) async {
    log('Setting stage $stageId for restoration $restorationId (case $caseId)');

    final response = await Api().put(
      url: 'Cases/$caseId/restorations/$restorationId/stage',
      body: {'stageId': stageId, 'note': note},
      token: token,
    );

    log('Set Restoration stage response data: ${response.data}');
  }

  Future<CaseDetailModel> setCaseStatus({
    required String id,
    required int caseStatus,
    String? note,
    String? token,
  }) async {
    log('Setting status $caseStatus for case $id');

    final response = await Api().put(
      url: 'Cases/$id/status',
      body: {'caseStatus': caseStatus, 'note': note},
      token: token,
    );

    log('Set Case status response data: ${response.data}');

    return CaseDetailModel.fromJson(response.data as Map<String, dynamic>);
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
      Url: 'Cases/$id/messages',
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
      if (message != null) 'Message': message,
      if (replyToMessageId != null) 'ReplyToMessageId': replyToMessageId,
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
}
