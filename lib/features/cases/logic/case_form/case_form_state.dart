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
  const CaseFormSuccess(this.caseDetail, {this.failedAttachmentCount = 0});
  final CaseDetailModel caseDetail;

  /// The case itself is safely saved either way — this only counts how many
  /// of the picked files' own follow-up uploads failed, so the page can say
  /// so without treating the whole submission as a failure. Zero means every
  /// attachment (if any were picked) made it.
  final int failedAttachmentCount;

  bool get attachmentFailed => failedAttachmentCount > 0;
}

class CaseFormError extends CaseFormState {
  const CaseFormError(this.message);
  final String message;
}
