import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/create_price_tier_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/set_price_tier_prices_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/update_price_tier_request_model.dart';
import 'package:dio/dio.dart';

class PriceTiersRepo {
  final ApiService _apiService;
  PriceTiersRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<PriceTierModel>>> getPriceTiers() async {
    try {
      final tiers = await _apiService.getPriceTiers(token: _token);

      log('Fetched ${tiers.length} price tiers');
      return right(tiers);
    } on DioException catch (e) {
      log('DioException while fetching price tiers: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching price tiers: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, PriceTierModel>> getPriceTierById(String id) async {
    try {
      final tier = await _apiService.getPriceTierById(id: id, token: _token);

      log('Fetched price tier: ${tier.name}');
      return right(tier);
    } on DioException catch (e) {
      log('DioException while fetching price tier: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching price tier: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, PriceTierModel>> createPriceTier(
    CreatePriceTierRequestModel createRequestBody,
  ) async {
    try {
      final tier = await _apiService.createPriceTier(
        createRequestBody: createRequestBody,
        token: _token,
      );

      log('Created price tier: ${tier.name}');
      return right(tier);
    } on DioException catch (e) {
      log('DioException while creating price tier: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating price tier: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, PriceTierModel>> updatePriceTier({
    required String id,
    required UpdatePriceTierRequestModel updateRequestBody,
  }) async {
    try {
      final tier = await _apiService.updatePriceTier(
        id: id,
        updateRequestBody: updateRequestBody,
        token: _token,
      );

      log('Updated price tier: ${tier.name}');
      return right(tier);
    } on DioException catch (e) {
      log('DioException while updating price tier: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating price tier: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deletePriceTier(String id) async {
    try {
      await _apiService.deletePriceTier(id: id, token: _token);

      log('Deleted price tier: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting price tier: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting price tier: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, PriceTierModel>> setPrices({
    required String id,
    required SetPriceTierPricesRequestModel setPricesRequestBody,
  }) async {
    try {
      final tier = await _apiService.setPriceTierPrices(
        id: id,
        setPricesRequestBody: setPricesRequestBody,
        token: _token,
      );

      log('Set prices for price tier: ${tier.name}');
      return right(tier);
    } on DioException catch (e) {
      log('DioException while setting price tier prices: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while setting price tier prices: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
