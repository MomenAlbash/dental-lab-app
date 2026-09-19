import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/expense_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/expenses/expenses_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExpensesCubit extends Cubit<ExpensesState> {
  ExpensesCubit(this._accountingRepo) : super(const ExpensesInitial());

  final AccountingRepo _accountingRepo;

  Future<void> getExpenses() async {
    emit(const ExpensesLoading());

    final expensesResult = await _accountingRepo.getExpenses();
    if (expensesResult.isLeft()) {
      emit(
        ExpensesError(expensesResult.fold((f) => f.errorMessage, (_) => '')),
      );
      return;
    }
    final expenses = expensesResult.fold(
      (_) => const <ExpenseModel>[],
      (e) => e,
    );

    // Currencies feed the add-expense dialog's picker; a failure here should
    // not block seeing the list that already loaded, so it just leaves the
    // picker empty rather than surfacing as its own error.
    final currenciesResult = await _accountingRepo.getCurrencies();
    final currencies = currenciesResult.fold(
      (_) => const <CurrencyModel>[],
      (c) => c,
    );

    emit(ExpensesLoaded(expenses, currencies: currencies));
  }

  List<CurrencyModel> get _currencies => switch (state) {
    ExpensesLoaded(:final currencies) => currencies,
    _ => const [],
  };

  Future<void> addExpense(CreateExpenseRequestModel requestBody) async {
    final state = this.state;
    if (state is! ExpensesLoaded) return;
    final expenses = state.expenses;
    final currencies = _currencies;

    emit(ExpensesLoaded(expenses, currencies: currencies, isBusy: true));

    final result = await _accountingRepo.createExpense(requestBody);

    result.fold(
      (failure) {
        emit(ExpensesActionError(failure.errorMessage));
        emit(ExpensesLoaded(expenses, currencies: currencies));
      },
      (created) =>
          emit(ExpensesLoaded([created, ...expenses], currencies: currencies)),
    );
  }
}
