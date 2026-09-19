import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_status_history_model.dart';
import 'package:dental_lab_app/features/cases/data/models/shade_codes.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';

/// A restoration line as returned on a case (`ClinicCaseRestorationDto`).
/// Stage tracking lives here (per-restoration), not on the case itself.
///
/// The API stores shades as [ShadeCodes] integer enums (`shadeSystem`,
/// `ToothShade`, `BaseShade`) — [shadeLayout], [shadeCervical],
/// [shadeMiddle], [shadeIncisal] and [baseToothColor] are decoded to the
/// display labels here, at the JSON boundary, so nothing above this file has
/// to know the wire format.
class CaseRestorationModel {
  final String id;

  /// The number printed on the piece.s own label — what a scanner resolves
  /// through `/Cases/restorations/by-number/{n}`.
  final String? restorationNumber;

  /// The type's id as a flat field. Kept alongside [restorationType] because
  /// the expanded object is one of the things the API trims on a restricted
  /// response, and the route lookup needs only the id.
  final String? restorationTypeId;

  final RestorationTypeModel? restorationType;
  final int quantity;
  final double? unitPrice;
  final String? currencyName;
  final double? discountValue;
  final double? discountPercentage;
  final String? shadeLayout;
  final String? shadeCervical;
  final String? shadeMiddle;
  final String? shadeIncisal;
  final String? baseToothColor;
  final String? notes;
  final List<ToothMarkModel> teeth;
  final String? currentStageId;
  final CaseWorkflowStageModel? currentStage;
  final int orderNum;

  /// This restoration has nothing left to make — every stage it holds is on
  /// the last step of its route. Computed server-side and must be read as-is,
  /// never recomputed from [currentStage]: "last" is a fact about the whole
  /// route (nothing numbered after it), which a client holding only one
  /// stage cannot work out — and a restoration on a parallel step can be
  /// holding more than one stage at once, which [currentStageId] alone does
  /// not capture either.
  final bool isFinished;

  /// The restoration's stage timeline — one entry per stage change.
  final List<CaseRestorationStatusHistoryModel> statusHistory;

  CaseRestorationModel({
    required this.id,
    this.restorationNumber,
    this.restorationTypeId,
    this.restorationType,
    this.quantity = 1,
    this.unitPrice,
    this.currencyName,
    this.discountValue,
    this.discountPercentage,
    this.shadeLayout,
    this.shadeCervical,
    this.shadeMiddle,
    this.shadeIncisal,
    this.baseToothColor,
    this.notes,
    this.teeth = const [],
    this.currentStageId,
    this.currentStage,
    this.orderNum = 0,
    this.isFinished = false,
    this.statusHistory = const [],
  });

  String get restorationName => restorationType?.displayName ?? '—';

  /// Arabic first, English as the fallback — via [CaseWorkflowStageModel
  /// .displayName]. Reading `name` directly returned null for a stage the lab
  /// named only in Arabic, which is the ordinary case here.
  String? get currentStageName {
    final name = currentStage?.displayName;
    return (name == null || name.isEmpty) ? null : name;
  }

  factory CaseRestorationModel.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as Map<String, dynamic>?;
    return CaseRestorationModel(
      id: json['id'] as String,
      restorationTypeId: json['restorationTypeId'] as String?,
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
      shadeLayout: ShadeCodes.shadeSystemLabel(json['shadeSystem'] as int?),
      shadeCervical: ShadeCodes.toothShadeLabel(
        json['shadeSystem'] as int?,
        json['shadeCervical'] as int?,
      ),
      shadeMiddle: ShadeCodes.toothShadeLabel(
        json['shadeSystem'] as int?,
        json['shadeMiddle'] as int?,
      ),
      shadeIncisal: ShadeCodes.toothShadeLabel(
        json['shadeSystem'] as int?,
        json['shadeIncisal'] as int?,
      ),
      // The API's canonical field is `baseShade`; `baseToothColor` is an
      // older duplicate property some responses may still carry.
      baseToothColor: ShadeCodes.baseShadeLabel(
        (json['baseShade'] ?? json['baseToothColor']) as int?,
      ),
      restorationNumber: json['restorationNumber'] as String?,
      notes: json['notes'] as String?,
      teeth:
          (json['teeth'] as List<dynamic>?)
              ?.map((e) => ToothMarkModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currentStageId: json['currentStageId'] as String?,
      currentStage: json['currentStage'] == null
          ? null
          : CaseWorkflowStageModel.fromJson(
              json['currentStage'] as Map<String, dynamic>,
            ),
      orderNum: json['orderNum'] as int? ?? 0,
      isFinished: json['isFinished'] as bool? ?? false,
      statusHistory:
          (json['statusHistory'] as List<dynamic>?)
              ?.map(
                (e) => CaseRestorationStatusHistoryModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }
}
