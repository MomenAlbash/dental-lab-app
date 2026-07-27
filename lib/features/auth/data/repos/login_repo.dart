import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/auth/data/models/login_request_model.dart';
import 'package:dental_lab_app/features/auth/data/models/login_response_model.dart';
import 'package:dio/dio.dart';

class LoginRepo {
  final ApiService _apiService;
  LoginRepo(this._apiService);

  Future<Either<Failure, LoginResponseModel>> login(
    LoginRequestModel loginRequestBody,
  ) async {
    try {
      log('Sending Login request with: ${loginRequestBody.toJson()}');

      final response = await _apiService.userLogin(
        loginRequestBody: loginRequestBody,
      );

      final token = response.token;
      if (token == null || token.isEmpty) {
        return left(
          ServerFailure('تعذر الحصول على بيانات المستخدم من السيرفر'),
        );
      }

      await CacheHelper.saveData(key: CacheKeys.token, value: token);

      // Scope the session to the laboratory the account belongs to. If the
      // user has access to more than one, the laboratory-selection screen
      // overwrites this afterwards.
      final laboratory = response.data?.laboratory;
      final laboratoryId = response.data?.laboratoryId ?? laboratory?.id;
      if (laboratoryId != null) {
        await CacheHelper.saveData(
          key: CacheKeys.laboratoryId,
          value: laboratoryId,
        );
        await CacheHelper.saveData(
          key: CacheKeys.laboratoryName,
          value: laboratory?.name ?? '',
        );
      }

      log('Login response successfully received');
      return right(response);
    } on DioException catch (e) {
      log('DioException during login: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception during login: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
