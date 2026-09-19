import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/zones/data/models/save_zone_request_models.dart';
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';
import 'package:dio/dio.dart';

class ZonesRepo {
  final ApiService _apiService;
  ZonesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<ZoneModel>>> getZones({
    bool includeInactive = false,
  }) async {
    try {
      final zones = await _apiService.getZones(
        includeInactive: includeInactive,
        token: _token,
      );

      log('Fetched ${zones.length} zones');
      return right(zones);
    } on DioException catch (e) {
      log('DioException while fetching zones: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching zones: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, ZoneModel>> getZoneById(String id) async {
    try {
      final zone = await _apiService.getZoneById(id: id, token: _token);

      log('Fetched zone: ${zone.name}');
      return right(zone);
    } on DioException catch (e) {
      log('DioException while fetching zone: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching zone: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, ZoneModel>> createZone(
    CreateZoneRequestModel requestBody,
  ) async {
    try {
      final zone = await _apiService.createZone(
        createRequestBody: requestBody,
        token: _token,
      );

      log('Created zone: ${zone.name}');
      return right(zone);
    } on DioException catch (e) {
      log('DioException while creating zone: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while creating zone: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, ZoneModel>> updateZone({
    required String id,
    required UpdateZoneRequestModel requestBody,
  }) async {
    try {
      final zone = await _apiService.updateZone(
        id: id,
        updateRequestBody: requestBody,
        token: _token,
      );

      log('Updated zone: ${zone.name}');
      return right(zone);
    } on DioException catch (e) {
      log('DioException while updating zone: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while updating zone: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteZone(String id) async {
    try {
      await _apiService.deleteZone(id: id, token: _token);

      log('Deleted zone: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting zone: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting zone: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
