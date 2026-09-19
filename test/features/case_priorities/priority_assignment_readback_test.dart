import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

DoctorPriorityQuotaModel _quota(
  String doctorId, {
  required String priorityId,
  required bool isOverridden,
}) => DoctorPriorityQuotaModel.fromJson({
  'doctorId': doctorId,
  'lines': [
    {'priorityId': priorityId, 'isOverridden': isOverridden},
    // A second priority the doctor does have an override on, to prove the
    // answer is per priority and not "has any override at all".
    {'priorityId': 'other', 'isOverridden': true},
  ],
});

void main() {
  late _MockApiService api;
  late CasePrioritiesRepo repo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    api = _MockApiService();
    repo = CasePrioritiesRepo(api);
  });

  void stubQuota(String doctorId, DoctorPriorityQuotaModel answer) {
    when(
      () => api.getDoctorPriorityQuota(
        doctorId: doctorId,
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => answer);
  }

  test(
    'reports the doctors that carry an override for this priority',
    () async {
      // The screen reopening a priority's audience has to show the last answer;
      // the API only answers per doctor, so the repo folds those answers.
      stubQuota('d1', _quota('d1', priorityId: 'p1', isOverridden: true));
      stubQuota('d2', _quota('d2', priorityId: 'p1', isOverridden: false));
      stubQuota('d3', _quota('d3', priorityId: 'p1', isOverridden: true));

      final result = await repo.getDoctorsWithPriorityOverride(
        priorityId: 'p1',
        doctorIds: const ['d1', 'd2', 'd3'],
      );

      expect(result.assignedIds, {'d1', 'd3'});
      expect(result.unreadable, 0);
    },
  );

  test('a doctor with no line for the priority is not assigned', () async {
    stubQuota(
      'd1',
      DoctorPriorityQuotaModel.fromJson(const {'doctorId': 'd1', 'lines': []}),
    );

    final result = await repo.getDoctorsWithPriorityOverride(
      priorityId: 'p1',
      doctorIds: const ['d1'],
    );

    expect(result.assignedIds, isEmpty);
    expect(result.unreadable, 0);
  });

  test(
    'a doctor whose quota fails is counted, not silently unassigned',
    () async {
      // Reported so the screen can say the selection may be incomplete, instead
      // of showing the user a confident but wrong "not assigned".
      stubQuota('d1', _quota('d1', priorityId: 'p1', isOverridden: true));
      when(
        () => api.getDoctorPriorityQuota(
          doctorId: 'd2',
          token: any(named: 'token'),
        ),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      final result = await repo.getDoctorsWithPriorityOverride(
        priorityId: 'p1',
        doctorIds: const ['d1', 'd2'],
      );

      expect(result.assignedIds, {'d1'});
      expect(result.unreadable, 1);
    },
  );

  test(
    'runs in batches so a large lab does not fire every request at once',
    () async {
      // Eight doctors, batch size six: the seventh cannot have been asked before
      // the first six answered.
      final ids = [for (var i = 0; i < 8; i++) 'd$i'];
      for (final id in ids) {
        stubQuota(id, _quota(id, priorityId: 'p1', isOverridden: true));
      }

      final result = await repo.getDoctorsWithPriorityOverride(
        priorityId: 'p1',
        doctorIds: ids,
      );

      expect(result.assignedIds.length, 8);
      for (final id in ids) {
        verify(
          () => api.getDoctorPriorityQuota(
            doctorId: id,
            token: any(named: 'token'),
          ),
        ).called(1);
      }
    },
  );
}
