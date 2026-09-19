import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';

sealed class CaseTicketTemplateEditorState {
  const CaseTicketTemplateEditorState();
}

class CaseTicketTemplateEditorLoading extends CaseTicketTemplateEditorState {
  const CaseTicketTemplateEditorLoading();
}

class CaseTicketTemplateEditorLoaded extends CaseTicketTemplateEditorState {
  const CaseTicketTemplateEditorLoaded(this.template, {this.isSaving = false});
  final CaseTicketTemplateModel template;
  final bool isSaving;
}

class CaseTicketTemplateEditorError extends CaseTicketTemplateEditorState {
  const CaseTicketTemplateEditorError(this.message);
  final String message;
}

/// A one-shot message — the cubit emits it, the screen toasts it, and the
/// loaded state comes straight back underneath.
class CaseTicketTemplateEditorMessage extends CaseTicketTemplateEditorState {
  const CaseTicketTemplateEditorMessage(this.message, {this.isError = false});
  final String message;
  final bool isError;
}
