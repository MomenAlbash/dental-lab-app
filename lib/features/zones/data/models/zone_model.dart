import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart'
    show ZoneRepresentativeModel;

/// `ClinicZoneAreaDto` — one of a zone's assigned areas, as the zone reads
/// it back (denormalised with its city, for display).
class ZoneAreaModel {
  final String id;
  final String areaId;
  final String? areaName;
  final String? areaNameAr;
  final String cityId;
  final String? cityName;

  const ZoneAreaModel({
    required this.id,
    required this.areaId,
    this.areaName,
    this.areaNameAr,
    required this.cityId,
    this.cityName,
  });

  factory ZoneAreaModel.fromJson(Map<String, dynamic> json) {
    return ZoneAreaModel(
      id: json['id'] as String,
      areaId: json['areaId'] as String,
      areaName: json['areaName'] as String?,
      areaNameAr: json['areaNameAr'] as String?,
      cityId: json['cityId'] as String,
      cityName: json['cityName'] as String?,
    );
  }
}

/// `ClinicZoneDto` — a delivery/coverage zone: the areas it spans and the
/// representatives who work it.
class ZoneModel {
  final String id;
  final String laboratoryId;
  final String? laboratoryName;
  final String? name;
  final String? nameAr;
  final String? description;
  final bool isActive;
  final List<ZoneAreaModel> areas;
  final List<ZoneRepresentativeModel> representatives;
  final int doctorCount;
  final double? returnDeliveryFee;
  final String? shippingCurrencyId;

  /// How long shipping adds to a case's delivery date, in minutes.
  final int shippingMinutes;
  final DateTime? createdAt;

  const ZoneModel({
    required this.id,
    required this.laboratoryId,
    this.laboratoryName,
    this.name,
    this.nameAr,
    this.description,
    this.isActive = true,
    this.areas = const [],
    this.representatives = const [],
    this.doctorCount = 0,
    this.returnDeliveryFee,
    this.shippingCurrencyId,
    this.shippingMinutes = 0,
    this.createdAt,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    final rawAreas = json['areas'] as List<dynamic>? ?? const [];
    final rawReps = json['representatives'] as List<dynamic>? ?? const [];

    return ZoneModel(
      id: json['id'] as String,
      laboratoryId: json['laboratoryId'] as String,
      laboratoryName: json['laboratoryName'] as String?,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      areas: rawAreas
          .whereType<Map<String, dynamic>>()
          .map(ZoneAreaModel.fromJson)
          .toList(),
      representatives: rawReps
          .whereType<Map<String, dynamic>>()
          .map(ZoneRepresentativeModel.fromJson)
          .toList(),
      doctorCount: json['doctorCount'] as int? ?? 0,
      returnDeliveryFee: (json['returnDeliveryFee'] as num?)?.toDouble(),
      shippingCurrencyId: json['shippingCurrencyId'] as String?,
      shippingMinutes: json['shippingMinutes'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

/// A zone's shipping time, split for editing and display.
///
/// The API stores one minute count; people think in "2 days 4 hours". This
/// is the one place the two are converted, so the form's fields and its
/// summary line cannot drift apart.
class ShippingDuration {
  const ShippingDuration({this.days = 0, this.hours = 0, this.minutes = 0});

  factory ShippingDuration.fromMinutes(int total) => ShippingDuration(
    days: total ~/ minutesPerDay,
    hours: total % minutesPerDay ~/ 60,
    minutes: total % 60,
  );

  static const minutesPerDay = 24 * 60;

  /// The API's ceiling: one year.
  static const maxMinutes = 525600;

  final int days;
  final int hours;
  final int minutes;

  int get totalMinutes => days * minutesPerDay + hours * 60 + minutes;

  bool get isZero => totalMinutes == 0;

  bool get exceedsMax => totalMinutes > maxMinutes;

  /// `يومان و3 ساعات` style, skipping empty parts; `بدون مدة` when zero.
  String get label {
    if (isZero) return 'بدون مدة';
    return [
      if (days > 0) '$days يوم',
      if (hours > 0) '$hours ساعة',
      if (minutes > 0) '$minutes دقيقة',
    ].join(' و');
  }
}
