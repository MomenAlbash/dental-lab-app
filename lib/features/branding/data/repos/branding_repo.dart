import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/features/branding/data/models/branding_model.dart';
import 'package:dio/dio.dart';

/// The laboratory's visual identity.
///
/// Talks to [Api] directly rather than through `ApiService`: `GET /Branding`
/// is the one call this app makes **before** anybody is signed in, and keeping
/// it out of the authenticated service makes that impossible to forget.
class BrandingRepo {
  BrandingRepo();

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  /// Reads the branding for one surface — this app is always `admin`.
  ///
  /// Anonymous: the login screen must be dressed in the lab's own colour
  /// before a token exists, which is exactly the moment a white-labelled app
  /// gives itself away if it paints its own brand instead.
  Future<Either<Failure, BrandingModel>> getBranding({
    BrandingScope scope = BrandingScope.admin,
  }) async {
    try {
      log('Fetching branding for scope: ${scope.key}');

      final data = await Api().get(url: 'Branding?scope=${scope.key}');
      if (data is! Map<String, dynamic>) return right(BrandingModel.fallback);

      return right(BrandingModel.fromJson(data));
    } on DioException catch (e) {
      log('DioException while fetching branding: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching branding: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, BrandingModel>> updateBranding({
    required UpdateBrandingRequestModel body,
    BrandingScope scope = BrandingScope.admin,
  }) async {
    try {
      log('Updating branding: ${body.toJson()}');

      final response = await Api().put(
        url: 'Branding?scope=${scope.key}',
        body: body.toJson(),
        token: _token,
      );

      return right(
        BrandingModel.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      log('DioException while updating branding: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while updating branding: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, BrandingModel>> uploadLogo({
    required String filePath,
    BrandingScope scope = BrandingScope.admin,
  }) async {
    try {
      log('Uploading branding logo');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await Api().post(
        url: 'Branding/logo?scope=${scope.key}',
        body: formData,
        isFormData: true,
        token: _token,
      );

      return right(
        BrandingModel.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      log('DioException while uploading a branding logo: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while uploading a branding logo: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, BrandingModel>> removeLogo({
    BrandingScope scope = BrandingScope.admin,
  }) async {
    try {
      log('Removing branding logo');

      final response = await Api().delete(
        url: 'Branding/logo?scope=${scope.key}',
        token: _token,
      );

      return right(
        BrandingModel.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      log('DioException while removing a branding logo: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while removing a branding logo: $e');
      return left(ServerFailure.fromException(e));
    }
  }
}
