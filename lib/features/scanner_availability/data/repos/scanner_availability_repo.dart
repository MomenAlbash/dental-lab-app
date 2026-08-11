import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_exception_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_rule_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_exception_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_rule_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_day_model.dart';
import 'package:dio/dio.dart';

class ScannerAvailabilityRepo {
  final ApiService _apiService;
  ScannerAvailabilityRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  // ---- weekly rules ----

  Future<Either<Failure, List<ScannerAvailabilityRuleModel>>> getRules() async {
    try {
      final rules = await _apiService.getScannerRules(token: _token);

      log('Fetched ${rules.length} scanner rules');
      return right(rules);
    } on DioException catch (e) {
      log('DioException while fetching scanner rules: ${e.message}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedScannerRulesList,
        fromJson: ScannerAvailabilityRuleModel.fromJson,
        onFailure: () => ServerFailure.FromDioExecption(e),
      );
    } catch (e) {
      log('General Exception while fetching scanner rules: ${e.toString()}');
      return fallbackToCache(
        cacheKey: CacheKeys.cachedScannerRulesList,
        fromJson: ScannerAvailabilityRuleModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
    }
  }

  Future<Either<Failure, ScannerAvailabilityRuleModel>> createRule(
    SaveScannerAvailabilityRuleRequestModel saveRequestBody,
  ) async {
    try {
      final rule = await _apiService.createScannerRule(
        saveRequestBody: saveRequestBody,
        token: _token,
      );

      log('Created scanner rule for day ${rule.dayOfWeek}');
      return right(rule);
    } on DioException catch (e) {
      log('DioException while creating scanner rule: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while creating scanner rule: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, ScannerAvailabilityRuleModel>> updateRule({
    required String id,
    required SaveScannerAvailabilityRuleRequestModel saveRequestBody,
  }) async {
    try {
      final rule = await _apiService.updateScannerRule(
        id: id,
        saveRequestBody: saveRequestBody,
        token: _token,
      );

      log('Updated scanner rule: $id');
      return right(rule);
    } on DioException catch (e) {
      log('DioException while updating scanner rule: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while updating scanner rule: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteRule(String id) async {
    try {
      await _apiService.deleteScannerRule(id: id, token: _token);

      log('Deleted scanner rule: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting scanner rule: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while deleting scanner rule: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  // ---- date exceptions ----

  Future<Either<Failure, List<ScannerAvailabilityExceptionModel>>>
  getExceptions({required DateTime from, required DateTime to}) async {
    try {
      final exceptions = await _apiService.getScannerExceptions(
        from: ApiTime.formatDate(from),
        to: ApiTime.formatDate(to),
        token: _token,
      );

      log('Fetched ${exceptions.length} scanner exceptions');
      return right(exceptions);
    } on DioException catch (e) {
      log('DioException while fetching scanner exceptions: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log(
        'General Exception while fetching scanner exceptions: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, ScannerAvailabilityExceptionModel>> saveException(
    SaveScannerAvailabilityExceptionRequestModel saveRequestBody,
  ) async {
    try {
      final exception = await _apiService.saveScannerException(
        saveRequestBody: saveRequestBody,
        token: _token,
      );

      log('Saved scanner exception for ${exception.dateLabel}');
      return right(exception);
    } on DioException catch (e) {
      log('DioException while saving scanner exception: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while saving scanner exception: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteException(String id) async {
    try {
      await _apiService.deleteScannerException(id: id, token: _token);

      log('Deleted scanner exception: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting scanner exception: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log(
        'General Exception while deleting scanner exception: ${e.toString()}',
      );
      return left(ServerFailure.fromException(e));
    }
  }

  // ---- resolved calendar ----

  Future<Either<Failure, List<ScannerDayModel>>> getCalendar({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final days = await _apiService.getScannerCalendar(
        from: ApiTime.formatDate(from),
        to: ApiTime.formatDate(to),
        token: _token,
      );

      log('Fetched ${days.length} scanner calendar days');
      return right(days);
    } on DioException catch (e) {
      log('DioException while fetching scanner calendar: ${e.message}');
      return left(ServerFailure.FromDioExecption(e));
    } catch (e) {
      log('General Exception while fetching scanner calendar: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
