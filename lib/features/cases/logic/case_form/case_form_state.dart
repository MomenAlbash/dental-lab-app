import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';

sealed class CaseFormState {
  const CaseFormState();
}

class CaseFormInitial extends CaseFormState {
  const CaseFormInitial();
}

class CaseFormSubmitting extends CaseFormState {
  const CaseFormSubmitting();
}

class CaseFormSuccess extends CaseFormState {
  const CaseFormSuccess(this.caseDetail);
  final CaseDetailModel caseDetail;
}

class CaseFormError extends CaseFormState {
  const CaseFormError(this.message);
  final String message;
}
