import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/accounting_statistics/accounting_statistics_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountingStatisticsCubit extends Cubit<AccountingStatisticsState> {
  AccountingStatisticsCubit(this._accountingRepo)
    : super(const AccountingStatisticsInitial());

  final AccountingRepo _accountingRepo;

  Future<void> getStatistics() async {
    emit(const AccountingStatisticsLoading());

    final result = await _accountingRepo.getStatistics();

    result.fold(
      (failure) => emit(AccountingStatisticsError(failure.errorMessage)),
      (statistics) => emit(AccountingStatisticsLoaded(statistics)),
    );
  }
}
