import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// One month's row in a currency's جدوى اقتصادية series
/// (`MonthlyFeasibilityPointDto`).
class MonthlyFeasibilityPointModel {
  const MonthlyFeasibilityPointModel({
    this.month,
    this.revenue = 0,
    this.expenses = 0,
    this.purchases = 0,
    this.payrollCost = 0,
    this.netProfit = 0,
    this.cumulativeCash = 0,
  });

  /// First day of the month, e.g. 2026-07-01.
  final DateTime? month;

  /// Actual cash collected (verified payments) — not invoiced/accrued
  /// revenue.
  final double revenue;
  final double expenses;
  final double purchases;
  final double payrollCost;

  /// revenue − (expenses + purchases + payrollCost), for this month alone.
  final double netProfit;

  /// Running total of [netProfit] from the first month in the series through
  /// this one — "الصندوق". Its sign is what "healthy or not" asks about, not
  /// its size.
  final double cumulativeCash;

  factory MonthlyFeasibilityPointModel.fromJson(Map<String, dynamic> json) {
    return MonthlyFeasibilityPointModel(
      month: DateTime.tryParse(json['month'] as String? ?? ''),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
      purchases: (json['purchases'] as num?)?.toDouble() ?? 0,
      payrollCost: (json['payrollCost'] as num?)?.toDouble() ?? 0,
      netProfit: (json['netProfit'] as num?)?.toDouble() ?? 0,
      cumulativeCash: (json['cumulativeCash'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// One currency's whole series (`FeasibilityCurrencySeriesDto`) — money in
/// different currencies can never be netted into one number, so each gets
/// its own list of months.
class FeasibilityCurrencySeriesModel {
  const FeasibilityCurrencySeriesModel({this.currency, this.points = const []});

  final CurrencyModel? currency;
  final List<MonthlyFeasibilityPointModel> points;

  factory FeasibilityCurrencySeriesModel.fromJson(Map<String, dynamic> json) {
    return FeasibilityCurrencySeriesModel(
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      points:
          (json['points'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(MonthlyFeasibilityPointModel.fromJson)
              .toList() ??
          const [],
    );
  }
}

/// The lab's monthly جدوى اقتصادية (`MonthlyFeasibilityDto`,
/// `GET /store/feasibility`) — one series per currency.
class MonthlyFeasibilityModel {
  const MonthlyFeasibilityModel({this.currencies = const []});

  final List<FeasibilityCurrencySeriesModel> currencies;

  factory MonthlyFeasibilityModel.fromJson(Map<String, dynamic> json) {
    return MonthlyFeasibilityModel(
      currencies:
          (json['currencies'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(FeasibilityCurrencySeriesModel.fromJson)
              .toList() ??
          const [],
    );
  }
}
