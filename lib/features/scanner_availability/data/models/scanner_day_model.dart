import 'package:dental_lab_app/core/helper/api_time_helper.dart';

/// One bookable slot on the scanner calendar (`DoctorScannerSlotDto`).
class ScannerSlotModel {
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isAvailable;

  /// Appointments still free in this slot, out of the rule's capacity. Zero
  /// means taken, which is why [isAvailable] can be false on an open day.
  final int remainingCapacity;

  const ScannerSlotModel({
    this.startAt,
    this.endAt,
    this.isAvailable = false,
    this.remainingCapacity = 0,
  });

  String get timeLabel {
    final start = startAt;
    if (start == null) return '—';
    final hour = start.hour.toString().padLeft(2, '0');
    final minute = start.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  factory ScannerSlotModel.fromJson(Map<String, dynamic> json) {
    return ScannerSlotModel(
      startAt: DateTime.tryParse(json['startAt'] as String? ?? ''),
      endAt: DateTime.tryParse(json['endAt'] as String? ?? ''),
      isAvailable: json['isAvailable'] as bool? ?? false,
      remainingCapacity: json['remainingCapacity'] as int? ?? 0,
    );
  }
}

/// One day of the scanner calendar (`DoctorScannerDayDto`).
///
/// This is the *computed* result of the weekly rules minus the exceptions
/// minus what is already booked — the server owns that arithmetic. The lab
/// reads it to check that its rules produced what it intended; the doctor
/// picks an appointment out of it.
class ScannerDayModel {
  final DateTime? date;
  final bool isOpen;

  /// Why the day is shut — comes from the exception's reason.
  final String? closedReason;

  final List<ScannerSlotModel> slots;

  const ScannerDayModel({
    this.date,
    this.isOpen = false,
    this.closedReason,
    this.slots = const [],
  });

  /// Slots a doctor could still take. A day can be open yet have none left.
  int get availableCount => slots.where((slot) => slot.isAvailable).length;

  factory ScannerDayModel.fromJson(Map<String, dynamic> json) {
    return ScannerDayModel(
      date: ApiTime.parseDate(json['date'] as String?),
      isOpen: json['isOpen'] as bool? ?? false,
      closedReason: json['closedReason'] as String?,
      slots:
          (json['slots'] as List<dynamic>?)
              ?.map((e) => ScannerSlotModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
