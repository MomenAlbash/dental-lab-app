import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/currencies/data/models/save_currency_request_models.dart';
import 'package:dental_lab_app/features/currencies/data/repos/currencies_repo.dart';
import 'package:dental_lab_app/features/currencies/logic/currencies/currencies_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CurrenciesCubit extends Cubit<CurrenciesState> {
  CurrenciesCubit(this._currenciesRepo) : super(const CurrenciesInitial());

  final CurrenciesRepo _currenciesRepo;

  Future<void> getCurrencies() async {
    emit(const CurrenciesLoading());

    final result = await _currenciesRepo.getCurrencies();

    result.fold(
      (failure) => emit(CurrenciesError(failure.errorMessage)),
      (currencies) => emit(CurrenciesLoaded(currencies)),
    );
  }

  List<CurrencyModel> get _currentList => switch (state) {
    CurrenciesLoaded(:final currencies) => currencies,
    _ => const [],
  };

  Future<void> addCurrency(CreateCurrencyRequestModel requestBody) async {
    final currencies = _currentList;
    emit(CurrenciesLoaded(currencies, isBusy: true));

    final result = await _currenciesRepo.createCurrency(requestBody);

    result.fold((failure) {
      emit(CurrenciesActionError(failure.errorMessage));
      emit(CurrenciesLoaded(currencies));
    }, (created) => emit(CurrenciesLoaded([...currencies, created])));
  }

  Future<void> editCurrency({
    required String id,
    required UpdateCurrencyRequestModel requestBody,
  }) async {
    final currencies = _currentList;
    emit(CurrenciesLoaded(currencies, isBusy: true));

    final result = await _currenciesRepo.updateCurrency(
      id: id,
      requestBody: requestBody,
    );

    result.fold(
      (failure) {
        emit(CurrenciesActionError(failure.errorMessage));
        emit(CurrenciesLoaded(currencies));
      },
      (updated) => emit(
        CurrenciesLoaded([
          for (final c in currencies)
            if (c.id == id) updated else c,
        ]),
      ),
    );
  }

  Future<void> removeCurrency(String id) async {
    final currencies = _currentList;
    emit(CurrenciesLoaded(currencies, isBusy: true));

    final result = await _currenciesRepo.deleteCurrency(id);

    result.fold(
      (failure) {
        emit(CurrenciesActionError(failure.errorMessage));
        emit(CurrenciesLoaded(currencies));
      },
      (_) =>
          emit(CurrenciesLoaded(currencies.where((c) => c.id != id).toList())),
    );
  }
}
