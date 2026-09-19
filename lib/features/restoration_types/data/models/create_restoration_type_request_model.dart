import 'package:dental_lab_app/features/restoration_types/data/models/save_priority_duration_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/save_restoration_type_price_request_model.dart';

/// Create payload for a restoration type (`ClinicCreateRestorationTypeRequest`).
/// Required: [name], and at least one row in [prices] — a restoration type
/// with nobody able to price it is not a service the laboratory offers.
///
/// There is no currency-less `defaultPrice` field: the API never declared
/// one. A type is priced per currency alone.
///
/// Stages are NOT part of this payload: the endpoint declares no `stages`
/// field, so anything sent inline was dropped and the type came back with an
/// empty route. They are created against `/restoration-type-stages` from the
/// route editor instead.
class CreateRestorationTypeRequestModel {
  final String name;
  final String? nameAr;
  final String? description;
  final double? transparency;

  /// List price per currency. At least one row is required — the server
  /// refuses a create with none.
  final List<SaveRestorationTypePriceRequestModel> prices;

  final int? pricingType;

  /// One row per priority level the lab declared. The four fixed columns
  /// this replaced were the retired `CasePriority` enum: the API takes
  /// `durations` now, and the old keys were dropped on the floor.
  final List<SavePriorityDurationRequestModel> durations;

  CreateRestorationTypeRequestModel({
    required this.name,
    this.nameAr,
    this.description,
    this.transparency,
    required this.prices,
    this.pricingType,
    this.durations = const [],
  }) : assert(prices.isNotEmpty, 'A restoration type must have a price.');

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'transparency': transparency,
      'prices': prices.map((p) => p.toJson()).toList(),
      'pricingType': pricingType,
      'durations': durations.map((d) => d.toJson()).toList(),
    };
  }
}
