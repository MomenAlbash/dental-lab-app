import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// `AccountingCurrencyStatisticsDto` — one currency's slice of the lab's
/// books. Amounts are never converted or summed across currencies (there is
/// no shared unit to sum them in), so the overview shows one card per
/// currency instead of a single grand total.
class AccountingCurrencyStatisticsModel {
  const AccountingCurrencyStatisticsModel({
    this.currency,
    this.invoiced = 0,
    this.paid = 0,
    this.outstanding = 0,
    this.verifiedPayments = 0,
    this.pendingPayments = 0,
    this.expenses = 0,
    this.netCash = 0,
  });

  final CurrencyModel? currency;
  final double invoiced;
  final double paid;
  final double outstanding;
  final double verifiedPayments;
  final double pendingPayments;
  final double expenses;
  final double netCash;

  factory AccountingCurrencyStatisticsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AccountingCurrencyStatisticsModel(
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      invoiced: (json['invoiced'] as num?)?.toDouble() ?? 0,
      paid: (json['paid'] as num?)?.toDouble() ?? 0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
      verifiedPayments: (json['verifiedPayments'] as num?)?.toDouble() ?? 0,
      pendingPayments: (json['pendingPayments'] as num?)?.toDouble() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
      netCash: (json['netCash'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// `AccountingStatisticsDto`.
class AccountingStatisticsModel {
  const AccountingStatisticsModel({
    this.invoiceCount = 0,
    this.paymentCount = 0,
    this.pendingPaymentCount = 0,
    this.currencies = const [],
  });

  final int invoiceCount;
  final int paymentCount;
  final int pendingPaymentCount;
  final List<AccountingCurrencyStatisticsModel> currencies;

  factory AccountingStatisticsModel.fromJson(Map<String, dynamic> json) {
    final rawCurrencies = json['currencies'] as List<dynamic>? ?? const [];

    return AccountingStatisticsModel(
      invoiceCount: json['invoiceCount'] as int? ?? 0,
      paymentCount: json['paymentCount'] as int? ?? 0,
      pendingPaymentCount: json['pendingPaymentCount'] as int? ?? 0,
      currencies: rawCurrencies
          .whereType<Map<String, dynamic>>()
          .map(AccountingCurrencyStatisticsModel.fromJson)
          .toList(),
    );
  }
}
