import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/priority_duration_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_currency_price_model.dart';

/*
{
  "id": "...",
  "laboratoryId": "...",
  "name": "Zircon Crown",
  "nameAr": "تاج زيركون",
  "description": "...",
  "transparency": 0.5,
  "prices": [ { "currencyId": "...", "currency": {...}, "price": 250000.0 } ],
  "pricingType": 1,
  "isActive": true,
  "durations": [ { "casePriorityId": "...", "priorityNameAr": "عاجلة", "durationMinutes": 720 } ],
  "stages": [ { "id": "...", "name": "التصميم", "order": 1, ... } ]
}
 */

/// A restoration type and the ordered workflow [stages] a restoration of this
/// type moves through inside the lab. Stages belong to the type — they are
/// not a separate lab-wide list.
///
/// There is no currency-less "default price": `ClinicRestorationTypeDto`
/// carries [prices] alone, one row per currency the lab actually sells this
/// type in, and a create/update needs at least one such row. A
/// `defaultPrice` field used to live here, fed by nothing on the plain
/// catalog response — it always read as zero, and the list card that showed
/// it was always wrong.
class RestorationTypeModel {
  final String id;
  final String? laboratoryId;
  final String? name;
  final String? nameAr;
  final String? description;
  final double? transparency;

  /// The list price stated per currency, one row per currency this type is
  /// actually sold in. A restoration type the lab has not priced yet holds
  /// this empty — a case's currency picker then has nothing to offer.
  final List<RestorationCurrencyPriceModel> prices;

  final int? pricingType;
  final bool isActive;

  /// One row per priority level the lab declared, not four fixed columns.
  ///
  /// The four `low/normal/high/urgent` fields this replaced belonged to the
  /// retired `CasePriority` enum: a lab with two rush tiers got four boxes,
  /// and a lab with six could only fill four of them.
  final List<PriorityDurationModel> durations;
  final List<CaseWorkflowStageModel> stages;

  RestorationTypeModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.nameAr,
    this.description,
    this.transparency,
    this.prices = const [],
    this.pricingType,
    this.isActive = true,
    this.durations = const [],
    this.stages = const [],
  });

  /// Prefers the Arabic name for display, falling back to the base name.
  String get displayName =>
      (nameAr != null && nameAr!.isNotEmpty) ? nameAr! : (name ?? '—');

  /// The catalogue price, formatted from the first currency row — real data,
  /// unlike the retired `defaultPrice`. Null when the lab has not priced this
  /// type in any currency yet, so a card can say so instead of showing "0".
  String? get catalogPriceLabel {
    if (prices.isEmpty) return null;
    final first = prices.first;
    return '${first.price.toStringAsFixed(0)} ${first.currencyLabel}';
  }

  factory RestorationTypeModel.fromJson(Map<String, dynamic> json) {
    final stages =
        (json['stages'] as List<dynamic>?)
            ?.map(
              (e) => CaseWorkflowStageModel.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        <CaseWorkflowStageModel>[];
    stages.sort((a, b) => a.order.compareTo(b.order));

    return RestorationTypeModel(
      id: json['id'] as String,
      laboratoryId: json['laboratoryId'] as String?,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      transparency: (json['transparency'] as num?)?.toDouble(),
      prices:
          (json['prices'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(RestorationCurrencyPriceModel.fromJson)
              .toList() ??
          const [],
      pricingType: json['pricingType'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      durations:
          (json['durations'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(PriorityDurationModel.fromJson)
              .toList() ??
          const [],
      stages: stages,
    );
  }
}
