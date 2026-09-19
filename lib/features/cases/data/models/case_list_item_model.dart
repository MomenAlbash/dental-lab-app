import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_breakdown_group.dart';
import 'package:dental_lab_app/features/cases/data/models/case_stage_summary.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';

/// A row in the cases list (`ClinicCaseListItemDto`).
class CaseListItemModel {
  final String id;
  final String? caseNumber;
  final String? referenceNumber;

  /// The lab-defined priority this case was filed under. Priorities are a
  /// lookup entity now, so the case only carries the id and the names the
  /// server denormalised onto it — not an enum.
  final String? priorityId;
  final String? priorityName;
  final String? priorityNameAr;

  /// Where the case is in the lab's own workflow. Replaced a hardcoded
  /// `caseStatus` enum the API no longer sends — see [CaseStageSummary].
  final CaseStageSummary stage;

  final String? patientName;
  final DoctorModel? doctor;
  final ClinicModel? clinic;

  /// Which laboratory filed the case. Only worth showing once the user is
  /// browsing several at once — in a single-lab view it prints the same name
  /// on every row.
  final String? laboratoryId;
  final LaboratoryModel? laboratory;
  final int restorationsCount;

  /// Every restoration on this case, grouped by (current stage, type) — the
  /// decomposition of [restorationsCount], and what the row's expander draws.
  ///
  /// Stored in the server's own order. The group DTO carries no `order` field,
  /// so there is nothing here to sort by that would mean anything; see
  /// [orderedRestorationBreakdown] for the one display-only rearrangement.
  final List<CaseRestorationBreakdownGroup> restorationBreakdown;

  final int doctorNumber;
  final String? dueDate;
  final String? createdAt;

  /// The fixed six-value lifecycle checkpoint (`CasePhase`) — `new` is a case
  /// that has not had its material recorded yet, whatever its intake.
  final CasePhase? phase;

  /// When the material actually arrived at the lab. Null while the case is
  /// still awaiting pickup or drop-off, which is the other half of "not
  /// received": a case can sit in [CasePhase.newCase] for a while with this
  /// still null.
  final String? receivedAt;

  CaseListItemModel({
    required this.id,
    this.caseNumber,
    this.referenceNumber,
    this.priorityId,
    this.priorityName,
    this.priorityNameAr,
    this.stage = CaseStageSummary.empty,
    this.patientName,
    this.doctor,
    this.clinic,
    this.laboratoryId,
    this.laboratory,
    this.restorationsCount = 0,
    this.restorationBreakdown = const [],
    this.doctorNumber = 0,
    this.dueDate,
    this.createdAt,
    this.phase,
    this.receivedAt,
  });

  /// The material has not been recorded yet. [CasePhase.newCase] is the
  /// checkpoint's own word for it — recording the material is what moves a
  /// case out of it and opens its workflow.
  bool get isNotReceived => phase == CasePhase.newCase;

  String? get doctorName => doctor?.fullName;
  String? get clinicName => clinic?.name;

  /// The lab's name, or empty when the row did not carry one.
  String get laboratoryName => laboratory?.name ?? '';

  /// The city the case's clinic sits in. A case with no linked clinic has no
  /// city at all — said as empty rather than guessed from the doctor, who may
  /// practise somewhere else.
  String get cityName => clinic?.city?.name ?? '';
  String? get cityId => clinic?.cityId;

  /// The stage's name, or empty when the case has none — callers hide the
  /// badge rather than invent a label.
  String get stageLabel => stage.label;

  /// Whether there is a breakdown worth offering an expander for. False for a
  /// case with no restorations — the row hides the button rather than opening
  /// an empty sheet.
  bool get hasRestorationBreakdown => restorationBreakdown.isNotEmpty;

  /// The breakdown as the sheet draws it: the server's own order, with the
  /// groups that have not started moved to the end.
  ///
  /// **A partition, not a sort.** There is no key here worth sorting on — the
  /// group carries no stage `order`, and ranking Arabic stage names
  /// alphabetically would invent a sequence the lab does not work in. Two
  /// `where` passes rather than `List.sort`, because Dart's sort is not
  /// guaranteed stable and a comparator would be free to scramble the
  /// server's order inside each half.
  ///
  /// Not-started goes last because it is the *absence* of a stage rather than
  /// a position among them; interleaved, it reads as a stage literally named
  /// "لم تبدأ".
  List<CaseRestorationBreakdownGroup> get orderedRestorationBreakdown => [
    ...restorationBreakdown.where((group) => group.hasStarted),
    ...restorationBreakdown.where((group) => !group.hasStarted),
  ];

  /// "زيركون: طحن (+2 مراحل أخرى)" — one representative restoration's stage,
  /// for the list row's second line. Empty when the case is not mid-
  /// production or the server resolved no stage to summarise with.
  ///
  /// A glimpse, not the picture: it names one restoration's stage and counts
  /// the rest. [restorationBreakdown] is where the rest actually are.
  String get productionSummaryLabel {
    if (!stage.hasProductionSummary) return '';

    final type = stage.productionRestorationTypeLabel;
    final head = type.isEmpty
        ? stage.productionStageLabel
        : '$type: ${stage.productionStageLabel}';

    if (stage.productionOtherStagesCount <= 0) return head;
    return '$head (+${stage.productionOtherStagesCount} مراحل أخرى)';
  }

  /// Arabic first, English as the fallback; empty when the case has no
  /// priority at all, so callers can hide the badge rather than show a dash.
  String get priorityLabel => (priorityNameAr?.trim().isNotEmpty ?? false)
      ? priorityNameAr!.trim()
      : (priorityName?.trim() ?? '');

  factory CaseListItemModel.fromJson(Map<String, dynamic> json) {
    return CaseListItemModel(
      id: json['id'] as String,
      caseNumber: json['caseNumber'] as String?,
      referenceNumber: json['referenceNumber'] as String?,
      priorityId: json['priorityId'] as String?,
      priorityName: json['priorityName'] as String?,
      priorityNameAr: json['priorityNameAr'] as String?,
      stage: CaseStageSummary.fromCaseJson(json),
      patientName: json['patientName'] as String?,
      doctor: json['doctor'] == null
          ? null
          : DoctorModel.fromJson(json['doctor'] as Map<String, dynamic>),
      clinic: json['clinic'] == null
          ? null
          : ClinicModel.fromJson(json['clinic'] as Map<String, dynamic>),
      laboratoryId: json['laboratoryId'] as String?,
      laboratory: json['laboratory'] == null
          ? null
          : LaboratoryModel.fromJson(
              json['laboratory'] as Map<String, dynamic>,
            ),
      restorationsCount: json['restorationsCount'] as int? ?? 0,
      restorationBreakdown: CaseRestorationBreakdownGroup.listFromCaseJson(
        json,
      ),
      doctorNumber: json['doctorNumber'] as int? ?? 0,
      dueDate: json['dueDate'] as String?,
      createdAt: json['createdAt'] as String?,
      phase: CasePhase.fromValue(json['phase'] as int?),
      receivedAt: json['receivedAt'] as String?,
    );
  }
}
