import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';

/// Filters applied to the cases list (`GET /Cases` query params). All fields
/// are optional — `null` (or an empty set) means "don't filter by this".
class CaseFiltersModel {
  const CaseFiltersModel({
    this.doctorId,
    this.doctorName,
    this.clinicId,
    this.clinicName,
    this.patientId,
    this.patientName,
    this.priorityId,
    this.priorityName,
    this.stageIds = const {},
    this.restorationStageIds = const {},
    this.overriddenRestorationIds = const {},
    this.matchAnyAssignedStage = false,
    this.laboratoryIds = const {},
    this.cityIds = const {},
    this.cityNames = const {},
    this.receivedFrom,
    this.receivedTo,
    this.phaseTab = CasePhaseTab.all,
    this.sla = CaseSlaFilter.none,
  });

  static const empty = CaseFiltersModel();

  final String? doctorId;
  final String? doctorName;
  final String? clinicId;
  final String? clinicName;

  /// Narrows to one patient's cases. The name rides along so the sheet can
  /// show the selection without waiting on the patients list.
  final String? patientId;
  final String? patientName;

  /// Id of the lab-defined priority to narrow by, with its label kept
  /// alongside so the sheet can show the selection without reloading the
  /// priorities list.
  final String? priorityId;
  final String? priorityName;

  /// Ids of the lab's workflow stages to narrow by. A set, not a single value:
  /// the API accepts `StageIds` repeatedly, and "show me everything still in
  /// review" is usually several stages.
  ///
  /// Replaced a single `CaseStatus` enum value — stages are rows the lab
  /// declares now, so there is no fixed list to pick one from.
  final Set<String> stageIds;

  /// Ids of *restoration* stages to narrow by (`RestorationStageIds`) — the
  /// pieces' own routes, which are a different catalogue from [stageIds].
  ///
  /// Set by the "my tasks" queue from `GET /Cases/my-workflow-assignments`;
  /// there is no manual picker for it, since a person does not choose which
  /// stages they are assigned to.
  final Set<String> restorationStageIds;

  /// Specific restorations (`OverriddenCaseRestorationIds`) a temporary
  /// override hands this login — restoration ids, not stage ids, so they
  /// match only that one piece and not everything parked on its stage. Set by
  /// the "my tasks" queue alone, like [restorationStageIds].
  final Set<String> overriddenRestorationIds;

  /// Match a case on *any* of [stageIds], [restorationStageIds] and
  /// [overriddenRestorationIds] instead of all of them — what "assigned to me"
  /// means. Every other view keeps the server's default AND.
  final bool matchAnyAssignedStage;

  /// Laboratories to browse at once (`LaboratoryIds`).
  ///
  /// Empty means "whichever lab the `X-Laboratory-Id` header names" — the
  /// ordinary single-lab view. Only an admin, or a user holding `Branches`,
  /// may pass several: everyone else is pinned to the header no matter what
  /// they send, so the control is not offered to them at all.
  final Set<String> laboratoryIds;

  /// Cities to narrow by, matched against each case's **clinic** city.
  ///
  /// Applied client-side: `GET /Cases` has no city parameter of any kind, so
  /// the rows are fetched and then narrowed here. It therefore filters the
  /// page that came back rather than the whole table — a real limit, and the
  /// reason this is not offered as an equal to the server-side filters.
  final Set<String> cityIds;

  /// The chosen cities' names, so the sheet can show the selection without
  /// waiting on the cities list.
  final Set<String> cityNames;

  /// The window filters on when the case was *received*. The API has no
  /// due-date filter — `DueDateFrom`/`DueDateTo` were removed and were being
  /// ignored silently.
  final DateTime? receivedFrom;
  final DateTime? receivedTo;

  /// Which lifecycle tab the list is showing. Its own field rather than a
  /// value folded into [stageIds]: the server counts the tabs separately from
  /// the filters, and a tab is a view, not a narrowing the user typed.
  final CasePhaseTab phaseTab;

