import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_stage_summary.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

CaseListItemModel _case(String id, String stageId) => CaseListItemModel(
  id: id,
  caseNumber: id,
  stage: CaseStageSummary(stageId: stageId, stageNameAr: 'مرحلة $stageId'),
);

/// Every named parameter has to be matched, or mocktail treats the call as
/// unstubbed.
void _stubGetCases(_MockApiService api, List<CaseListItemModel> answer) {
  when(
    () => api.getCases(
      search: any(named: 'search'),
      doctorId: any(named: 'doctorId'),
      clinicId: any(named: 'clinicId'),
      patientId: any(named: 'patientId'),
      priorityId: any(named: 'priorityId'),
      stageIds: any(named: 'stageIds'),
      restorationStageIds: any(named: 'restorationStageIds'),
      laboratoryIds: any(named: 'laboratoryIds'),
      receivedFrom: any(named: 'receivedFrom'),
      receivedTo: any(named: 'receivedTo'),
      phaseTab: any(named: 'phaseTab'),
      slaParam: any(named: 'slaParam'),
      token: any(named: 'token'),
    ),
  ).thenAnswer((_) async => answer);
}

void main() {
  late _MockApiService api;
  late CasesRepo repo;

  final all = [_case('1', 's1'), _case('2', 's2'), _case('3', 's3')];

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    api = _MockApiService();
    repo = CasesRepo(api);
  });

  test(
    'narrows to the requested stages even when the API returns everything',
    () async {
      // A server that answers an unrecognised param with the full list is
      // exactly what makes a filter look like it does nothing. Re-applying it
      // locally also covers the offline cache path, where no query ran at all.
      _stubGetCases(api, all);

      final result = await repo.getCases(
        filters: const CaseFiltersModel(stageIds: {'s2'}),
      );

      expect(result.getOrElse(() => []).map((c) => c.id), ['2']);
    },
  );

  test('several stages at once keep all of their cases', () async {
    _stubGetCases(api, all);

    final result = await repo.getCases(
      filters: const CaseFiltersModel(stageIds: {'s1', 's3'}),
    );

    expect(result.getOrElse(() => []).map((c) => c.id), ['1', '3']);
  });

  test('returns every case when no stage filter is set', () async {
    _stubGetCases(api, all);

    final result = await repo.getCases();

    expect(result.getOrElse(() => []).length, 3);
  });

  test(
    'passes the stage ids and the received window through to the API',
    () async {
      _stubGetCases(api, all);

      await repo.getCases(
        filters: CaseFiltersModel(
          stageIds: const {'s1'},
          receivedFrom: DateTime(2026, 3, 1),
        ),
      );

      final captured = verify(
        () => api.getCases(
          search: any(named: 'search'),
          doctorId: any(named: 'doctorId'),
          clinicId: any(named: 'clinicId'),
          patientId: any(named: 'patientId'),
          priorityId: any(named: 'priorityId'),
          stageIds: captureAny(named: 'stageIds'),
          restorationStageIds: any(named: 'restorationStageIds'),
          laboratoryIds: any(named: 'laboratoryIds'),
          receivedFrom: captureAny(named: 'receivedFrom'),
          receivedTo: any(named: 'receivedTo'),
          phaseTab: any(named: 'phaseTab'),
          slaParam: any(named: 'slaParam'),
          token: any(named: 'token'),
        ),
      ).captured;

      expect(captured[0], ['s1']);
      // The window filters on reception; the API's old due-date params are gone.
      expect(captured[1], startsWith('2026-03-01'));
    },
  );
}
