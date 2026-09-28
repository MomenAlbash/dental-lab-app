import 'dart:developer';

import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/create_price_tier_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/update_price_tier_request_model.dart';

/// The `price tiers` endpoints — split out of
/// [ApiService], reached through the same instance.
extension PriceTiersApi on ApiService {
  // ----------------------------------------------------------- price tiers ---

  Future<List<PriceTierModel>> getPriceTiers({String? token}) async {
    log('Fetching price tiers');

    final responseData = await Api().get(url: 'PriceTiers', token: token);

    log('Price tiers response data: ${logSafe(responseData)}');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedPriceTiersList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => PriceTierModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PriceTierModel> getPriceTierById({
    required String id,
    String? token,
  }) async {
    log('Fetching price tier by id: $id');

    final responseData = await Api().get(url: 'PriceTiers/$id', token: token);

    log('Price tier response data: ${logSafe(responseData)}');

    return PriceTierModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<PriceTierModel> createPriceTier({
    required CreatePriceTierRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create PriceTier request with: ${logSafe(body)}');

    final response = await Api().post(
      url: 'PriceTiers',
      body: body,
      token: token,
    );

    log('Create PriceTier response data: ${logSafe(response.data)}');

    return PriceTierModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PriceTierModel> updatePriceTier({
    required String id,
    required UpdatePriceTierRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update PriceTier request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'PriceTiers/$id',
      body: body,
      token: token,
    );

    log('Update PriceTier response data: ${logSafe(response.data)}');

    return PriceTierModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePriceTier({required String id, String? token}) async {
    log('Deleting price tier: $id');

    final response = await Api().delete(url: 'PriceTiers/$id', token: token);

    log('Delete PriceTier response data: ${logSafe(response.data)}');
  }


}
