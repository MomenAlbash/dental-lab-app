import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_list_item_model.dart';

sealed class CaseTicketTemplatesState {
  const CaseTicketTemplatesState();
}

class CaseTicketTemplatesInitial extends CaseTicketTemplatesState {
  const CaseTicketTemplatesInitial();
}

class CaseTicketTemplatesLoading extends CaseTicketTemplatesState {
  const CaseTicketTemplatesLoading();
}

class CaseTicketTemplatesLoaded extends CaseTicketTemplatesState {
  const CaseTicketTemplatesLoaded(this.templates, {this.isBusy = false});
  final List<CaseTicketTemplateListItemModel> templates;

  /// True while a create/delete/set-default is in flight.
  final bool isBusy;
}

class CaseTicketTemplatesError extends CaseTicketTemplatesState {
  const CaseTicketTemplatesError(this.message);
  final String message;
}

/// Transient failure of an action — surfaced as a toast.
class CaseTicketTemplatesActionError extends CaseTicketTemplatesState {
  const CaseTicketTemplatesActionError(this.message);
  final String message;
}
