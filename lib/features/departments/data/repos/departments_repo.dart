import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/people_api.dart';
import 'package:dental_lab_app/features/departments/data/models/department_model.dart';
import 'package:dental_lab_app/features/departments/data/models/department_user_model.dart';
import 'package:dental_lab_app/features/departments/data/models/save_department_request_model.dart';
import 'package:dio/dio.dart';

/// Reads and edits the laboratory's departments.
///
/// Not cached: a save replaces the whole stage and employee membership, so
/// editing against a stale picture would unlink stages someone else had just
/// attached.
class DepartmentsRepo {
  DepartmentsRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, T>> _guard<T>(
    String what,
    Future<T> Function() request,
  ) async {
    try {
      return right(await request());
    } on DioException catch (e) {
      log('DioException while $what: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while $what: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, List<DepartmentModel>>> getDepartments({
    bool includeInactive = false,
  }) => _guard(
    'fetching departments',
    () => _apiService.getDepartments(
      includeInactive: includeInactive,
      token: _token,
    ),
  );

  Future<Either<Failure, DepartmentModel>> getDepartment(String id) => _guard(
    'fetching a department',
    () => _apiService.getDepartment(id: id, token: _token),
  );

  Future<Either<Failure, DepartmentModel>> createDepartment(
    SaveDepartmentRequestModel body,
  ) => _guard(
    'creating a department',
    () => _apiService.createDepartment(body: body, token: _token),
  );

  Future<Either<Failure, DepartmentModel>> updateDepartment({
    required String id,
    required SaveDepartmentRequestModel body,
  }) => _guard(
    'updating a department',
    () => _apiService.updateDepartment(id: id, body: body, token: _token),
  );

  Future<Either<Failure, void>> deleteDepartment(String id) => _guard(
    'deleting a department',
    () => _apiService.deleteDepartment(id: id, token: _token),
  );
}

/// The people a department brings into a stage's pool.
extension DepartmentUsersRepo on DepartmentsRepo {
  Future<Either<Failure, List<DepartmentUserModel>>> getUsers(
    String departmentId,
  ) async {
    try {
      final users = await _apiService.getDepartmentUsers(
        departmentId: departmentId,
        token: _token,
      );

      log('Fetched ${users.length} users for department: $departmentId');
      return right(users);
    } on DioException catch (e) {
      log('DioException while fetching department users: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching department users: $e');
      return left(ServerFailure.fromException(e));
    }
  }
}
