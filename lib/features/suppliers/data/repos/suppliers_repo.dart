import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/suppliers/data/models/save_supplier_request_model.dart';
import 'package:dental_lab_app/features/suppliers/data/models/supplier_model.dart';
import 'package:dio/dio.dart';

class SuppliersRepo {
  SuppliersRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<SupplierModel>>> getSuppliers({
    bool includeInactive = false,
  }) async {
    try {
      final suppliers = await _apiService.getSuppliers(
        includeInactive: includeInactive,
        token: _token,
      );

      log('Fetched ${suppliers.length} suppliers');
      return right(suppliers);
    } on DioException catch (e) {
      log('DioException while fetching suppliers: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching suppliers: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, SupplierModel>> createSupplier(
    SaveSupplierRequestModel requestBody,
  ) async {
    try {
      final supplier = await _apiService.createSupplier(
        body: requestBody,
        token: _token,
      );

      log('Created supplier: ${supplier.name}');
      return right(supplier);
    } on DioException catch (e) {
      log('DioException while creating supplier: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while creating supplier: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, SupplierModel>> updateSupplier({
    required String id,
    required SaveSupplierRequestModel requestBody,
  }) async {
    try {
      final supplier = await _apiService.updateSupplier(
        id: id,
        body: requestBody,
        token: _token,
      );

      log('Updated supplier: $id');
      return right(supplier);
    } on DioException catch (e) {
      log('DioException while updating supplier: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while updating supplier: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteSupplier(String id) async {
    try {
      await _apiService.deleteSupplier(id: id, token: _token);
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting supplier: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting supplier: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
