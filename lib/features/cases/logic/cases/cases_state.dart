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
  const CasesLoaded(this.cases);
  final List<CaseListItemModel> cases;
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
