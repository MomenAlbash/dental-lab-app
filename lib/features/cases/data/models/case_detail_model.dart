import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_stage_history_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_stage_move_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_stage_summary.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';

/// Full case details (`ClinicCaseDetailDto`).
class CaseDetailModel {
  final String id;
  final String? caseNumber;
  final String? referenceNumber;

  /// See [CaseListItemModel.priorityId] — priorities are a lookup entity, so
  /// the case carries the id plus the names denormalised onto it.
  final String? priorityId;
  final String? priorityName;
  final String? priorityNameAr;
  final String? patientName;
  final DoctorModel? doctor;
  final ClinicModel? clinic;

  /// Where the case is in the lab's own workflow — see [CaseStageSummary].
  final CaseStageSummary stage;

  /// How the case came in. It decides which head of every route the case
  /// runs, so the progress board cannot be drawn without it.
  /// Where the case sits in the fixed lifecycle. The lab-drawn stages all
  /// live inside `inProduction`; the other five are checkpoints moved by
  /// their own actions.
  final CasePhase? phase;

  final ImpressionMethod? impressionMethod;
  final DigitalScanSource? digitalScanSource;
  final String? dueDate;
  final String? createdAt;
  final String? receivedAt;
  final String? notes;
  final List<ToothMarkModel> teeth;
  final List<CaseRestorationModel> restorations;
  final List<CaseFileModel> files;
  final List<CaseStageHistoryModel> history;

  /// What the case may do right now, resolved by the server.
  ///
  /// The only source of truth for the move sheet: the rules behind it — the
  /// running order, the parallel step, the production barrier, the declared
  /// rework target — are the server.s, and a client-computed list would
  /// disagree with it the moment the lab edits its workflow.
  final List<CaseStageMoveModel> availableTransitions;

  CaseDetailModel({
    required this.id,
    this.caseNumber,
    this.referenceNumber,
    this.priorityId,
    this.priorityName,
    this.priorityNameAr,
    this.patientName,
    this.doctor,
    this.clinic,
    this.stage = CaseStageSummary.empty,
    this.phase,
    this.impressionMethod,
    this.digitalScanSource,
    this.dueDate,
    this.createdAt,
    this.receivedAt,
    this.notes,
    this.teeth = const [],
    this.restorations = const [],
    this.files = const [],
    this.history = const [],
    this.availableTransitions = const [],
  });

  String? get doctorName => doctor?.fullName;
  String? get clinicName => clinic?.name;

  /// The stage's name, or empty when the case has none.
  String get stageLabel => stage.label;

  /// Arabic first, English as the fallback; empty when the case has no
  /// priority at all, so callers can hide the badge rather than show a dash.
  String get priorityLabel => (priorityNameAr?.trim().isNotEmpty ?? false)
      ? priorityNameAr!.trim()
      : (priorityName?.trim() ?? '');

  static List<T> _list<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return (value as List<dynamic>?)
            ?.map((e) => fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
  }

  factory CaseDetailModel.fromJson(Map<String, dynamic> json) {
    return CaseDetailModel(
      id: json['id'] as String,
      caseNumber: json['caseNumber'] as String?,
      referenceNumber: json['referenceNumber'] as String?,
      priorityId: json['priorityId'] as String?,
      priorityName: json['priorityName'] as String?,
      priorityNameAr: json['priorityNameAr'] as String?,
      patientName: json['patientName'] as String?,
      doctor: json['doctor'] == null
          ? null
          : DoctorModel.fromJson(json['doctor'] as Map<String, dynamic>),
      clinic: json['clinic'] == null
          ? null
          : ClinicModel.fromJson(json['clinic'] as Map<String, dynamic>),
      stage: CaseStageSummary.fromCaseJson(json),
      phase: CasePhase.fromValue(json['phase'] as int?),
      impressionMethod: ImpressionMethod.fromValue(
        json['impressionMethod'] as int?,
      ),
      digitalScanSource: DigitalScanSource.fromValue(
        json['digitalScanSource'] as int?,
      ),
      dueDate: json['dueDate'] as String?,
      createdAt: json['createdAt'] as String?,
      receivedAt: json['receivedAt'] as String?,
      notes: json['notes'] as String?,
      teeth: _list(json['teeth'], ToothMarkModel.fromJson),
      restorations: _list(json['restorations'], CaseRestorationModel.fromJson),
      files: _list(json['files'], CaseFileModel.fromJson),
      history: _list(json['history'], CaseStageHistoryModel.fromJson),
      availableTransitions: _list(
        json['availableTransitions'],
        CaseStageMoveModel.fromJson,
      ),
    );
  }
}
