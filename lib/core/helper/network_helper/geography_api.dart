import 'dart:developer';

import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/areas/data/models/area_model.dart';
import 'package:dental_lab_app/features/areas/data/models/save_area_request_models.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/countries/data/models/country_model.dart';
import 'package:dental_lab_app/features/zones/data/models/save_zone_request_models.dart';
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';

/// The `geography` endpoints — split out of
/// [ApiService], reached through the same instance.
extension GeographyApi on ApiService {
  // ---------------------------------------------------------------- cities ---

  Future<List<CityModel>> getCities({String? countryId, String? token}) async {
    log('Fetching cities');

    final url = countryId == null ? 'Cities' : 'Cities?countryId=$countryId';
    final responseData = await Api().get(url: url, token: token);

    log('Cities response data: ${logSafe(responseData)}');

    if (countryId == null) {
      await CacheHelper.saveJson(
        key: CacheKeys.cachedCitiesList,
        value: responseData,
      );
    }

    return (responseData as List<dynamic>)
        .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CityModel> createCity({
    required String name,
    String? countryId,
    String? token,
  }) async {
    log('Sending Create City request with: $name');

    final response = await Api().post(
      url: 'Cities',
      body: {'name': name, 'countryId': countryId},
      token: token,
    );

    log('Create City response data: ${logSafe(response.data)}');

    return CityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CityModel> updateCity({
    required String id,
    required String name,
    String? countryId,
    String? token,
  }) async {
    log('Sending Update City request with: $name');

    final response = await Api().put(
      url: 'Cities/$id',
      body: {'name': name, 'countryId': countryId},
      token: token,
    );

    log('Update City response data: ${logSafe(response.data)}');

    return CityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCity({required String id, String? token}) async {
    log('Deleting city: $id');

    final response = await Api().delete(url: 'Cities/$id', token: token);

    log('Delete City response data: ${logSafe(response.data)}');
  }


  // ----------------------------------------------------------------- areas ---

  Future<List<AreaModel>> getAreas({String? cityId, String? token}) async {
    log('Fetching areas (cityId: $cityId)');

    final url = cityId == null ? 'Areas' : 'Areas?cityId=$cityId';
    final responseData = await Api().get(url: url, token: token);

    return (responseData as List<dynamic>)
        .map((e) => AreaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AreaModel> createArea({
    required CreateAreaRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create Area request with: ${logSafe(body)}');

    final response = await Api().post(url: 'Areas', body: body, token: token);

    return AreaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AreaModel> updateArea({
    required String id,
    required UpdateAreaRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update Area request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'Areas/$id',
      body: body,
      token: token,
    );

    return AreaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteArea({required String id, String? token}) async {
    log('Deleting area: $id');

    final response = await Api().delete(url: 'Areas/$id', token: token);

    log('Delete Area response data: ${logSafe(response.data)}');
  }


  // ----------------------------------------------------------------- zones ---

  Future<List<ZoneModel>> getZones({
    bool includeInactive = false,
    List<String>? laboratoryIds,
    String? token,
  }) async {
    log('Fetching zones (includeInactive: $includeInactive)');

    final params = <String>['includeInactive=$includeInactive'];
    for (final id in laboratoryIds ?? const <String>[]) {
      params.add('laboratoryIds=${Uri.encodeQueryComponent(id)}');
    }

    final responseData = await Api().get(
      url: 'Zones?${params.join('&')}',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ZoneModel> getZoneById({required String id, String? token}) async {
    log('Fetching zone by id: $id');

    final responseData = await Api().get(url: 'Zones/$id', token: token);

    return ZoneModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<ZoneModel> createZone({
    required CreateZoneRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create Zone request with: ${logSafe(body)}');

    final response = await Api().post(url: 'Zones', body: body, token: token);

    return ZoneModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ZoneModel> updateZone({
    required String id,
    required UpdateZoneRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update Zone request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'Zones/$id',
      body: body,
      token: token,
    );

    return ZoneModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteZone({required String id, String? token}) async {
    log('Deleting zone: $id');

    final response = await Api().delete(url: 'Zones/$id', token: token);

    log('Delete Zone response data: ${logSafe(response.data)}');
  }


  // ------------------------------------------------------------- countries ---

  Future<List<CountryModel>> getCountries({String? token}) async {
    log('Fetching countries');

    final responseData = await Api().get(url: 'Countries', token: token);

    log('Countries response data: ${logSafe(responseData)}');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedCountriesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => CountryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CountryModel> createCountry({
    required String name,
    String? token,
  }) async {
    log('Sending Create Country request with: $name');

    final response = await Api().post(
      url: 'Countries',
      body: {'name': name},
      token: token,
    );

    log('Create Country response data: ${logSafe(response.data)}');

    return CountryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CountryModel> updateCountry({
    required String id,
    required String name,
    String? token,
  }) async {
    log('Sending Update Country request with: $name');

    final response = await Api().put(
      url: 'Countries/$id',
      body: {'name': name},
      token: token,
    );

    log('Update Country response data: ${logSafe(response.data)}');

    return CountryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCountry({required String id, String? token}) async {
    log('Deleting country: $id');

    final response = await Api().delete(url: 'Countries/$id', token: token);

    log('Delete Country response data: ${logSafe(response.data)}');
  }


}
