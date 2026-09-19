import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_movement_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/record_inventory_movement_request_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/save_inventory_item_request_model.dart';
import 'package:dio/dio.dart';

class InventoryRepo {
  InventoryRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<InventoryItemModel>>> getInventoryItems({
    bool includeInactive = false,
  }) async {
    try {
      final items = await _apiService.getInventoryItems(
        includeInactive: includeInactive,
        token: _token,
      );

      log('Fetched ${items.length} inventory items');
      return right(items);
    } on DioException catch (e) {
      log('DioException while fetching inventory items: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching inventory items: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, InventoryItemModel>> createInventoryItem(
    SaveInventoryItemRequestModel requestBody,
  ) async {
    try {
      final item = await _apiService.createInventoryItem(
        body: requestBody,
        token: _token,
      );

      log('Created inventory item: ${item.name}');
      return right(item);
    } on DioException catch (e) {
      log('DioException while creating inventory item: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while creating inventory item: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, InventoryItemModel>> updateInventoryItem({
    required String id,
    required SaveInventoryItemRequestModel requestBody,
  }) async {
    try {
      final item = await _apiService.updateInventoryItem(
        id: id,
        body: requestBody,
        token: _token,
      );

      log('Updated inventory item: $id');
      return right(item);
    } on DioException catch (e) {
      log('DioException while updating inventory item: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while updating inventory item: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteInventoryItem(String id) async {
    try {
      await _apiService.deleteInventoryItem(id: id, token: _token);
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting inventory item: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting inventory item: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, List<InventoryMovementModel>>> getInventoryMovements(
    String id,
  ) async {
    try {
      final movements = await _apiService.getInventoryMovements(
        id: id,
        token: _token,
      );

      log('Fetched ${movements.length} movements for item $id');
      return right(movements);
    } on DioException catch (e) {
      log('DioException while fetching inventory movements: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while fetching inventory movements: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, InventoryMovementModel>> recordInventoryMovement({
    required String id,
    required RecordInventoryMovementRequestModel requestBody,
  }) async {
    try {
      final movement = await _apiService.recordInventoryMovement(
        id: id,
        body: requestBody,
        token: _token,
      );

      log('Recorded movement for item $id: ${movement.quantity}');
      return right(movement);
    } on DioException catch (e) {
      log('DioException while recording inventory movement: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log(
        'General Exception while recording inventory movement: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }
}
