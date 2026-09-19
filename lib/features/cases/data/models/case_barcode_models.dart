import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/shade_codes.dart';

/// What a scanned restoration barcode resolves to
/// (`ClinicScannedRestorationDto`).
///
/// The whole case comes back with it: a restoration is never worked on its
/// own — the technician holding the piece needs the case it belongs to, and
/// [restorationId] says which line of it they scanned.
class ScannedRestorationModel {
  const ScannedRestorationModel({
    required this.restorationId,
    this.restorationNumber,
    this.caseDetail,
  });

  final String restorationId;
  final String? restorationNumber;
  final CaseDetailModel? caseDetail;

  factory ScannedRestorationModel.fromJson(Map<String, dynamic> json) {
    final caseJson = json['case'];

    return ScannedRestorationModel(
      restorationId: json['restorationId'] as String? ?? '',
      restorationNumber: json['restorationNumber'] as String?,
      caseDetail: caseJson is Map<String, dynamic>
          ? CaseDetailModel.fromJson(caseJson)
          : null,
    );
  }
}

/// Everything printed on the thermal case ticket (طباعة الحالة) that Control
/// produces when it accepts a case, and nothing else
/// (`ClinicCasePrintTicketDto`, `GET /Cases/{id}/print-ticket`).
///
/// **Carries no prices, for anybody, admins included, on purpose** — the
/// ticket travels with the physical work through every department and out to
/// benches, and the rule "the ticket never shows what a restoration costs"
/// has to hold no matter which screen or role produced it. The patient's
/// phone number is likewise absent, though the system holds one.
class CasePrintTicketModel {
  const CasePrintTicketModel({
    this.caseNumber,
    this.qrPayload,
    this.referenceNumber,
    this.patientName,
    this.doctorNumber,
    this.doctorName,
    this.doctorCountry,
    this.doctorCity,
    this.doctorArea,
    this.laboratoryName,
    this.priorityId,
    this.priorityName,
    this.priorityNameAr,
    this.impressionMethodLabelAr,
    this.createdAt,
    this.receivedAt,
    this.expectedCompletionAt,
    this.notes,
    this.restorations = const [],
  });

  final String? caseNumber;

  /// What the case's own barcode/QR encodes — the bare case number, never a
  /// URL: a printed ticket outlives the deployment it was printed from.
  final String? qrPayload;

  final String? referenceNumber;
  final String? patientName;

  /// The doctor's lab-assigned number — what the benches identify them by,
  /// not their name.
  final int? doctorNumber;
  final String? doctorName;
  final String? doctorCountry;
  final String? doctorCity;
  final String? doctorArea;
  final String? laboratoryName;

  final String? priorityId;
  final String? priorityName;
  final String? priorityNameAr;

  /// Already resolved to Arabic server-side — nothing to convert from an
  /// enum on this side.
  final String? impressionMethodLabelAr;

  final DateTime? createdAt;
  final DateTime? receivedAt;
  final DateTime? expectedCompletionAt;
  final String? notes;

  final List<PrintTicketRestorationModel> restorations;

  /// Arabic first, English as the fallback, same convention every other
  /// priority display in the app uses.
  String? get priorityLabel {
    final ar = priorityNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return priorityName?.trim();
  }

  /// `"<country> / <city> / <area>"`, whichever parts exist — null when none
  /// do, so a row can skip itself instead of printing an empty line.
  String? get locationLabel {
    final parts = [
      doctorCountry,
      doctorCity,
      doctorArea,
    ].whereType<String>().map((p) => p.trim()).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return null;
    return parts.join(' / ');
  }

