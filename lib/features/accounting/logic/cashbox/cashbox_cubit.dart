import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/accounting/data/models/cashbox_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/cashbox/cashbox_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The laboratory's cash drawer: one ledger per currency, its opening
/// balances, and the manual movements a user may add or take back.
class CashboxCubit extends Cubit<CashboxState> {
  CashboxCubit(this._repo) : super(const CashboxInitial());

  final AccountingRepo _repo;

  DateTime? _from;
  DateTime? _to;

  DateTime? get from => _from;
  DateTime? get to => _to;

  Future<void> load({DateTime? from, DateTime? to, bool resetWindow = false}) async {
    if (resetWindow) {
      _from = null;
      _to = null;
    } else {
      _from = from ?? _from;
      _to = to ?? _to;
    }

    emit(const CashboxLoading());

    // The opening balances are a second read rather than part of the ledger:
    // a currency the lab has set a balance for but had no movement in this
    // window still has a box, and only this list knows about it.
    final ledgerRequest = _repo.getCashboxLedger(from: _from, to: _to);
    final balancesRequest = _repo.getCashboxOpeningBalances();
    final currenciesRequest = _repo.getCurrencies();

    final ledgers = await ledgerRequest;
    final balances = await balancesRequest;
    final currencies = await currenciesRequest;
    if (isClosed) return;

    ledgers.fold((failure) => emit(CashboxError(failure.errorMessage)), (
      list,
    ) {
      emit(
        CashboxLoaded(
          ledgers: list,
          // A failed balances or currencies read leaves the ledger readable:
          // both are context for it, not the thing itself. The forms then open
          // with an empty picker rather than the screen refusing to draw.
          openingBalances: balances.fold((_) => const [], (b) => b),
          currencies: currencies.fold((_) => const [], (c) => c),
          from: _from,
          to: _to,
        ),
      );
    });
  }

  Future<void> addEntry(CreateCashBoxEntryRequestModel body) => _write(
    'تم تسجيل الحركة',
    () => _repo.createCashboxEntry(body),
  );

  Future<void> deleteEntry(String id) =>
      _write('تم حذف الحركة', () => _repo.deleteCashboxEntry(id));

  Future<void> setOpeningBalance(SetCashBoxOpeningBalanceRequestModel body) =>
      _write(
        'تم تعيين الرصيد الافتتاحي',
        () => _repo.setCashboxOpeningBalance(body),
      );

  /// Every write reloads afterwards: each one changes a running balance that
  /// every line below it carries, so recomputing on the client would be
  /// re-deriving what the ledger endpoint exists to answer.
  Future<void> _write<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() request,
  ) async {
    final current = state;
    if (current is CashboxLoaded) emit(current.copyWith(isBusy: true));

    final result = await request();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(CashboxActionError(failure.errorMessage));
        if (current is CashboxLoaded) emit(current);
      },
      (_) async {
        emit(CashboxActionSuccess(successMessage));
        await load();
      },
    );
  }
}
