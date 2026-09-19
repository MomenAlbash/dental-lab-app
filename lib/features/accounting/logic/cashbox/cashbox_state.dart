import 'package:dental_lab_app/features/accounting/data/models/cashbox_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

sealed class CashboxState {
  const CashboxState();
}

class CashboxInitial extends CashboxState {
  const CashboxInitial();
}

class CashboxLoading extends CashboxState {
  const CashboxLoading();
}

class CashboxError extends CashboxState {
  const CashboxError(this.message);
  final String message;
}

/// The drawer, one ledger per currency.
class CashboxLoaded extends CashboxState {
  const CashboxLoaded({
    required this.ledgers,
    this.openingBalances = const [],
    this.currencies = const [],
    this.from,
    this.to,
    this.isBusy = false,
  });

  /// Never summed together: each currency is its own box.
  final List<CashBoxLedgerModel> ledgers;

  final List<CashBoxOpeningBalanceModel> openingBalances;

  /// Feeds the pickers on the two forms. A currency the box has never held is
  /// still a currency a movement can be recorded in, so this is the whole
  /// catalogue rather than the currencies already on the ledger.
  final List<CurrencyModel> currencies;

  /// The window the ledger was read over. Null means the server's default.
  final DateTime? from;
  final DateTime? to;

  /// A write is in flight — the actions disable rather than the screen
  /// blanking, so the numbers stay readable while one is being added.
  final bool isBusy;

  CashboxLoaded copyWith({bool? isBusy}) => CashboxLoaded(
    ledgers: ledgers,
    openingBalances: openingBalances,
    currencies: currencies,
    from: from,
    to: to,
    isBusy: isBusy ?? this.isBusy,
  );
}

/// A write went through — the screen toasts and reloads.
class CashboxActionSuccess extends CashboxState {
  const CashboxActionSuccess(this.message);
  final String message;
}

/// A write was refused. Carries the server's own sentence: the five-minute
/// window and the admin bypass are its rules, and a generic "failed" hides
/// which one was hit.
class CashboxActionError extends CashboxState {
  const CashboxActionError(this.message);
  final String message;
}
