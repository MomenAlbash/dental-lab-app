import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/areas/data/models/area_model.dart';
import 'package:dental_lab_app/features/areas/data/models/save_area_request_models.dart';
import 'package:dio/dio.dart';

class AreasRepo {
  final ApiService _apiService;
  AreasRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<AreaModel>>> getAreas({String? cityId}) async {
    try {
      final areas = await _apiService.getAreas(cityId: cityId, token: _token);

      log('Fetched ${areas.length} areas');
      return right(areas);
    } on DioException catch (e) {
      log('DioException while fetching areas: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching areas: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, AreaModel>> createArea(
    CreateAreaRequestModel requestBody,
  ) async {
    try {
      final area = await _apiService.createArea(
        createRequestBody: requestBody,
        token: _token,
      );

      log('Created area: ${area.name}');
      return right(area);
    } on DioException catch (e) {
      log('DioException while creating area: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while creating area: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, AreaModel>> updateArea({
    required String id,
    required UpdateAreaRequestModel requestBody,
  }) async {
    try {
      final area = await _apiService.updateArea(
        id: id,
        updateRequestBody: requestBody,
        token: _token,
      );

      log('Updated area: ${area.name}');
      return right(area);
    } on DioException catch (e) {
      log('DioException while updating area: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while updating area: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteArea(String id) async {
    try {
      await _apiService.deleteArea(id: id, token: _token);

      log('Deleted area: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting area: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting area: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
