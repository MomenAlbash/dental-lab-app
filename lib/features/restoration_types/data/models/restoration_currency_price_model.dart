import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// One currency a restoration type is priced in (`RestorationCurrencyPriceDto`).
///
/// A case-creation form offers only the currencies a type actually has a row
/// for here — picking any other currency has no price behind it and the
/// server refuses the case.
class RestorationCurrencyPriceModel {
  const RestorationCurrencyPriceModel({
    this.currencyId,
    this.currency,
    required this.price,
  });

  final String? currencyId;
  final CurrencyModel? currency;
  final double price;

  String get currencyLabel =>
      currency?.name ?? currency?.code ?? currency?.symbol ?? '—';

  factory RestorationCurrencyPriceModel.fromJson(Map<String, dynamic> json) {
    return RestorationCurrencyPriceModel(
      currencyId: json['currencyId'] as String?,
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
