/// One stretch of time during which a doctor was on one price tier
/// (`DoctorPriceTierSpellDto`, `GET /Doctors/{id}/price-tier-history`).
///
/// Kept as rows rather than a single "current tier" column so an old invoice
/// can still be explained: the range is half-open — a switch writes the old
/// spell's [endDate] and the new spell's [startDate] as the same instant, so
/// exactly one row covers any given moment. [isActive] answers "now" only.
class DoctorPriceTierSpellModel {
  const DoctorPriceTierSpellModel({
    required this.id,
    this.priceTierId,
    this.priceTierName,
    this.startDate,
    this.endDate,
    this.isActive = false,
    this.note,
  });

  final String id;
  final String? priceTierId;
  final String? priceTierName;
  final DateTime? startDate;

  /// Null on the spell in force — also the instant the next spell started.
  final DateTime? endDate;

  /// The tier in force today. Anything explaining a past invoice must
  /// compare its own date against [startDate]/[endDate] instead of trusting
  /// this flag.
  final bool isActive;

  /// Why the doctor was moved, where anyone recorded it.
  final String? note;

  /// Arabic first, English as the fallback — the lab named its own tiers, so
  /// there is no placeholder to fall back to further than "no tier".
  String get tierLabel => priceTierName?.trim().isNotEmpty ?? false
      ? priceTierName!.trim()
      : 'بلا شريحة';

  factory DoctorPriceTierSpellModel.fromJson(Map<String, dynamic> json) {
    return DoctorPriceTierSpellModel(
      id: json['id'] as String? ?? '',
      priceTierId: json['priceTierId'] as String?,
      priceTierName: json['priceTierName'] as String?,
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      isActive: json['isActive'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}
