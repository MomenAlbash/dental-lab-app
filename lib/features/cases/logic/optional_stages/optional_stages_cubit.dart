import 'package:dental_lab_app/features/case_stages/data/repos/case_stages_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/repos/workflow_stages_repo.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/logic/optional_stages/optional_stages_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Collects the stages a new case may opt into.
///
/// Two sources, because the lab draws its work in two places: the case's own
/// workflow (`/case-statuses`) and each restoration type's route
/// (`/restoration-type-stages`). A stage marked `isOptional` in either is not
/// cut onto the case unless somebody says so, so the form asks about every
/// one of them.
///
/// The two answers do **not** go out together: a case stage's answer is the
/// request's `selectedCaseStagesIds`, a route stage's belongs to the
/// restoration that runs it. [OptionalStage.isCaseStage] is what keeps them
/// apart, which is why the origin is recorded here rather than flattened away.
class OptionalStagesCubit extends Cubit<OptionalStagesState> {
  OptionalStagesCubit(this._caseStagesRepo, this._workflowStagesRepo)
    : super(const OptionalStagesState());

  final CaseStagesRepo _caseStagesRepo;
  final WorkflowStagesRepo _workflowStagesRepo;

  /// What the last load was for, so stepping back and forth in the wizard
  /// does not refetch. The intake is part of the key: a route carries a
  /// traditional head and a digital head, and switching intake changes which
  /// stages are even on offer.
  List<String> _loadedForTypes = const [];
  ImpressionMethod? _loadedForIntake;
  bool _hasLoadKey = false;

  /// Loads the optional stages for [restorationTypeIds] under [intake], plus
  /// the case-level ones. Passing the same key again is a no-op.
  Future<void> load(
    List<String> restorationTypeIds, {
    ImpressionMethod? intake,
  }) async {
    final types = {...restorationTypeIds}.toList()..sort();
    if (state.hasLoaded &&
        _hasLoadKey &&
        _loadedForIntake == intake &&
        _sameAsLoaded(types)) {
      return;
    }

    _loadedForTypes = types;
    _loadedForIntake = intake;
    _hasLoadKey = true;
    emit(const OptionalStagesState(isLoading: true));

    final stages = <OptionalStage>[];
    // Route stages are collected by id first: the same stage can be offered
    // by several restoration types, and it must be asked about once while
    // still remembering every type it applies to.
    final routeTypes = <String, Set<String>>{};
    final routeNames = <String, String>{};
    var failed = false;

    final caseStages = await _caseStagesRepo.getCaseStages();
    if (isClosed) return;
    caseStages.fold((_) => failed = true, (list) {
      for (final stage in list) {
        if (!stage.isOptional || !stage.isActive) continue;
        stages.add(
          OptionalStage(
            id: stage.id,
            name: stage.displayName,
            isCaseStage: true,
          ),
        );
      }
    });

    for (final typeId in types) {
      final result = await _workflowStagesRepo.getStages(
        restorationTypeId: typeId,
      );
      if (isClosed) return;

      result.fold((_) => failed = true, (list) {
        for (final stage in list) {
          if (!stage.isOptional || !stage.isActive) continue;
          // A route has a traditional head and a digital head and the server
          // prunes one of them. Asking about a stage this case's intake will
          // never run is asking a question with no consequence.
          if (!stage.appliesToIntake(intake)) continue;

          routeNames[stage.id] = stage.displayName;
          (routeTypes[stage.id] ??= <String>{}).add(typeId);
        }
      });
    }

    for (final entry in routeTypes.entries) {
      stages.add(
        OptionalStage(
          id: entry.key,
          name: routeNames[entry.key] ?? '',
          isCaseStage: false,
          restorationTypeIds: entry.value,
        ),
      );
    }

    if (isClosed) return;
    emit(
      OptionalStagesState(stages: stages, hasLoaded: true, hasFailure: failed),
    );
  }

  bool _sameAsLoaded(List<String> types) {
    if (types.length != _loadedForTypes.length) return false;
    for (var i = 0; i < types.length; i++) {
      if (types[i] != _loadedForTypes[i]) return false;
    }
    return true;
  }
}
