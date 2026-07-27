import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';

sealed class CaseDetailsState {
  const CaseDetailsState();
}

class CaseDetailsInitial extends CaseDetailsState {
  const CaseDetailsInitial();
}

class CaseDetailsLoading extends CaseDetailsState {
  const CaseDetailsLoading();
}

class CaseDetailsLoaded extends CaseDetailsState {
  const CaseDetailsLoaded(this.caseDetail, {this.isBusy = false});

  final CaseDetailModel caseDetail;

  /// True while a stage change or file action is in flight.
  final bool isBusy;
}

class CaseDetailsError extends CaseDetailsState {
  const CaseDetailsError(this.message);
  final String message;
}

/// Transient failure of an action — surfaced as a toast.
class CaseDetailsActionError extends CaseDetailsState {
  const CaseDetailsActionError(this.message);
  final String message;
}

/// Transient success of an action — surfaced as a toast.
class CaseDetailsActionSuccess extends CaseDetailsState {
  const CaseDetailsActionSuccess(this.message);
  final String message;
}
