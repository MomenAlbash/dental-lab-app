import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CaseFormCubit extends Cubit<CaseFormState> {
  CaseFormCubit(this._casesRepo) : super(const CaseFormInitial());

  final CasesRepo _casesRepo;

  /// [attachmentPaths] are uploaded one at a time in a second round of
  /// requests, fired only once the case exists — there is no case id to
  /// attach them to before that. A failed upload does not undo the case: the
  /// case is the one thing here that cannot be re-entered by hand, so it is
  /// reported as saved regardless, with
  /// [CaseFormSuccess.failedAttachmentCount] carrying the rest of the story.
  ///
  /// Deliberately not `POST /Cases/with-files` (one atomic multipart
  /// request): that endpoint's failure mode is a single request either
  /// succeeding or failing whole, which would let one bad file lose the case
  /// data along with it — worse than the case being saved and only one
  /// attachment needing a retry.
  Future<void> createCase(
    CreateCaseRequestModel createCaseRequestBody, {
    List<String> attachmentPaths = const [],
  }) async {
    emit(const CaseFormSubmitting());

    final result = await _casesRepo.createCase(createCaseRequestBody);

    await result.fold(
      (failure) async => emit(CaseFormError(failure.errorMessage)),
      (caseDetail) async {
        if (attachmentPaths.isEmpty) {
          emit(CaseFormSuccess(caseDetail));
          return;
        }

        var failedCount = 0;
        for (final path in attachmentPaths) {
          final uploadResult = await _casesRepo.uploadFile(
            id: caseDetail.id,
            filePath: path,
          );
          if (uploadResult.isLeft()) failedCount++;
        }

        emit(CaseFormSuccess(caseDetail, failedAttachmentCount: failedCount));
      },
    );
  }
}
