import 'package:dental_lab_app/features/accounting/data/models/accounting_statistics_model.dart';

sealed class AccountingStatisticsState {
  const AccountingStatisticsState();
}

class AccountingStatisticsInitial extends AccountingStatisticsState {
  const AccountingStatisticsInitial();
}

class AccountingStatisticsLoading extends AccountingStatisticsState {
  const AccountingStatisticsLoading();
}

class AccountingStatisticsLoaded extends AccountingStatisticsState {
  const AccountingStatisticsLoaded(this.statistics);
  final AccountingStatisticsModel statistics;
}

class AccountingStatisticsError extends AccountingStatisticsState {
  const AccountingStatisticsError(this.message);
  final String message;
}
