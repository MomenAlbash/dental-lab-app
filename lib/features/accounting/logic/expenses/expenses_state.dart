import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/expense_model.dart';

sealed class ExpensesState {
  const ExpensesState();
}

class ExpensesInitial extends ExpensesState {
  const ExpensesInitial();
}

class ExpensesLoading extends ExpensesState {
  const ExpensesLoading();
}

class ExpensesLoaded extends ExpensesState {
  const ExpensesLoaded(
    this.expenses, {
    this.currencies = const [],
    this.isBusy = false,
  });

  final List<ExpenseModel> expenses;

  /// Loaded once alongside the list, for the add-expense dialog's currency
  /// picker — a second round trip on every "add" tap would be wasteful.
  final List<CurrencyModel> currencies;

  /// True while a create is in flight.
  final bool isBusy;
}

class ExpensesError extends ExpensesState {
  const ExpensesError(this.message);
  final String message;
}

/// Transient failure of a create — surfaced as a toast.
class ExpensesActionError extends ExpensesState {
  const ExpensesActionError(this.message);
  final String message;
}
