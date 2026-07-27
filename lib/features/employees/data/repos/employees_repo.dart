import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/employees/data/models/create_employee_request_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_attachment_file_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/models/update_employee_request_model.dart';
import 'package:dio/dio.dart';

class EmployeesRepo {
  final ApiService _apiService;
  EmployeesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<EmployeeModel>>> getEmployees() async {
    try {
      final employees = await _apiService.getEmployees(token: _token);

      log('Fetched ${employees.length} employees');
      return right(employees);
    } on DioException catch (e) {
      log('DioException while fetching employees: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching employees: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, EmployeeModel>> getEmployeeById(String id) async {
    try {
      final employee = await _apiService.getEmployeeById(id: id, token: _token);

      log('Fetched employee: ${employee.fullName}');
      return right(employee);
    } on DioException catch (e) {
      log('DioException while fetching employee: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching employee: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, EmployeeModel>> createEmployee(
    CreateEmployeeRequestModel createEmployeeRequestBody,
  ) async {
    try {
      final employee = await _apiService.createEmployee(
        createEmployeeRequestBody: createEmployeeRequestBody,
        token: _token,
      );

      log('Created employee: ${employee.fullName}');
      return right(employee);
    } on DioException catch (e) {
      log('DioException while creating employee: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating employee: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, EmployeeModel>> updateEmployee({
    required String id,
    required UpdateEmployeeRequestModel updateEmployeeRequestBody,
  }) async {
    try {
      final employee = await _apiService.updateEmployee(
        id: id,
        updateEmployeeRequestBody: updateEmployeeRequestBody,
        token: _token,
      );

      log('Updated employee: ${employee.fullName}');
      return right(employee);
    } on DioException catch (e) {
      log('DioException while updating employee: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating employee: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteEmployee(String id) async {
    try {
      await _apiService.deleteEmployee(id: id, token: _token);

      log('Deleted employee: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting employee: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting employee: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, EmployeeAttachmentFileModel>> uploadEmployeeFile({
    required String id,
    required String filePath,
  }) async {
    try {
      final file = await _apiService.uploadEmployeeFile(
        id: id,
        filePath: filePath,
        token: _token,
      );

      log('Uploaded file for employee: $id');
      return right(file);
    } on DioException catch (e) {
      log('DioException while uploading employee file: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while uploading employee file: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteEmployeeFile({
    required String id,
    required String fileId,
  }) async {
    try {
      await _apiService.deleteEmployeeFile(
        id: id,
        fileId: fileId,
        token: _token,
      );

      log('Deleted file $fileId for employee: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting employee file: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting employee file: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
