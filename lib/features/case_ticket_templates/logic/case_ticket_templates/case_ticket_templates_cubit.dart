import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_list_item_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/save_case_ticket_template_request_models.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/repos/case_ticket_templates_repo.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_templates/case_ticket_templates_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CaseTicketTemplatesCubit extends Cubit<CaseTicketTemplatesState> {
  CaseTicketTemplatesCubit(this._repo)
    : super(const CaseTicketTemplatesInitial());

  final CaseTicketTemplatesRepo _repo;

  Future<void> getTemplates() async {
    emit(const CaseTicketTemplatesLoading());

    final result = await _repo.getCaseTicketTemplates();

    result.fold(
      (failure) => emit(CaseTicketTemplatesError(failure.errorMessage)),
      (templates) => emit(CaseTicketTemplatesLoaded(templates)),
    );
  }

  List<CaseTicketTemplateListItemModel> get _currentList => switch (state) {
    CaseTicketTemplatesLoaded(:final templates) => templates,
    _ => const [],
  };

  /// Creates a new (empty) template and returns it so the caller can push
  /// straight into its editor — a template with no rows is not useful on
  /// its own.
  Future<CaseTicketTemplateModel?> addTemplate(String name) async {
    final templates = _currentList;
    emit(CaseTicketTemplatesLoaded(templates, isBusy: true));

    final result = await _repo.createCaseTicketTemplate(
      requestBody: CreateCaseTicketTemplateRequestModel(name: name),
    );

    return result.fold(
      (failure) {
        emit(CaseTicketTemplatesActionError(failure.errorMessage));
        emit(CaseTicketTemplatesLoaded(templates));
        return null;
      },
      (created) {
        emit(
          CaseTicketTemplatesLoaded([
            ...templates,
            CaseTicketTemplateListItemModel(
              id: created.id,
              name: created.name,
              isDefault: created.isDefault,
              paperWidthMm: created.paperWidthMm,
            ),
          ]),
        );
        return created;
      },
    );
  }

  Future<void> removeTemplate(String id) async {
    final templates = _currentList;
    emit(CaseTicketTemplatesLoaded(templates, isBusy: true));

    final result = await _repo.deleteCaseTicketTemplate(id);

    result.fold(
      (failure) {
        emit(CaseTicketTemplatesActionError(failure.errorMessage));
        emit(CaseTicketTemplatesLoaded(templates));
      },
      (_) => emit(
        CaseTicketTemplatesLoaded(templates.where((t) => t.id != id).toList()),
      ),
    );
  }

  /// Setting a default flips every other template's flag off server-side —
  /// a full reload is what keeps this list honest, not a local patch of one
  /// row.
  Future<void> setDefault(String id) async {
    final templates = _currentList;
    emit(CaseTicketTemplatesLoaded(templates, isBusy: true));

    final result = await _repo.setDefaultCaseTicketTemplate(id);

    await result.fold((failure) async {
      emit(CaseTicketTemplatesActionError(failure.errorMessage));
      emit(CaseTicketTemplatesLoaded(templates));
    }, (_) => getTemplates());
  }
}
