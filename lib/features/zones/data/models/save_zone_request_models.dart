/// `ClinicCreateZoneRequest`.
///
/// [returnDeliveryFee] is the zone's delivery fee (أجرة التوصيل) — despite
/// the name, what shipping costs a doctor here — priced in [shippingCurrencyId].
class CreateZoneRequestModel {
  const CreateZoneRequestModel({
    required this.name,
    this.nameAr,
    this.description,
    this.isActive = true,
    this.areaIds = const [],
    this.representativeUserIds = const [],
    this.returnDeliveryFee,
    this.shippingCurrencyId,
    this.shippingMinutes = 0,
  });

  final String name;
  final String? nameAr;
  final String? description;
  final bool isActive;
  final List<String> areaIds;
  final List<String> representativeUserIds;
  final double? returnDeliveryFee;
  final String? shippingCurrencyId;

  /// How long shipping adds to delivery, in minutes (0–525600, a year).
  final int shippingMinutes;

  Map<String, dynamic> toJson() => {
    'name': name,
    'nameAr': nameAr,
    'description': description,
    'isActive': isActive,
    'areaIds': areaIds,
    'representativeUserIds': representativeUserIds,
    'returnDeliveryFee': returnDeliveryFee,
    'shippingCurrencyId': shippingCurrencyId,
    'shippingMinutes': shippingMinutes,
  };
}

/// `ClinicUpdateZoneRequest` — every field optional/nullable per the schema,
/// but the form always resends the full picked sets for `areaIds` and
/// `representativeUserIds` rather than a partial patch: the server
/// treats the arrays as a replacement, not a merge.
class UpdateZoneRequestModel {
  const UpdateZoneRequestModel({
    this.name,
    this.nameAr,
    this.description,
    this.isActive,
    this.areaIds = const [],
    this.representativeUserIds = const [],
    this.returnDeliveryFee,
    this.shippingCurrencyId,
    this.shippingMinutes = 0,
    this.clearReturnDeliveryFee = false,
  });

  final String? name;
  final String? nameAr;
  final String? description;
  final bool? isActive;
  final List<String> areaIds;
  final List<String> representativeUserIds;
  final double? returnDeliveryFee;
  final String? shippingCurrencyId;

  /// How long shipping adds to delivery, in minutes (0–525600, a year).
  final int shippingMinutes;

  /// Removes the delivery fee. A null [returnDeliveryFee] alone leaves the
  /// old one in place, so emptying the field has to say so explicitly.
  final bool clearReturnDeliveryFee;

  Map<String, dynamic> toJson() => {
    'name': name,
    'nameAr': nameAr,
    'description': description,
    'isActive': isActive,
    'areaIds': areaIds,
    'representativeUserIds': representativeUserIds,
    'returnDeliveryFee': returnDeliveryFee,
    'shippingCurrencyId': shippingCurrencyId,
    'shippingMinutes': shippingMinutes,
    if (clearReturnDeliveryFee) 'clearReturnDeliveryFee': true,
  };
}
