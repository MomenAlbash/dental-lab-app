import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/purchases/data/models/create_purchase_request_model.dart';
import 'package:dental_lab_app/features/purchases/data/models/purchase_model.dart';
import 'package:dio/dio.dart';

class PurchasesRepo {
  PurchasesRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<PurchaseModel>>> getPurchases({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final purchases = await _apiService.getPurchases(
        from: _isoDate(from),
        to: _isoDate(to),
        token: _token,
      );

      log('Fetched ${purchases.length} purchases');
      return right(purchases);
    } on DioException catch (e) {
      log('DioException while fetching purchases: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching purchases: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, PurchaseModel>> createPurchase(
    CreatePurchaseRequestModel requestBody,
  ) async {
    try {
      final purchase = await _apiService.createPurchase(
        body: requestBody,
        token: _token,
      );

      log('Recorded purchase: ${purchase.id}');
      return right(purchase);
    } on DioException catch (e) {
      log('DioException while recording purchase: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while recording purchase: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  String? _isoDate(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
