import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';

/// Where a node of the flow sits relative to the case's current position
/// (`CaseFlowNodeStatus`).
///
/// Computed by the server on every read from the same facts the case engine
/// itself reads — held stages, status history, the lab's quality-check
/// setting — and never stored, so the board can never disagree with what
/// actually happened.
enum CaseFlowNodeStatus {
  done(1),
  current(2),
  pending(3),

  /// The lab's own configuration took this node out of the case's path (the
  /// clearest example: quality check on a lab that does not require one).
  /// Drawn, but greyed and struck through — hiding it would make two cases of
  /// the same type look like they ran different routes.
  skipped(4);

  const CaseFlowNodeStatus(this.value);

  final int value;

  bool get isDone => this == CaseFlowNodeStatus.done;
  bool get isCurrent => this == CaseFlowNodeStatus.current;
  bool get isSkipped => this == CaseFlowNodeStatus.skipped;

  /// An unknown value reads as [pending]: an unrecognised node drawn as
  /// "not there yet" is recoverable, drawn as "done" is a lie.
  static CaseFlowNodeStatus fromValue(int? value) {
    for (final status in CaseFlowNodeStatus.values) {
      if (status.value == value) return status;
    }
    return CaseFlowNodeStatus.pending;
  }
}

/// How the material was to reach the laboratory (`CollectionMethod`), carried
/// on the `New` phase node only.
enum CollectionMethod {
  none(1, ''),
  courierCollection(2, 'استلام بمندوب'),
  doctorDelivers(3, 'الطبيب يسلّمها');

  const CollectionMethod(this.value, this.label);

  final int value;
  final String label;

  static CollectionMethod? fromValue(int? value) {
    for (final method in CollectionMethod.values) {
      if (method.value == value) return method;
    }
    return null;
  }
}

/// One stage of a route — the case's own, or one restoration's
/// (`CaseFlowStageDto`).
///
/// This is a node of *this case's* frozen plan, not a row of the restoration
/// type's live catalogue: a lab that redraws a route after the case was
/// created must not change the board of work already in flight.
class CaseFlowStageModel {
  const CaseFlowStageModel({
    required this.stageId,
    this.name,
    this.nameAr,
    this.order = 0,
    this.status = CaseFlowNodeStatus.pending,
    this.isCheckpoint = false,
    this.isExternal = false,
    this.sendBackToStageId,
    this.changedAt,
    this.changedByName,
    this.isReturn = false,
    this.attempt = 1,
  });

  final String stageId;
  final String? name;
  final String? nameAr;

  /// Stages sharing an `order` run in parallel — neither waits on the other.
  final int order;

  final CaseFlowNodeStatus status;

  /// A stage that declares a send-back target: work can be refused here.
  final bool isCheckpoint;

  /// Performed outside the laboratory ("trying at the doctor"), which is why
  /// it can sit `current` for days with nobody in the lab touching it.
  final bool isExternal;

  final String? sendBackToStageId;
  final DateTime? changedAt;
  final String? changedByName;

  /// This node was entered by coming *back* — the piece was reworked. Worth
  /// showing: the same stage name appearing twice is a repair, not a loop bug.
  final bool isReturn;

  /// How many times this stage has been entered, 1 for the ordinary path.
  final int attempt;

  /// Arabic first, English as the fallback, never a placeholder: the lab wrote
  /// these names itself.
  String get displayName {
    final ar = nameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return name?.trim() ?? '';
  }

  factory CaseFlowStageModel.fromJson(Map<String, dynamic> json) {
    return CaseFlowStageModel(
      stageId: json['stageId'] as String? ?? '',
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      order: json['order'] as int? ?? 0,
      status: CaseFlowNodeStatus.fromValue(json['status'] as int?),
      isCheckpoint: json['isCheckpoint'] as bool? ?? false,
      isExternal: json['isExternal'] as bool? ?? false,
      sendBackToStageId: json['sendBackToStageId'] as String?,
      changedAt: DateTime.tryParse(json['changedAt'] as String? ?? ''),
      changedByName: json['changedByName'] as String?,
      isReturn: json['isReturn'] as bool? ?? false,
      attempt: json['attempt'] as int? ?? 1,
    );
  }
}

/// One restoration and its own independent route (`CaseFlowRestorationDto`).
class CaseFlowRestorationModel {
  const CaseFlowRestorationModel({
    required this.restorationId,
    this.restorationNumber,
    this.restorationTypeName,
    this.restorationTypeNameAr,
    this.stages = const [],
  });

  final String restorationId;
  final String? restorationNumber;
  final String? restorationTypeName;
  final String? restorationTypeNameAr;
  final List<CaseFlowStageModel> stages;

  String get displayName {
    final ar = restorationTypeNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return restorationTypeName?.trim() ?? '';
  }

  /// Where the piece is standing. Null once it has finished its route — and
  /// there can be more than one when the route forks into parallel steps, in
  /// which case this is the first of them.
  CaseFlowStageModel? get currentStage {
    for (final stage in stages) {
      if (stage.status.isCurrent) return stage;
    }
    return null;
  }

  factory CaseFlowRestorationModel.fromJson(Map<String, dynamic> json) {
    return CaseFlowRestorationModel(
      restorationId: json['restorationId'] as String? ?? '',
      restorationNumber: json['restorationNumber'] as String?,
      restorationTypeName: json['restorationTypeName'] as String?,
      restorationTypeNameAr: json['restorationTypeNameAr'] as String?,
      stages: [
        for (final stage in json['stages'] as List<dynamic>? ?? const [])
          CaseFlowStageModel.fromJson(stage as Map<String, dynamic>),
      ],
    );
  }
}

