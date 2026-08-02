import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';

/// A restoration line on a create/update case request
/// (`ClinicRestorationRequest`). Only [restorationTypeId] is required. The
/// shade/color fields ([shadeCervical], [shadeMiddle], [shadeIncisal],
/// [baseToothColor]) belong to this restoration specifically — each
/// restoration in a case can have its own.
class CaseRestorationRequestModel {
  final String restorationTypeId;
  final int? quantity;
  final double? unitPrice;
  final String? currencyId;
  final double? discountValue;
  final double? discountPercentage;
  final String? shadeLayout;
  final String? shadeCervical;
  final String? shadeMiddle;
  final String? shadeIncisal;
  final String? baseToothColor;
  final String? notes;
  final List<ToothMarkModel> teeth;

  CaseRestorationRequestModel({
    required this.restorationTypeId,
    this.quantity,
    this.unitPrice,
    this.currencyId,
    this.discountValue,
    this.discountPercentage,
    this.shadeLayout,
    this.shadeCervical,
    this.shadeMiddle,
    this.shadeIncisal,
    this.baseToothColor,
    this.notes,
    this.teeth = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'restorationTypeId': restorationTypeId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'currencyId': currencyId,
      'discountValue': discountValue,
      'discountPercentage': discountPercentage,
      'shadeLayout': shadeLayout,
      'shadeCervical': shadeCervical,
      'shadeMiddle': shadeMiddle,
      'shadeIncisal': shadeIncisal,
      'baseToothColor': baseToothColor,
      'notes': notes,
      'teeth': teeth.map((t) => t.toJson()).toList(),
    };
  }
}
