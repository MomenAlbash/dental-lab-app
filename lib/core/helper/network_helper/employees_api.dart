import 'dart:developer';

import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/employees/data/models/create_employee_request_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_attachment_file_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/models/update_employee_request_model.dart';
import 'package:dio/dio.dart';

/// The `employees` endpoints — split out of
/// [ApiService], reached through the same instance.
extension EmployeesApi on ApiService {
  // ------------------------------------------------------------- employees ---

  /// `GET /Employees?IsAgent=true` — the agents (وكلاء) a representative
  /// hands field-collected cash to. Not cached: the cache holds the full
  /// employee list, and a filtered answer must not replace it.
  Future<List<EmployeeModel>> getAgents({String? token}) async {
    log('Fetching agents');

    final responseData = await Api().get(
      url: 'Employees?IsAgent=true',
      token: token,
    );

    return [
      for (final row in responseData as List<dynamic>? ?? const [])
        if (row is Map<String, dynamic>) EmployeeModel.fromJson(row),
    ];
  }

  Future<List<EmployeeModel>> getEmployees({String? token}) async {
    log('Fetching employees');

    final responseData = await Api().get(url: 'Employees', token: token);

    log('Employees response data: ${logSafe(responseData)}');

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

    log('Employee by id response data: ${logSafe(responseData)}');

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

    log('Create Employee response data: ${logSafe(response.data)}');

    return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmployeeModel> updateEmployee({
    required String id,
    required UpdateEmployeeRequestModel updateEmployeeRequestBody,
    String? token,
  }) async {
    final body = updateEmployeeRequestBody.toJson();

    log('Sending Update Employee request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'Employees/$id',
      body: body,
      token: token,
    );

    log('Update Employee response data: ${logSafe(response.data)}');

    return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteEmployee({required String id, String? token}) async {
    log('Deleting employee: $id');

    final response = await Api().delete(url: 'Employees/$id', token: token);

    log('Delete Employee response data: ${logSafe(response.data)}');
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

    log('Upload Employee file response data: ${logSafe(response.data)}');

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

    log('Delete Employee file response data: ${logSafe(response.data)}');
  }


}
