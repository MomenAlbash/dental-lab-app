import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/save_case_ticket_template_request_models.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/repos/case_ticket_templates_repo.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_template_editor/case_ticket_template_editor_cubit.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_template_editor/case_ticket_template_editor_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCaseTicketTemplatesRepo extends Mock
    implements CaseTicketTemplatesRepo {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const UpdateCaseTicketTemplateRequestModel(name: 'x'),
    );
  });

  late _MockCaseTicketTemplatesRepo repo;
  late CaseTicketTemplateEditorCubit cubit;

  setUp(() {
    repo = _MockCaseTicketTemplatesRepo();
    cubit = CaseTicketTemplateEditorCubit(repo);
  });

  tearDown(() => cubit.close());

  const template = CaseTicketTemplateModel(id: 't1', name: 'الاستقبال');

  test('load resolves the template by id', () async {
    when(
      () => repo.getCaseTicketTemplateById('t1'),
    ).thenAnswer((_) async => right(template));

    await cubit.load('t1');

    final loaded = cubit.state as CaseTicketTemplateEditorLoaded;
    expect(loaded.template, template);
    expect(loaded.isSaving, isFalse);
  });

  test('a load failure reports the reason', () async {
    when(
      () => repo.getCaseTicketTemplateById('t1'),
    ).thenAnswer((_) async => left(ServerFailure('غير موجود')));

    await cubit.load('t1');

    expect(cubit.state, isA<CaseTicketTemplateEditorError>());
    expect((cubit.state as CaseTicketTemplateEditorError).message, 'غير موجود');
  });

  test('save replaces the loaded template on success', () async {
    when(
      () => repo.getCaseTicketTemplateById('t1'),
    ).thenAnswer((_) async => right(template));
    await cubit.load('t1');

    const updated = CaseTicketTemplateModel(id: 't1', name: 'الاستقبال 2');
    when(
      () => repo.updateCaseTicketTemplate(
        id: 't1',
        requestBody: any(named: 'requestBody'),
      ),
    ).thenAnswer((_) async => right(updated));

    await cubit.save(
      id: 't1',
      requestBody: const UpdateCaseTicketTemplateRequestModel(
        name: 'الاستقبال 2',
      ),
    );

    final loaded = cubit.state as CaseTicketTemplateEditorLoaded;
    expect(loaded.template, updated);
  });

  test('a save failure restores the prior template unsaved', () async {
    when(
      () => repo.getCaseTicketTemplateById('t1'),
    ).thenAnswer((_) async => right(template));
    await cubit.load('t1');

    when(
      () => repo.updateCaseTicketTemplate(
        id: 't1',
        requestBody: any(named: 'requestBody'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('فشل الحفظ')));

    await cubit.save(
      id: 't1',
      requestBody: const UpdateCaseTicketTemplateRequestModel(name: 'x'),
    );

    final loaded = cubit.state as CaseTicketTemplateEditorLoaded;
    expect(loaded.template, template);
    expect(loaded.isSaving, isFalse);
  });
}
