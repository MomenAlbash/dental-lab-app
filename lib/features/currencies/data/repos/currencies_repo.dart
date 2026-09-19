import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/lookup_api.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/currencies/data/models/currency_assignment_model.dart';
import 'package:dental_lab_app/features/currencies/data/models/save_currency_request_models.dart';
import 'package:dio/dio.dart';

class CurrenciesRepo {
  CurrenciesRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, List<CurrencyModel>>> getCurrencies() async {
    try {
      final currencies = await _apiService.getCurrencies(token: _token);

      log('Fetched ${currencies.length} currencies');
      return right(currencies);
    } on DioException catch (e) {
      log('DioException while fetching currencies: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching currencies: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CurrencyModel>> createCurrency(
    CreateCurrencyRequestModel requestBody,
  ) async {
    try {
      final currency = await _apiService.createCurrency(
        createRequestBody: requestBody,
        token: _token,
      );

      log('Created currency: ${currency.name}');
      return right(currency);
    } on DioException catch (e) {
      log('DioException while creating currency: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while creating currency: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CurrencyModel>> updateCurrency({
    required String id,
    required UpdateCurrencyRequestModel requestBody,
  }) async {
    try {
      final currency = await _apiService.updateCurrency(
        id: id,
        updateRequestBody: requestBody,
        token: _token,
      );

      log('Updated currency: $id');
      return right(currency);
    } on DioException catch (e) {
      log('DioException while updating currency: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while updating currency: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  // ---- Assignment -------------------------------------------------------
  //
  // Which currencies are actually traded in, as opposed to the catalogue of
  // every currency that exists above. Quoting a doctor in a currency their
  // clinic does not settle in is a pricing error that only surfaces at
  // invoice time.

  Future<Either<Failure, T>> _guard<T>(
    String what,
    Future<T> Function() request,
  ) async {
    try {
      return right(await request());
    } on DioException catch (e) {
      log('DioException while $what: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while $what: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CurrencyAssignmentModel>> getLaboratoryCurrencies() =>
      _guard(
        'fetching laboratory currencies',
        () => _apiService.getLaboratoryCurrencies(token: _token),
      );

  /// Replaces the lab's set. [SetLaboratoryCurrenciesRequestModel.defaultCurrencyId]
  /// must be one of the ids sent — a default outside the set leaves forms
  /// pre-selecting a currency the lab cannot invoice in.
  Future<Either<Failure, CurrencyAssignmentModel>> setLaboratoryCurrencies(
    SetLaboratoryCurrenciesRequestModel body,
  ) => _guard(
    'setting laboratory currencies',
    () => _apiService.setLaboratoryCurrencies(body: body, token: _token),
  );

  /// The clinic's own narrowed set, or the laboratory's shown through with
  /// `isInherited` set.
  Future<Either<Failure, CurrencyAssignmentModel>> getClinicCurrencies(
    String clinicId,
  ) => _guard(
    'fetching clinic currencies',
    () => _apiService.getClinicCurrencies(clinicId: clinicId, token: _token),
  );

  /// Narrows a clinic to a subset of the lab's currencies. An empty list
  /// clears the override and returns the clinic to inheriting.
  Future<Either<Failure, CurrencyAssignmentModel>> setClinicCurrencies({
    required String clinicId,
    required SetClinicCurrenciesRequestModel body,
  }) => _guard(
    'setting clinic currencies',
    () => _apiService.setClinicCurrencies(
      clinicId: clinicId,
      body: body,
      token: _token,
    ),
  );

  Future<Either<Failure, void>> deleteCurrency(String id) async {
    try {
      await _apiService.deleteCurrency(id: id, token: _token);
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting currency: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting currency: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }
}
