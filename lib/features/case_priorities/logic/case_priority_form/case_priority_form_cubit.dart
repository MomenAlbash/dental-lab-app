import 'package:dental_lab_app/features/case_priorities/data/models/save_case_priority_request_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priority_form/case_priority_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CasePriorityFormCubit extends Cubit<CasePriorityFormState> {
  CasePriorityFormCubit(this._repo) : super(const CasePriorityFormInitial());

  final CasePrioritiesRepo _repo;

  Future<void> createCasePriority(
    SaveCasePriorityRequestModel saveRequestBody,
  ) async {
    emit(const CasePriorityFormSubmitting());

    final result = await _repo.createCasePriority(saveRequestBody);

    result.fold(
      (failure) => emit(CasePriorityFormError(failure.errorMessage)),
      (priority) => emit(CasePriorityFormSuccess(priority)),
    );
  }

  Future<void> updateCasePriority({
    required String id,
    required SaveCasePriorityRequestModel saveRequestBody,
  }) async {
    emit(const CasePriorityFormSubmitting());

    final result = await _repo.updateCasePriority(
      id: id,
      saveRequestBody: saveRequestBody,
    );

    result.fold(
      (failure) => emit(CasePriorityFormError(failure.errorMessage)),
      (priority) => emit(CasePriorityFormSuccess(priority)),
    );
  }
}