  factory CasePrintTicketModel.fromJson(Map<String, dynamic> json) {
    return CasePrintTicketModel(
      caseNumber: json['caseNumber'] as String?,
      qrPayload: json['qrPayload'] as String?,
      referenceNumber: json['referenceNumber'] as String?,
      patientName: json['patientName'] as String?,
      doctorNumber: json['doctorNumber'] as int?,
      doctorName: json['doctorName'] as String?,
      doctorCountry: json['doctorCountry'] as String?,
      doctorCity: json['doctorCity'] as String?,
      doctorArea: json['doctorArea'] as String?,
      laboratoryName: json['laboratoryName'] as String?,
      priorityId: json['priorityId'] as String?,
      priorityName: json['priorityName'] as String?,
      priorityNameAr: json['priorityNameAr'] as String?,
      impressionMethodLabelAr: json['impressionMethodLabelAr'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? ''),
      expectedCompletionAt: DateTime.tryParse(
        json['expectedCompletionAt'] as String? ?? '',
      ),
      notes: json['notes'] as String?,
      restorations:
          (json['restorations'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(PrintTicketRestorationModel.fromJson)
              .toList() ??
          const [],
    );
  }
}

/// One line on the ticket (`ClinicCasePrintRestorationDto`) — no unit price,
/// no discount, no total, same no-pricing rule as the parent.
class PrintTicketRestorationModel {
  const PrintTicketRestorationModel({
    this.restorationNumber,
    this.typeName,
    this.typeNameAr,
    this.quantity = 1,
    this.teeth = const [],
    this.shadeSystem,
    this.shadeNotes,
    this.shadeCervical,
    this.shadeMiddle,
    this.shadeIncisal,
    this.baseShade,
    this.notes,
  });

  /// This restoration's own barcode, `"{CaseNumber}-{NN}"`.
  final String? restorationNumber;
  final String? typeName;
  final String? typeNameAr;
  final int quantity;

  /// Tooth numbers marked for this restoration, ascending.
  final List<int> teeth;

  /// `ShadeSystem` (1 = Vita Classical, 2 = Vita 3D-Master) — which table
  /// [shadeCervical]/[shadeMiddle]/[shadeIncisal] read against.
  final int? shadeSystem;
  final String? shadeNotes;

  /// `ToothShade` codes — converted to their Vita label (`'A2'`, `'2M1'`)
  /// through [ShadeCodes], the same table the case form itself uses.
  final int? shadeCervical;
  final int? shadeMiddle;
  final int? shadeIncisal;

  /// `BaseShade` code.
  final int? baseShade;

  final String? notes;

  String get displayName {
    final ar = typeNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return typeName?.trim() ?? '';
  }

  String? get shadeCervicalLabel =>
      ShadeCodes.toothShadeLabel(shadeSystem, shadeCervical);

  String? get shadeMiddleLabel =>
      ShadeCodes.toothShadeLabel(shadeSystem, shadeMiddle);

  String? get shadeIncisalLabel =>
      ShadeCodes.toothShadeLabel(shadeSystem, shadeIncisal);

  String? get baseShadeLabel => ShadeCodes.baseShadeLabel(baseShade);

  /// One line for the three layered shades, e.g. `"A2 / A2 / A1"` — the same
  /// order the case form's own diagram uses (cervical, middle, incisal).
  /// Empty when none are set.
  String get shadeSummary {
    final values = [shadeCervicalLabel, shadeMiddleLabel, shadeIncisalLabel];
    if (values.every((v) => v == null)) return '';
    return values.map((v) => v ?? '—').join(' / ');
  }

  factory PrintTicketRestorationModel.fromJson(Map<String, dynamic> json) {
    return PrintTicketRestorationModel(
      restorationNumber: json['restorationNumber'] as String?,
      typeName: json['typeName'] as String?,
      typeNameAr: json['typeNameAr'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      teeth:
          (json['teeth'] as List<dynamic>?)?.whereType<int>().toList() ??
          const [],
      shadeSystem: json['shadeSystem'] as int?,
      shadeNotes: json['shadeNotes'] as String?,
      shadeCervical: json['shadeCervical'] as int?,
      shadeMiddle: json['shadeMiddle'] as int?,
      shadeIncisal: json['shadeIncisal'] as int?,
      baseShade: json['baseShade'] as int?,
      notes: json['notes'] as String?,
    );
  }
}
