import 'dart:developer';

import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/roles/data/models/create_role_request_model.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';
import 'package:dental_lab_app/features/roles/data/models/set_role_permissions_request_model.dart';
import 'package:dental_lab_app/features/roles/data/models/update_role_request_model.dart';

/// The `roles` endpoints — split out of
/// [ApiService], reached through the same instance.
extension RolesApi on ApiService {
  // ----------------------------------------------------------------- roles ---

  Future<List<RoleModel>> getRoles({String? token}) async {
    log('Fetching roles');

    final responseData = await Api().get(url: 'Roles', token: token);

    log('Roles response data: ${logSafe(responseData)}');

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

    log('Sending Create Role request with: ${logSafe(body)}');

    final response = await Api().post(url: 'Roles', body: body, token: token);

    log('Create Role response data: ${logSafe(response.data)}');

    return RoleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoleModel> updateRole({
    required String id,
    required UpdateRoleRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update Role request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'Roles/$id',
      body: body,
      token: token,
    );

    log('Update Role response data: ${logSafe(response.data)}');

    return RoleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRole({required String id, String? token}) async {
    log('Deleting role: $id');

    final response = await Api().delete(url: 'Roles/$id', token: token);

    log('Delete Role response data: ${logSafe(response.data)}');
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

    log('Setting permissions for role $id: ${logSafe(body)}');

    final response = await Api().put(
      url: 'Roles/$id/permissions',
      body: body,
      token: token,
    );

    return RoleModel.fromJson(response.data as Map<String, dynamic>);
  }


}