/// The `InProduction` sub-tree (`CaseFlowProductionDto`): the case's own
/// stages that run alongside the pieces, every restoration's own route, then
/// the stages that wait for all of them to finish.
class CaseFlowProductionModel {
  const CaseFlowProductionModel({
    this.beforeStages = const [],
    this.restorations = const [],
    this.afterStages = const [],
  });

  final List<CaseFlowStageModel> beforeStages;
  final List<CaseFlowRestorationModel> restorations;

  /// The barrier half: these stay pending until every restoration is done.
  final List<CaseFlowStageModel> afterStages;

  factory CaseFlowProductionModel.fromJson(Map<String, dynamic> json) {
    List<CaseFlowStageModel> stages(String key) => [
      for (final stage in json[key] as List<dynamic>? ?? const [])
        CaseFlowStageModel.fromJson(stage as Map<String, dynamic>),
    ];

    return CaseFlowProductionModel(
      beforeStages: stages('beforeStages'),
      restorations: [
        for (final restoration
            in json['restorations'] as List<dynamic>? ?? const [])
          CaseFlowRestorationModel.fromJson(
            restoration as Map<String, dynamic>,
          ),
      ],
      afterStages: stages('afterStages'),
    );
  }
}

/// One of the six fixed lifecycle checkpoints (`CaseFlowPhaseDto`).
///
/// Each field answers a question only one phase asks — [collectionMethod] on
/// `New`, [receivedVia] on `Received`, [production] on `InProduction` — and
/// stays null elsewhere rather than one shape pretending to answer all six.
class CaseFlowPhaseModel {
  const CaseFlowPhaseModel({
    required this.phase,
    this.status = CaseFlowNodeStatus.pending,
    this.enteredAt,
    this.changedByName,
    this.note,
    this.collectionMethod,
    this.receivedVia,
    this.production,
  });

  final CasePhase? phase;
  final CaseFlowNodeStatus status;
  final DateTime? enteredAt;
  final String? changedByName;
  final String? note;

  /// `New` only.
  final CollectionMethod? collectionMethod;

  /// `Received` only — a stable key, not localized text, so the sentence is
  /// the client's to write. See [receivedViaLabel].
  final String? receivedVia;

  /// `InProduction` only.
  final CaseFlowProductionModel? production;

  /// The Arabic sentence behind the server's key. An unknown key falls back to
  /// the key itself rather than to silence — a new intake route the client has
  /// not been taught yet still says *something* true.
  String? get receivedViaLabel => switch (receivedVia) {
    null || '' => null,
    'digital-rep-session' => 'مسح رقمي بجلسة مندوب',
    'digital-doctor-own' => 'مسح رقمي من الطبيب',
    'traditional-courier' => 'طبعة تقليدية بمندوب',
    'traditional-doctor-delivers' => 'طبعة تقليدية سلّمها الطبيب',
    final other => other,
  };

  factory CaseFlowPhaseModel.fromJson(Map<String, dynamic> json) {
    final production = json['production'] as Map<String, dynamic>?;

    return CaseFlowPhaseModel(
      phase: CasePhase.fromValue(json['phase'] as int?),
      status: CaseFlowNodeStatus.fromValue(json['status'] as int?),
      enteredAt: DateTime.tryParse(json['enteredAt'] as String? ?? ''),
      changedByName: json['changedByName'] as String?,
      note: json['note'] as String?,
      collectionMethod: CollectionMethod.fromValue(
        json['collectionMethod'] as int?,
      ),
      receivedVia: json['receivedVia'] as String?,
      production: production == null
          ? null
          : CaseFlowProductionModel.fromJson(production),
    );
  }
}

/// The whole case lifecycle, assembled server-side (`ClinicCaseFlowDto`).
///
/// `GET /Cases/{id}/flow` replaces what this client used to compose out of the
/// stage catalogue plus one route request per restoration type: the server
/// already reasons about held stages, the production barrier, parallel steps
/// and the case's frozen plan, and a client that recomputed any of it would
/// disagree with the server the moment a lab edited a route mid-case.
class CaseFlowModel {
  const CaseFlowModel({
    required this.caseId,
    this.currentPhase,
    this.phases = const [],
  });

  final String caseId;
  final CasePhase? currentPhase;
  final List<CaseFlowPhaseModel> phases;

  /// The production sub-tree, wherever the server hung it.
  CaseFlowProductionModel? get production {
    for (final phase in phases) {
      final production = phase.production;
      if (production != null) return production;
    }
    return null;
  }

  List<CaseFlowStageModel> get beforeStages =>
      production?.beforeStages ?? const [];

  List<CaseFlowStageModel> get afterStages =>
      production?.afterStages ?? const [];

  List<CaseFlowRestorationModel> get restorations =>
      production?.restorations ?? const [];

  /// True once every restoration has finished its route — what the
  /// after-production half is waiting on. Vacuously false with no pieces at
  /// all, which is the same answer the barrier needs: nothing to wait for.
  bool get restorationsFinished =>
      restorations.isNotEmpty &&
      restorations.every(
        (restoration) => restoration.stages.every(
          (stage) => stage.status.isDone || stage.status.isSkipped,
        ),
      );

  factory CaseFlowModel.fromJson(Map<String, dynamic> json) {
    return CaseFlowModel(
      caseId: json['caseId'] as String? ?? '',
      currentPhase: CasePhase.fromValue(json['currentPhase'] as int?),
      phases: [
        for (final phase in json['phases'] as List<dynamic>? ?? const [])
          CaseFlowPhaseModel.fromJson(phase as Map<String, dynamic>),
      ],
    );
  }
}
