import 'package:dental_lab_app/features/case_ticket_templates/data/models/save_case_ticket_template_request_models.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/repos/case_ticket_templates_repo.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_template_editor/case_ticket_template_editor_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One template's own editor — load its current layout, then save the whole
/// thing back as a full replace. The draft being edited (row list, name,
/// paper width) lives on the editor page itself; this cubit only ever holds
/// the last version confirmed with the server.
class CaseTicketTemplateEditorCubit
    extends Cubit<CaseTicketTemplateEditorState> {
  CaseTicketTemplateEditorCubit(this._repo)
    : super(const CaseTicketTemplateEditorLoading());

  final CaseTicketTemplatesRepo _repo;

  Future<void> load(String id) async {
    emit(const CaseTicketTemplateEditorLoading());

    final result = await _repo.getCaseTicketTemplateById(id);

    result.fold(
      (failure) => emit(CaseTicketTemplateEditorError(failure.errorMessage)),
      (template) => emit(CaseTicketTemplateEditorLoaded(template)),
    );
  }

  Future<void> save({
    required String id,
    required UpdateCaseTicketTemplateRequestModel requestBody,
  }) async {
    final current = state;
    if (current is! CaseTicketTemplateEditorLoaded) return;
    emit(CaseTicketTemplateEditorLoaded(current.template, isSaving: true));

    final result = await _repo.updateCaseTicketTemplate(
      id: id,
      requestBody: requestBody,
    );

    result.fold(
      (failure) {
        emit(
          CaseTicketTemplateEditorMessage(failure.errorMessage, isError: true),
        );
        emit(current);
      },
      (updated) {
        emit(const CaseTicketTemplateEditorMessage('تم حفظ القالب'));
        emit(CaseTicketTemplateEditorLoaded(updated));
      },
    );
  }
}
