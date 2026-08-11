import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CaseFormCubit extends Cubit<CaseFormState> {
  CaseFormCubit(this._casesRepo) : super(const CaseFormInitial());

  final CasesRepo _casesRepo;

  Future<void> createCase(CreateCaseRequestModel createCaseRequestBody) async {
    emit(const CaseFormSubmitting());

    final result = await _casesRepo.createCase(createCaseRequestBody);

    result.fold(
      (failure) => emit(CaseFormError(failure.errorMessage)),
      (caseDetail) => emit(CaseFormSuccess(caseDetail)),
    );
  }
}
