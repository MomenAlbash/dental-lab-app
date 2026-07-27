/// A restoration line on a create/update case request
/// (`ClinicRestorationRequest`). Only [restorationTypeId] is required.
class CaseRestorationRequestModel {
  final String restorationTypeId;
  final int? quantity;
  final double? unitPrice;
  final String? currencyId;
  final double? discountValue;
  final double? discountPercentage;
  final String? shadeCervical;
  final String? shadeMiddle;
  final String? shadeIncisal;
  final String? baseToothColor;
  final String? alloyType;
  final String? notes;

  CaseRestorationRequestModel({
    required this.restorationTypeId,
    this.quantity,
    this.unitPrice,
    this.currencyId,
    this.discountValue,
    this.discountPercentage,
    this.shadeCervical,
    this.shadeMiddle,
    this.shadeIncisal,
    this.baseToothColor,
    this.alloyType,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'restorationTypeId': restorationTypeId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'currencyId': currencyId,
      'discountValue': discountValue,
      'discountPercentage': discountPercentage,
      'shadeCervical': shadeCervical,
      'shadeMiddle': shadeMiddle,
      'shadeIncisal': shadeIncisal,
      'baseToothColor': baseToothColor,
      'alloyType': alloyType,
      'notes': notes,
    };
  }
}
