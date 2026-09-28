import 'dart:developer';

import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_exception_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_rule_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_exception_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_rule_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_day_model.dart';

/// The `scanner availability` endpoints — split out of
/// [ApiService], reached through the same instance.
extension ScannerAvailabilityApi on ApiService {
  // --------------------------------------------------- scanner availability ---

  Future<List<ScannerAvailabilityRuleModel>> getScannerRules({
    String? token,
  }) async {
    log('Fetching scanner availability rules');

    final responseData = await Api().get(
      url: 'scanner-availability/rules',
      token: token,
    );

    log('Scanner rules response data: ${logSafe(responseData)}');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedScannerRulesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map(
          (e) =>
              ScannerAvailabilityRuleModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ScannerAvailabilityRuleModel> createScannerRule({
    required SaveScannerAvailabilityRuleRequestModel saveRequestBody,
    String? token,
  }) async {
    final body = saveRequestBody.toJson();

    log('Sending Create ScannerRule request with: ${logSafe(body)}');

    final response = await Api().post(
      url: 'scanner-availability/rules',
      body: body,
      token: token,
    );

    log('Create ScannerRule response data: ${logSafe(response.data)}');

    return ScannerAvailabilityRuleModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ScannerAvailabilityRuleModel> updateScannerRule({
    required String id,
    required SaveScannerAvailabilityRuleRequestModel saveRequestBody,
    String? token,
  }) async {
    final body = saveRequestBody.toJson();

    log('Sending Update ScannerRule request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'scanner-availability/rules/$id',
      body: body,
      token: token,
    );

    log('Update ScannerRule response data: ${logSafe(response.data)}');

    return ScannerAvailabilityRuleModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteScannerRule({required String id, String? token}) async {
    log('Deleting scanner rule: $id');

    final response = await Api().delete(
      url: 'scanner-availability/rules/$id',
      token: token,
    );

    log('Delete ScannerRule response data: ${logSafe(response.data)}');
  }

  /// [from] and [to] are `yyyy-MM-dd`; the window is required, since an
  /// unbounded list of date overrides is not something the API offers.
  Future<List<ScannerAvailabilityExceptionModel>> getScannerExceptions({
    required String from,
    required String to,
    String? token,
  }) async {
    log('Fetching scanner exceptions from $from to $to');

    final responseData = await Api().get(
      url: 'scanner-availability/exceptions?from=$from&to=$to',
      token: token,
    );

    log('Scanner exceptions response data: ${logSafe(responseData)}');

    return (responseData as List<dynamic>)
        .map(
          (e) => ScannerAvailabilityExceptionModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Upserts the exception for its date — the API keys off the date, not an
  /// id, so this both creates and edits.
  Future<ScannerAvailabilityExceptionModel> saveScannerException({
    required SaveScannerAvailabilityExceptionRequestModel saveRequestBody,
    String? token,
  }) async {
    final body = saveRequestBody.toJson();

    log('Sending Save ScannerException request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'scanner-availability/exceptions',
      body: body,
      token: token,
    );

    log('Save ScannerException response data: ${logSafe(response.data)}');

    return ScannerAvailabilityExceptionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteScannerException({
    required String id,
    String? token,
  }) async {
    log('Deleting scanner exception: $id');

    final response = await Api().delete(
      url: 'scanner-availability/exceptions/$id',
      token: token,
    );

    log('Delete ScannerException response data: ${logSafe(response.data)}');
  }

  /// The rules and exceptions resolved into concrete days and slots — what the
  /// doctor is offered. Read-only: the lab changes it by changing the rules.
  Future<List<ScannerDayModel>> getScannerCalendar({
    required String from,
    required String to,
    String? token,
  }) async {
    log('Fetching scanner calendar from $from to $to');

    final responseData = await Api().get(
      url: 'scanner-availability/calendar?from=$from&to=$to',
      token: token,
    );

    log('Scanner calendar response data: ${logSafe(responseData)}');

    return (responseData as List<dynamic>)
        .map((e) => ScannerDayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }


}
