import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';

sealed class CasesState {
  const CasesState();
}

class CasesInitial extends CasesState {
  const CasesInitial();
}

class CasesLoading extends CasesState {
  const CasesLoading();
}

class CasesLoaded extends CasesState {
  const CasesLoaded(
    this.cases, {
    this.phaseCounts = CasePhaseCountsModel.empty,
    this.slaCounts = CaseSlaCountsModel.empty,
    this.filters = CaseFiltersModel.empty,
    this.isMyTasks = false,
  });

  final List<CaseListItemModel> cases;

  /// The tab bar's badges, counted by the server under the same filters the
  /// rows were fetched with — never by counting [cases], which is one page.
  final CasePhaseCountsModel phaseCounts;

  /// The date segment's badges, counted the same way.
  final CaseSlaCountsModel slaCounts;

  /// Carried on the state so the tab bar and the segment draw from the same
  /// snapshot the rows came from, rather than reading the cubit's live fields
  /// mid-reload and disagreeing with what is on screen.
  final CaseFiltersModel filters;

  /// The list is narrowed to the stages this login is assigned.
  final bool isMyTasks;
}

/// "My tasks" was asked for, and this login is assigned no stages at all.
///
/// A state of its own rather than an empty list: the two mean different things
/// — nothing assigned to you is not the same as nothing to do — and the queue
/// must not silently widen back to every case in the laboratory.
class CasesNoAssignments extends CasesState {
  const CasesNoAssignments();
}

class CasesError extends CasesState {
  const CasesError(this.message);
  final String message;
}

class CaseDeleted extends CasesState {
  const CaseDeleted();
}

class CaseDeleteError extends CasesState {
  const CaseDeleteError(this.message);
  final String message;
}
