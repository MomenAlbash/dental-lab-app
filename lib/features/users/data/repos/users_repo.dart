import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/users/data/models/create_user_request_model.dart';
import 'package:dental_lab_app/features/users/data/models/update_user_request_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dio/dio.dart';

class UsersRepo {
  final ApiService _apiService;
  UsersRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<UserModel>>> getUsers() async {
    try {
      final users = await _apiService.getUsers(token: _token);

      log('Fetched ${users.length} users');
      return right(users);
    } on DioException catch (e) {
      log('DioException while fetching users: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching users: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, UserModel>> getUserById(String id) async {
    try {
      final user = await _apiService.getUserById(id: id, token: _token);

      log('Fetched user: ${user.username}');
      return right(user);
    } on DioException catch (e) {
      log('DioException while fetching user: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching user: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, UserModel>> createUser(
    CreateUserRequestModel createUserRequestBody,
  ) async {
    try {
      final user = await _apiService.createUser(
        createUserRequestBody: createUserRequestBody,
        token: _token,
      );

      log('Created user: ${user.username}');
      return right(user);
    } on DioException catch (e) {
      log('DioException while creating user: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating user: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, UserModel>> updateUser({
    required String id,
    required UpdateUserRequestModel updateUserRequestBody,
  }) async {
    try {
      final user = await _apiService.updateUser(
        id: id,
        updateUserRequestBody: updateUserRequestBody,
        token: _token,
      );

      log('Updated user: ${user.username}');
      return right(user);
    } on DioException catch (e) {
      log('DioException while updating user: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating user: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteUser(String id) async {
    try {
      await _apiService.deleteUser(id: id, token: _token);

      log('Deleted user: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting user: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting user: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> setUserActive({
    required String id,
    required bool isActive,
  }) async {
    try {
      if (isActive) {
        await _apiService.activateUser(id: id, token: _token);
      } else {
        await _apiService.deactivateUser(id: id, token: _token);
      }

      log('Set user $id active: $isActive');
      return right(null);
    } on DioException catch (e) {
      log('DioException while toggling user active: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while toggling user active: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> resetPassword({
    required String id,
    required String newPassword,
  }) async {
    try {
      await _apiService.resetUserPassword(
        id: id,
        newPassword: newPassword,
        token: _token,
      );

      log('Reset password for user: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while resetting password: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while resetting password: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
