import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/doctor_quota/doctor_quota_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/doctor_quota/doctor_quota_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCasePrioritiesRepo extends Mock implements CasePrioritiesRepo {}

DoctorPriorityQuotaModel quota({int free = 5, bool overridden = true}) =>
    DoctorPriorityQuotaModel.fromJson({
      'doctorId': 'd1',
      'year': 2026,
      'month': 8,
      'lines': [
        {
          'priorityId': 'p1',
          'priorityNameAr': 'سريع جداً',
          'freePerMonth': free,
          'usedThisMonth': 2,
          'remainingFree': free - 2,
          'isOverridden': overridden,
        },
        {
          'priorityId': 'p2',
          'priorityNameAr': 'عادي',
          'isUnlimited': true,
          'isOverridden': false,
        },
      ],
    });

void main() {
  setUpAll(() {
    registerFallbackValue(
      const SetPriorityAllowanceRequestModel(priorityId: 'p1'),
    );
  });

  late MockCasePrioritiesRepo repo;
  late DoctorQuotaCubit cubit;

  setUp(() {
    repo = MockCasePrioritiesRepo();
    cubit = DoctorQuotaCubit(repo);
  });

  tearDown(() => cubit.close());

  test('loads every priority for the doctor, overridden or not', () async {
    when(
      () => repo.getDoctorPriorityQuota(any()),
    ).thenAnswer((_) async => right(quota()));

    await cubit.load('d1');

    final lines = (cubit.state as DoctorQuotaLoaded).quota.lines;
    expect(lines, hasLength(2));
    // Two doctors can hold different numbers for the same priority; the flag
    // is what says this one is not simply the lab default.
    expect(lines.first.isOverridden, isTrue);
    expect(lines.first.freePerMonth, 5);
    expect(lines.last.isOverridden, isFalse);
  });

  test('a line can be found by its priority', () async {
    when(
      () => repo.getDoctorPriorityQuota(any()),
    ).thenAnswer((_) async => right(quota(free: 6)));

    await cubit.load('d1');
    final loaded = (cubit.state as DoctorQuotaLoaded).quota;

    expect(loaded.lineFor('p1')?.freePerMonth, 6);
    expect(loaded.lineFor('nope'), isNull);
  });

  test('setting an allowance sends it for this doctor only', () async {
    when(
      () => repo.getDoctorPriorityQuota(any()),
    ).thenAnswer((_) async => right(quota()));
    when(
      () => repo.setDoctorPriorityAllowance(
        doctorId: any(named: 'doctorId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => right(quota(free: 6)));

    await cubit.load('d1');
    await cubit.setAllowance(
      priorityId: 'p1',
      freePerMonth: 6,
      surchargeAmount: null,
    );

    final body =
        verify(
              () => repo.setDoctorPriorityAllowance(
                doctorId: 'd1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as SetPriorityAllowanceRequestModel;

    expect(body.priorityId, 'p1');
    expect(body.freePerMonth, 6);
    expect(
      (cubit.state as DoctorQuotaLoaded).quota.lineFor('p1')?.freePerMonth,
      6,
    );
  });

  test('a failed write reports the reason and keeps the rows', () async {
    when(
      () => repo.getDoctorPriorityQuota(any()),
    ).thenAnswer((_) async => right(quota()));
    when(
      () => repo.setDoctorPriorityAllowance(
        doctorId: any(named: 'doctorId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('مرفوض')));

    await cubit.load('d1');

    final states = <DoctorQuotaState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.setAllowance(
      priorityId: 'p1',
      freePerMonth: 6,
      surchargeAmount: null,
    );
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(states.whereType<DoctorQuotaMessage>().single.message, 'مرفوض');
    expect(states.last, isA<DoctorQuotaLoaded>());
  });
}