  /// The date segment: late, due today, or never promised a date.
  final CaseSlaFilter sla;

  bool get isEmpty =>
      doctorId == null &&
      clinicId == null &&
      patientId == null &&
      priorityId == null &&
      stageIds.isEmpty &&
      laboratoryIds.isEmpty &&
      cityIds.isEmpty &&
      receivedFrom == null &&
      receivedTo == null;

  /// The count behind the filter sheet's badge. [phaseTab], [sla] and
  /// [restorationStageIds] are deliberately excluded: the first two have their
  /// own visible controls on the list screen, and the third is set by the "my
  /// tasks" queue rather than typed by anyone — counting them here would
  /// report a filter the sheet cannot show or clear.
  ///
  /// Note [stageIds] is counted by emptiness, not by null: a `const {}` is
  /// non-null and would otherwise make every filter set look active.
  int get activeCount =>
      [
        doctorId,
        clinicId,
        patientId,
        priorityId,
        receivedFrom,
        receivedTo,
      ].where((v) => v != null).length +
      (stageIds.isEmpty ? 0 : 1) +
      (laboratoryIds.isEmpty ? 0 : 1) +
      (cityIds.isEmpty ? 0 : 1);

  CaseFiltersModel copyWith({
    String? doctorId,
    String? doctorName,
    bool clearDoctor = false,
    String? clinicId,
    String? clinicName,
    bool clearClinic = false,
    String? patientId,
    String? patientName,
    bool clearPatient = false,
    String? priorityId,
    String? priorityName,
    bool clearPriority = false,
    Set<String>? stageIds,
    bool clearStages = false,
    Set<String>? restorationStageIds,
    bool clearRestorationStages = false,
    Set<String>? overriddenRestorationIds,
    bool? matchAnyAssignedStage,
    CasePhaseTab? phaseTab,
    CaseSlaFilter? sla,
    Set<String>? laboratoryIds,
    bool clearLaboratories = false,
    Set<String>? cityIds,
    Set<String>? cityNames,
    bool clearCities = false,
    DateTime? receivedFrom,
    bool clearReceivedFrom = false,
    DateTime? receivedTo,
    bool clearReceivedTo = false,
  }) {
    return CaseFiltersModel(
      doctorId: clearDoctor ? null : (doctorId ?? this.doctorId),
      doctorName: clearDoctor ? null : (doctorName ?? this.doctorName),
      clinicId: clearClinic ? null : (clinicId ?? this.clinicId),
      clinicName: clearClinic ? null : (clinicName ?? this.clinicName),
      patientId: clearPatient ? null : (patientId ?? this.patientId),
      patientName: clearPatient ? null : (patientName ?? this.patientName),
      priorityId: clearPriority ? null : (priorityId ?? this.priorityId),
      priorityName: clearPriority ? null : (priorityName ?? this.priorityName),
      stageIds: clearStages ? const {} : (stageIds ?? this.stageIds),
      restorationStageIds: clearRestorationStages
          ? const {}
          : (restorationStageIds ?? this.restorationStageIds),
      overriddenRestorationIds: clearRestorationStages
          ? const {}
          : (overriddenRestorationIds ?? this.overriddenRestorationIds),
      matchAnyAssignedStage: clearRestorationStages
          ? false
          : (matchAnyAssignedStage ?? this.matchAnyAssignedStage),
      phaseTab: phaseTab ?? this.phaseTab,
      sla: sla ?? this.sla,
      laboratoryIds: clearLaboratories
          ? const {}
          : (laboratoryIds ?? this.laboratoryIds),
      cityIds: clearCities ? const {} : (cityIds ?? this.cityIds),
      cityNames: clearCities ? const {} : (cityNames ?? this.cityNames),
      receivedFrom: clearReceivedFrom
          ? null
          : (receivedFrom ?? this.receivedFrom),
      receivedTo: clearReceivedTo ? null : (receivedTo ?? this.receivedTo),
    );
  }
}
