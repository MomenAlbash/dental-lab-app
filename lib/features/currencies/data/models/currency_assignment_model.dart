import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// Which currencies a laboratory — or one clinic under it — actually trades in
/// (`ClinicCurrencyAssignmentDto`).
///
/// Not the same thing as the currency catalogue: the catalogue is every
/// currency that exists, this is the short list a form should offer. Quoting a
/// doctor in a currency their clinic does not settle in is a pricing error
/// that only surfaces at invoice time.
class CurrencyAssignmentModel {
  const CurrencyAssignmentModel({
    this.currencies = const [],
    this.defaultCurrencyId,
    this.isInherited = false,
  });

  final List<CurrencyModel> currencies;

  /// Pre-selected in forms. Null means the lab never named one, so a form must
  /// ask rather than silently pick the first row — this app never blends
  /// currencies, and guessing the wrong one is guessing the price.
  final String? defaultCurrencyId;

  /// Whether this set is the laboratory's, shown through rather than the
  /// clinic's own. **The distinction is the feature**: an inherited set follows
  /// later edits to the lab, while an override freezes whatever it said the
  /// day it was set, so a screen that cannot tell them apart cannot tell the
  /// user which of those two they are about to get.
  ///
  /// Always false on the laboratory's own assignment — there is nothing above
  /// it to inherit from.
  final bool isInherited;

  CurrencyModel? get defaultCurrency {
    final id = defaultCurrencyId;
    if (id == null) return null;
    for (final currency in currencies) {
      if (currency.id == id) return currency;
    }
    // Named a currency that is no longer in the set — a real state after a
    // currency is removed, and reporting it as "none chosen" is more honest
    // than inventing a different default.
    return null;
  }

  factory CurrencyAssignmentModel.fromJson(Map<String, dynamic> json) {
    return CurrencyAssignmentModel(
      currencies: [
        for (final entry in json['currencies'] as List<dynamic>? ?? const [])
          if (entry is Map<String, dynamic>) CurrencyModel.fromJson(entry),
      ],
      defaultCurrencyId: json['defaultCurrencyId'] as String?,
      isInherited: json['isInherited'] as bool? ?? false,
    );
  }
}

/// `PUT /Currencies/laboratory` (`ClinicSetLaboratoryCurrenciesRequest`).
///
/// The list **replaces** the lab's set. [defaultCurrencyId] must be one of
/// [currencyIds] — naming a default outside the set is what leaves forms
/// pre-selecting a currency the lab cannot invoice in.
class SetLaboratoryCurrenciesRequestModel {
  const SetLaboratoryCurrenciesRequestModel({
    required this.currencyIds,
    this.defaultCurrencyId,
  });

  final List<String> currencyIds;
  final String? defaultCurrencyId;

  Map<String, dynamic> toJson() => {
    'currencyIds': currencyIds,
    'defaultCurrencyId': defaultCurrencyId,
  };
}

/// `PUT /Currencies/clinic/{clinicId}` (`ClinicSetClinicCurrenciesRequest`).
///
/// No default of its own — a clinic narrows which of the lab's currencies it
/// trades in; which one a form pre-selects stays the laboratory's call.
///
/// An **empty list clears the override** and returns the clinic to inheriting
/// the lab's set, which is why the field is never omitted: sending nothing and
/// sending an empty list must not mean the same thing.
class SetClinicCurrenciesRequestModel {
  const SetClinicCurrenciesRequestModel({required this.currencyIds});

  final List<String> currencyIds;

  Map<String, dynamic> toJson() => {'currencyIds': currencyIds};
}
