import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';
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
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching roles: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
