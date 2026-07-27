import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';

/// A restoration line as returned on a case (`ClinicCaseRestorationDto`).
class CaseRestorationModel {
  final String id;
  final RestorationTypeModel? restorationType;
  final int quantity;
  final double? unitPrice;
  final String? currencyName;
  final double? discountValue;
  final double? discountPercentage;
  final String? shadeCervical;
  final String? shadeMiddle;
  final String? shadeIncisal;
  final String? baseToothColor;
  final String? alloyType;
  final String? notes;

  CaseRestorationModel({
    required this.id,
    this.restorationType,
    this.quantity = 1,
    this.unitPrice,
    this.currencyName,
    this.discountValue,
    this.discountPercentage,
    this.shadeCervical,
    this.shadeMiddle,
    this.shadeIncisal,
    this.baseToothColor,
    this.alloyType,
    this.notes,
  });

  String get restorationName => restorationType?.displayName ?? '—';

  factory CaseRestorationModel.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as Map<String, dynamic>?;
    return CaseRestorationModel(
      id: json['id'] as String,
      restorationType: json['restorationType'] == null
          ? null
          : RestorationTypeModel.fromJson(
              json['restorationType'] as Map<String, dynamic>,
            ),
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      currencyName:
          (currency?['code'] ?? currency?['name'] ?? currency?['symbol'])
              as String?,
      discountValue: (json['discountValue'] as num?)?.toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      shadeCervical: json['shadeCervical'] as String?,
      shadeMiddle: json['shadeMiddle'] as String?,
      shadeIncisal: json['shadeIncisal'] as String?,
      baseToothColor: json['baseToothColor'] as String?,
      alloyType: json['alloyType'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
