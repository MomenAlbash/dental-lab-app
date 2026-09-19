import 'package:dental_lab_app/features/cases/data/models/shade_codes.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';

/// A restoration line on a create/update case request
/// (`ClinicRestorationRequest`). Only [restorationTypeId] is required. The
/// shade/color fields ([shadeCervical], [shadeMiddle], [shadeIncisal],
/// [baseToothColor]) belong to this restoration specifically — each
/// restoration in a case can have its own.
///
/// [shadeLayout] carries the guide label (`'Vita Classical'` /
/// `'Vita 3D-Master'`) the way every screen already works with it; [toJson]
/// is where it — and every shade label — is encoded to the [ShadeCodes]
/// integer enums the API actually expects (`shadeSystem`, `ToothShade`,
/// `BaseShade`). Sending the labels themselves is what used to fail with a
/// 400 the moment a shade was picked.
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

  /// The optional stages of this restoration's own route that the case opted
  /// into (`restorationTypeStageIds`).
  ///
  /// Per restoration, not per case: two units of different types can be
  /// offered different optional stages, and the one that does not run a stage
  /// must not be sent its id.
  final List<String> restorationTypeStageIds;

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
    this.restorationTypeStageIds = const [],
  });

  Map<String, dynamic> toJson() {
    final shadeSystem = ShadeCodes.shadeSystemFor(shadeLayout);
    final baseShadeCode = ShadeCodes.baseShadeCode(baseToothColor);

    return {
      'restorationTypeId': restorationTypeId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'currencyId': currencyId,
      'discountValue': discountValue,
      'discountPercentage': discountPercentage,
      'shadeSystem': shadeSystem,
      'shadeCervical': ShadeCodes.toothShadeCode(shadeSystem, shadeCervical),
      'shadeMiddle': ShadeCodes.toothShadeCode(shadeSystem, shadeMiddle),
      'shadeIncisal': ShadeCodes.toothShadeCode(shadeSystem, shadeIncisal),
      // The request DTO carries both `baseShade` (the field the response
      // reads back) and a legacy `baseToothColor` duplicate — both are sent
      // with the same value so either one being the one actually persisted
      // still works.
      'baseShade': baseShadeCode,
      'baseToothColor': baseShadeCode,
      'notes': notes,
      'teeth': teeth.map((t) => t.toJson()).toList(),
      'restorationTypeStageIds': restorationTypeStageIds,
    };
  }
}
