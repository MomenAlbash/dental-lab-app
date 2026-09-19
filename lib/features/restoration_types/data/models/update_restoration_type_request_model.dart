import 'package:dental_lab_app/features/restoration_types/data/models/save_priority_duration_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/save_restoration_type_price_request_model.dart';

/// Update payload for a restoration type (`ClinicUpdateRestorationTypeRequest`)
/// — same as create plus [isActive].
///
/// There is no currency-less `defaultPrice` field, and no `stages` field
/// either — a route's stages are edited on their own endpoint
/// (`/restoration-type-stages`), never inline on this request.
class UpdateRestorationTypeRequestModel {
  final String? name;
  final String? nameAr;
  final String? description;
  final double? transparency;

  /// List price per currency — replaces the whole set when sent. Pre-fill
  /// this from the type's existing [RestorationTypeModel.prices] so an edit
  /// that never touches pricing does not wipe it. An empty list is rejected
  /// by the server rather than clearing the set — a restoration type must
  /// always keep at least one price.
  final List<SaveRestorationTypePriceRequestModel> prices;

  final int? pricingType;
  final bool? isActive;

  /// One row per priority level the lab declared. The four fixed columns
  /// this replaced were the retired `CasePriority` enum: the API takes
  /// `durations` now, and the old keys were dropped on the floor.
  final List<SavePriorityDurationRequestModel> durations;

  UpdateRestorationTypeRequestModel({
    this.name,
    this.nameAr,
    this.description,
    this.transparency,
    this.prices = const [],
    this.pricingType,
    this.isActive,
    this.durations = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'transparency': transparency,
      'prices': prices.map((p) => p.toJson()).toList(),
      'pricingType': pricingType,
      'isActive': isActive,
      'durations': durations.map((d) => d.toJson()).toList(),
    };
  }
}
