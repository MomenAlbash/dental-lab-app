import 'dart:developer';

import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/departments/data/models/department_model.dart';
import 'package:dental_lab_app/features/departments/data/models/save_department_request_model.dart';

/// The `departments` endpoints — split out of
/// [ApiService], reached through the same instance.
extension DepartmentsApi on ApiService {
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

    return decodeJsonList(data, DepartmentModel.fromJson);
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


}
