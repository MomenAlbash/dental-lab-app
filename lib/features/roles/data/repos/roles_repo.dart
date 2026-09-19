import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/roles/data/models/create_role_request_model.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';
import 'package:dental_lab_app/features/roles/data/models/set_role_permissions_request_model.dart';
import 'package:dental_lab_app/features/roles/data/models/update_role_request_model.dart';
import 'package:dio/dio.dart';

class RolesRepo {
  final ApiService _apiService;
  RolesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<RoleModel>>> getRoles() async {
    try {
      final roles = await _apiService.getRoles(token: _token);

      log('Fetched ${roles.length} roles');
      return right(roles);
    } on DioException catch (e) {
      log('DioException while fetching roles: ${e.message}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedRolesList,
        fromJson: RoleModel.fromJson,
        onFailure: () => ServerFailure.fromDioException(e),
      );
    } catch (e) {
      log('General Exception while fetching roles: ${e.toString()}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedRolesList,
        fromJson: RoleModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
    }
  }

  Future<Either<Failure, RoleModel>> createRole(
    CreateRoleRequestModel requestBody,
  ) async {
    try {
      final role = await _apiService.createRole(
        createRequestBody: requestBody,
        token: _token,
      );

      log('Created role: ${role.name}');
      return right(role);
    } on DioException catch (e) {
      log('DioException while creating role: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while creating role: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Updates name/description, then the permission set — the API splits
  /// them across two endpoints. If the second call fails, the role is left
  /// with its new name but the old permissions; the caller surfaces that
  /// failure so the user knows to retry rather than assuming a clean save.
  Future<Either<Failure, RoleModel>> updateRole({
    required String id,
    required UpdateRoleRequestModel updateRequestBody,
    required List<RolePermission> permissions,
  }) async {
    try {
      await _apiService.updateRole(
        id: id,
        updateRequestBody: updateRequestBody,
        token: _token,
      );

      final role = await _apiService.setRolePermissions(
        id: id,
        setRequestBody: SetRolePermissionsRequestModel(permissions),
        token: _token,
      );

      log('Updated role: ${role.name}');
      return right(role);
    } on DioException catch (e) {
      log('DioException while updating role: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while updating role: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteRole(String id) async {
    try {
      await _apiService.deleteRole(id: id, token: _token);

      log('Deleted role: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting role: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting role: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  /// The modules this app can actually offer in the role form — always
  /// [RoleUserType.employee], since this screen only ever builds roles for
  /// the clinic's own staff.
  Future<Either<Failure, List<PermissionName>>>
  getRolePermissionCatalog() async {
    try {
      final catalog = await _apiService.getRolePermissionCatalog(
        userType: RoleUserType.employee,
        token: _token,
      );

      return right(catalog);
    } on DioException catch (e) {
      log('DioException while fetching permission catalog: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching permission catalog: $e');
      return left(ServerFailure.fromException(e));
    }
  }
}
