import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_status_history_model.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';

/// A restoration line as returned on a case (`ClinicCaseRestorationDto`).
/// Stage tracking lives here (per-restoration), not on the case itself.
class CaseRestorationModel {
  final String id;
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

  /// The restoration's stage timeline — one entry per stage change.
  final List<CaseRestorationStatusHistoryModel> statusHistory;

  CaseRestorationModel({
    required this.id,
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
    this.statusHistory = const [],
  });

  String get restorationName => restorationType?.displayName ?? '—';
  String? get currentStageName => currentStage?.name;

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
      shadeLayout: json['shadeLayout'] as String?,
      shadeCervical: json['shadeCervical'] as String?,
      shadeMiddle: json['shadeMiddle'] as String?,
      shadeIncisal: json['shadeIncisal'] as String?,
      baseToothColor: json['baseToothColor'] as String?,
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
