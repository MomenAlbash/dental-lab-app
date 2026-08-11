import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_status.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

CaseListItemModel _case(String id, CaseStatus status) =>
    CaseListItemModel(id: id, caseNumber: id, caseStatus: status);

void main() {
  late _MockApiService api;
  late CasesRepo repo;

  final all = [
    _case('1', CaseStatus.inProgress),
    _case('2', CaseStatus.rejected),
    _case('3', CaseStatus.created),
  ];

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    api = _MockApiService();
    repo = CasesRepo(api);
  });

  test(
    'narrows to the requested status even when the API returns everything',
    () async {
      // The API ignoring the CaseStatus query param is exactly the bug: it
      // answers with the full list and the filter appeared to do nothing.
      when(
        () => api.getCases(
          search: any(named: 'search'),
          doctorId: any(named: 'doctorId'),
          clinicId: any(named: 'clinicId'),
          patientId: any(named: 'patientId'),
          priorityId: any(named: 'priorityId'),
          caseStatus: any(named: 'caseStatus'),
          dueDateFrom: any(named: 'dueDateFrom'),
          dueDateTo: any(named: 'dueDateTo'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => all);

      final result = await repo.getCases(
        filters: const CaseFiltersModel(caseStatus: CaseStatus.rejected),
      );

      final cases = result.getOrElse(() => []);
      expect(cases.map((c) => c.id), ['2']);
    },
  );

  test('returns every case when no status filter is set', () async {
    when(
      () => api.getCases(
        search: any(named: 'search'),
        doctorId: any(named: 'doctorId'),
        clinicId: any(named: 'clinicId'),
        patientId: any(named: 'patientId'),
        priorityId: any(named: 'priorityId'),
        caseStatus: any(named: 'caseStatus'),
        dueDateFrom: any(named: 'dueDateFrom'),
        dueDateTo: any(named: 'dueDateTo'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => all);

    final result = await repo.getCases();

    expect(result.getOrElse(() => []).length, 3);
  });
}
