import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_currency_price_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';

/// One restoration type, priced for a specific doctor
/// (`DoctorRestorationTypeLookupDto`, `GET /RestorationTypes/lookup`).
///
/// This is the catalog a case-creation form must quote from — [effectivePrice]
/// is the doctor's own negotiated/tier rate, resolved server-side by the same
/// service that prices the case on submission. Quoting the plain catalog's
/// list price instead is the one pricing bug a lab never forgives: the form
/// and the invoice would disagree.
class DoctorRestorationTypeLookupModel {
  const DoctorRestorationTypeLookupModel({
    required this.id,
    this.name,
    this.nameAr,
    required this.listPrice,
    this.listCurrency,
    required this.effectivePrice,
    this.effectiveCurrency,
    this.availablePrices = const [],
    this.isPriceUnavailable = false,
    this.pricingType,
    this.imagePath,
  });

  final String id;
  final String? name;
  final String? nameAr;

  /// The lab's own catalogue price, never tier-overridden. Kept beside
  /// [effectivePrice] so a screen can show "٥٠٠ ~~٦٠٠~~" where a doctor's
  /// rate beats list.
  final double listPrice;
  final CurrencyModel? listCurrency;

  /// What THIS doctor actually pays — their negotiated price, their tier's,
  /// or list when neither applies. What the case form must quote.
  final double effectivePrice;
  final CurrencyModel? effectiveCurrency;

  /// Every currency this type is actually priced in on the doctor's resolved
  /// tier — the set a currency picker should offer.
  final List<RestorationCurrencyPriceModel> availablePrices;

  /// Nothing prices this type in any currency the doctor may be quoted in.
  /// The type is shown so the case is aware the lab makes it, but cannot be
  /// ordered until someone at the lab prices it.
  final bool isPriceUnavailable;

  final int? pricingType;
  final String? imagePath;

  String get displayName {
    final ar = nameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return name?.trim() ?? '—';
  }

  factory DoctorRestorationTypeLookupModel.fromJson(Map<String, dynamic> json) {
    return DoctorRestorationTypeLookupModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      listPrice: (json['listPrice'] as num?)?.toDouble() ?? 0,
      listCurrency: json['listCurrency'] == null
          ? null
          : CurrencyModel.fromJson(
              json['listCurrency'] as Map<String, dynamic>,
            ),
      effectivePrice: (json['effectivePrice'] as num?)?.toDouble() ?? 0,
      effectiveCurrency: json['effectiveCurrency'] == null
          ? null
          : CurrencyModel.fromJson(
              json['effectiveCurrency'] as Map<String, dynamic>,
            ),
      availablePrices:
          (json['availablePrices'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(RestorationCurrencyPriceModel.fromJson)
              .toList() ??
          const [],
      isPriceUnavailable: json['isPriceUnavailable'] as bool? ?? false,
      pricingType: json['pricingType'] as int?,
      imagePath: json['imagePath'] as String?,
    );
  }

  /// Reshaped into a [RestorationTypeModel] so the rest of the case form
  /// (type dropdown, currency/price gating in `AddRestorationPage`) can work
  /// off one shape regardless of which catalog fed it — the doctor's priced
  /// lookup when a doctor is chosen, the plain admin list otherwise.
  RestorationTypeModel toRestorationTypeModel() => RestorationTypeModel(
    id: id,
    name: name,
    nameAr: nameAr,
    prices: availablePrices,
    pricingType: pricingType,
  );
}
