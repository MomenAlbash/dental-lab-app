import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_list_item_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/save_case_ticket_template_request_models.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/repos/case_ticket_templates_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CreateCaseTicketTemplateRequestModel(name: 'x'),
    );
    registerFallbackValue(
      const UpdateCaseTicketTemplateRequestModel(name: 'x'),
    );
  });

  late _MockApiService api;
  late CaseTicketTemplatesRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    api = _MockApiService();
    repo = CaseTicketTemplatesRepo(api);
  });

  test('lists templates for the given laboratory', () async {
    when(
      () => api.getCaseTicketTemplates(
        laboratoryId: any(named: 'laboratoryId'),
        token: any(named: 'token'),
      ),
    ).thenAnswer(
      (_) async => const [
        CaseTicketTemplateListItemModel(id: 't1', name: 'طابعة الاستقبال'),
      ],
    );

    final result = await repo.getCaseTicketTemplates(laboratoryId: 'lab1');

    expect(result.getOrElse(() => []).single.name, 'طابعة الاستقبال');
    verify(
      () => api.getCaseTicketTemplates(
        laboratoryId: 'lab1',
        token: any(named: 'token'),
      ),
    ).called(1);
  });

  test('creating scopes the request to the chosen laboratory', () async {
    when(
      () => api.createCaseTicketTemplate(
        body: any(named: 'body'),
        laboratoryId: any(named: 'laboratoryId'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => const CaseTicketTemplateModel(id: 't1'));

    final result = await repo.createCaseTicketTemplate(
      requestBody: const CreateCaseTicketTemplateRequestModel(
        name: 'طابعة جديدة',
      ),
      laboratoryId: 'lab1',
    );

    expect(result.isRight(), isTrue);
    verify(
      () => api.createCaseTicketTemplate(
        body: any(named: 'body'),
        laboratoryId: 'lab1',
        token: any(named: 'token'),
      ),
    ).called(1);
  });

  test('a delete failure is reported, not thrown', () async {
    when(
      () => api.deleteCaseTicketTemplate(
        id: any(named: 'id'),
        token: any(named: 'token'),
      ),
    ).thenThrow(Exception('لا يوجد اتصال'));

    final result = await repo.deleteCaseTicketTemplate('t1');

    expect(result.isLeft(), isTrue);
  });

  test('setting default returns the now-default template', () async {
    when(
      () => api.setDefaultCaseTicketTemplate(
        id: any(named: 'id'),
        token: any(named: 'token'),
      ),
    ).thenAnswer(
      (_) async => const CaseTicketTemplateModel(id: 't1', isDefault: true),
    );

    final result = await repo.setDefaultCaseTicketTemplate('t1');

    expect(result.fold((_) => null, (t) => t.isDefault), isTrue);
  });
}
