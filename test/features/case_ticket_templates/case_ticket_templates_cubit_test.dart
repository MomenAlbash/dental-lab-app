import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_list_item_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/save_case_ticket_template_request_models.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/repos/case_ticket_templates_repo.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_templates/case_ticket_templates_cubit.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_templates/case_ticket_templates_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCaseTicketTemplatesRepo extends Mock
    implements CaseTicketTemplatesRepo {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CreateCaseTicketTemplateRequestModel(name: 'x'),
    );
  });

  late _MockCaseTicketTemplatesRepo repo;
  late CaseTicketTemplatesCubit cubit;

  setUp(() {
    repo = _MockCaseTicketTemplatesRepo();
    cubit = CaseTicketTemplatesCubit(repo);
  });

  tearDown(() => cubit.close());

  const template = CaseTicketTemplateListItemModel(
    id: 't1',
    name: 'الاستقبال',
    isDefault: true,
    paperWidthMm: 80,
  );

  test('getTemplates loads the list', () async {
    when(
      () => repo.getCaseTicketTemplates(),
    ).thenAnswer((_) async => right([template]));

    await cubit.getTemplates();

    final loaded = cubit.state as CaseTicketTemplatesLoaded;
    expect(loaded.templates, [template]);
  });

  test('a load failure reports the reason', () async {
    when(
      () => repo.getCaseTicketTemplates(),
    ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

    await cubit.getTemplates();

    expect(cubit.state, isA<CaseTicketTemplatesError>());
    expect((cubit.state as CaseTicketTemplatesError).message, 'لا يوجد اتصال');
  });

  test('addTemplate appends the created template and returns it', () async {
    when(
      () => repo.getCaseTicketTemplates(),
    ).thenAnswer((_) async => right([template]));
    await cubit.getTemplates();

    final created = CaseTicketTemplateModel(id: 't2', name: 'مخبر');
    when(
      () =>
          repo.createCaseTicketTemplate(requestBody: any(named: 'requestBody')),
    ).thenAnswer((_) async => right(created));

    final result = await cubit.addTemplate('مخبر');

    expect(result, created);
    final loaded = cubit.state as CaseTicketTemplatesLoaded;
    expect(loaded.templates.map((t) => t.id), ['t1', 't2']);
  });

  test('addTemplate reports the failure and keeps the existing list', () async {
    when(
      () => repo.getCaseTicketTemplates(),
    ).thenAnswer((_) async => right([template]));
    await cubit.getTemplates();

    when(
      () =>
          repo.createCaseTicketTemplate(requestBody: any(named: 'requestBody')),
    ).thenAnswer((_) async => left(ServerFailure('فشل الإنشاء')));

    final result = await cubit.addTemplate('مخبر');

    expect(result, isNull);
    final loaded = cubit.state as CaseTicketTemplatesLoaded;
    expect(loaded.templates, [template]);
  });

  test('removeTemplate drops the deleted template from the list', () async {
    when(
      () => repo.getCaseTicketTemplates(),
    ).thenAnswer((_) async => right([template]));
    await cubit.getTemplates();

    when(
      () => repo.deleteCaseTicketTemplate('t1'),
    ).thenAnswer((_) async => right(null));

    await cubit.removeTemplate('t1');

    final loaded = cubit.state as CaseTicketTemplatesLoaded;
    expect(loaded.templates, isEmpty);
  });

  test('setDefault reloads the full list from the server', () async {
    when(
      () => repo.getCaseTicketTemplates(),
    ).thenAnswer((_) async => right([template]));
    await cubit.getTemplates();

    when(
      () => repo.setDefaultCaseTicketTemplate('t1'),
    ).thenAnswer((_) async => right(const CaseTicketTemplateModel(id: 't1')));
    final reloaded = [
      const CaseTicketTemplateListItemModel(id: 't1', isDefault: true),
    ];
    when(
      () => repo.getCaseTicketTemplates(),
    ).thenAnswer((_) async => right(reloaded));

    await cubit.setDefault('t1');

    verify(() => repo.getCaseTicketTemplates()).called(2);
    final loaded = cubit.state as CaseTicketTemplatesLoaded;
    expect(loaded.templates, reloaded);
  });
}
