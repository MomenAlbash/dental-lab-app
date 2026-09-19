import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late CasesRepo repo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    api = _MockApiService();
    repo = CasesRepo(api);
  });

  group('exportCasesCsv', () {
    test('passes the same filters the case list itself uses', () async {
      when(
        () => api.exportCasesCsv(
          search: any(named: 'search'),
          doctorId: any(named: 'doctorId'),
          clinicId: any(named: 'clinicId'),
          patientId: any(named: 'patientId'),
          priorityId: any(named: 'priorityId'),
          stageIds: any(named: 'stageIds'),
          laboratoryIds: any(named: 'laboratoryIds'),
          receivedFrom: any(named: 'receivedFrom'),
          receivedTo: any(named: 'receivedTo'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => const []);

      // The bytes come back fine here; only the file write that follows has
      // nowhere to land in a widget-less test — that failure is not what
      // this test is checking.
      await repo.exportCasesCsv(
        search: 'محمد',
        filters: const CaseFiltersModel(stageIds: {'s1'}, doctorId: 'd1'),
      );

      final captured = verify(
        () => api.exportCasesCsv(
          search: captureAny(named: 'search'),
          doctorId: captureAny(named: 'doctorId'),
          clinicId: any(named: 'clinicId'),
          patientId: any(named: 'patientId'),
          priorityId: any(named: 'priorityId'),
          stageIds: captureAny(named: 'stageIds'),
          laboratoryIds: any(named: 'laboratoryIds'),
          receivedFrom: any(named: 'receivedFrom'),
          receivedTo: any(named: 'receivedTo'),
          token: any(named: 'token'),
        ),
      ).captured;

      expect(captured[0], 'محمد');
      expect(captured[1], 'd1');
      expect(captured[2], ['s1']);
    });

    test('a server failure is reported, not thrown', () async {
      when(
        () => api.exportCasesCsv(
          search: any(named: 'search'),
          doctorId: any(named: 'doctorId'),
          clinicId: any(named: 'clinicId'),
          patientId: any(named: 'patientId'),
          priorityId: any(named: 'priorityId'),
          stageIds: any(named: 'stageIds'),
          laboratoryIds: any(named: 'laboratoryIds'),
          receivedFrom: any(named: 'receivedFrom'),
          receivedTo: any(named: 'receivedTo'),
          token: any(named: 'token'),
        ),
      ).thenThrow(Exception('لا يوجد اتصال'));

      final result = await repo.exportCasesCsv();

      expect(result.isLeft(), isTrue);
    });
  });

  group('downloadCasePdf', () {
    test('asks for the exact case id', () async {
      when(
        () => api.downloadCasePdf(
          id: any(named: 'id'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => const []);

      await repo.downloadCasePdf(id: 'c1', caseNumber: 'CASE-001');

      verify(
        () => api.downloadCasePdf(
          id: 'c1',
          token: any(named: 'token'),
        ),
      ).called(1);
    });

    test('a server failure is reported, not thrown', () async {
      when(
        () => api.downloadCasePdf(
          id: any(named: 'id'),
          token: any(named: 'token'),
        ),
      ).thenThrow(Exception('لا يوجد اتصال'));

      final result = await repo.downloadCasePdf(id: 'c1', caseNumber: 'c1');

      expect(result.isLeft(), isTrue);
    });
  });
}
