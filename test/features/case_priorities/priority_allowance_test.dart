import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/priority_allowance/priority_allowance_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/priority_allowance/priority_allowance_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCasePrioritiesRepo extends Mock implements CasePrioritiesRepo {}

final quota = DoctorPriorityQuotaModel.fromJson(const {'doctorId': 'd1'});

List<({String id, String name})> doctors(int count) => [
  for (var i = 0; i < count; i++) (id: 'd$i', name: 'طبيب $i'),
];

void main() {
  group('SetPriorityAllowanceRequestModel', () {
    test('null is a reset, not zero', () {
      // Zero means "no free cases at all" — a decision. Null means "no special
      // arrangement", which puts the doctor back on the lab default. Sending
      // one for the other silently changes what a doctor is owed.
      const reset = SetPriorityAllowanceRequestModel(priorityId: 'p1');
      const none = SetPriorityAllowanceRequestModel(
        priorityId: 'p1',
        freePerMonth: 0,
      );

      expect(reset.isReset, isTrue);
      expect(none.isReset, isFalse);
      expect(reset.toJson()['freePerMonth'], isNull);
      expect(none.toJson()['freePerMonth'], 0);
    });

    test('always sends both keys so null reaches the server', () {
      // Omitting a key is how "unchanged" is usually expressed; this endpoint
      // has no such mode, so the nulls have to be on the wire.
      final json = const SetPriorityAllowanceRequestModel(
        priorityId: 'p1',
      ).toJson();

      expect(json.containsKey('freePerMonth'), isTrue);
      expect(json.containsKey('surchargeAmount'), isTrue);
    });

    test('refuses a negative allowance', () {
      expect(
        () => SetPriorityAllowanceRequestModel(
          priorityId: 'p1',
          freePerMonth: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('PriorityAllowanceCubit', () {
    late MockCasePrioritiesRepo repo;
    late PriorityAllowanceCubit cubit;

    setUpAll(() {
      registerFallbackValue(
        const SetPriorityAllowanceRequestModel(priorityId: 'p1'),
      );
    });

    setUp(() {
      repo = MockCasePrioritiesRepo();
      cubit = PriorityAllowanceCubit(repo);
    });

    tearDown(() => cubit.close());

    void stubAll({Either<Failure, DoctorPriorityQuotaModel>? answer}) {
      when(
        () => repo.setDoctorPriorityAllowance(
          doctorId: any(named: 'doctorId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => answer ?? right(quota));
    }

    test('writes once per doctor — there is no bulk endpoint', () async {
      stubAll();

      await cubit.apply(
        priorityId: 'p1',
        doctors: doctors(3),
        freePerMonth: 5,
        surchargeAmount: null,
      );

      verify(
        () => repo.setDoctorPriorityAllowance(
          doctorId: any(named: 'doctorId'),
          body: any(named: 'body'),
        ),
      ).called(3);
      expect((cubit.state as PriorityAllowanceDone).succeeded, 3);
    });

    test('reports progress as it goes', () async {
      // A count, not a spinner: a city's worth of writes takes long enough
      // that "still running" and "hung" have to look different.
      stubAll();

      final seen = <String>[];
      final subscription = cubit.stream.listen((state) {
        if (state is PriorityAllowanceApplying) {
          seen.add('${state.done}/${state.total}');
        }
      });

      await cubit.apply(
        priorityId: 'p1',
        doctors: doctors(2),
        freePerMonth: 5,
        surchargeAmount: null,
      );
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(seen, ['0/2', '1/2', '2/2']);
    });

    test('a failure does not abort the rest of the run', () async {
      // Stopping at the first would leave the lab unable to tell who was done.
      var call = 0;
      when(
        () => repo.setDoctorPriorityAllowance(
          doctorId: any(named: 'doctorId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async {
        call++;
        return call == 2 ? left(ServerFailure('رفض')) : right(quota);
      });

      await cubit.apply(
        priorityId: 'p1',
        doctors: doctors(3),
        freePerMonth: 5,
        surchargeAmount: null,
      );

      final done = cubit.state as PriorityAllowanceDone;
      expect(done.succeeded, 2);
      expect(done.failed, ['طبيب 1']);
      expect(done.firstError, 'رفض');
      expect(done.isClean, isFalse);
    });

    test('reset sends nulls rather than zeros', () async {
      stubAll();

      await cubit.reset(priorityId: 'p1', doctors: doctors(1));

      final body =
          verify(
                () => repo.setDoctorPriorityAllowance(
                  doctorId: 'd0',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as SetPriorityAllowanceRequestModel;

      expect(body.isReset, isTrue);
    });

    test('an empty audience does nothing at all', () async {
      stubAll();

      await cubit.apply(
        priorityId: 'p1',
        doctors: const [],
        freePerMonth: 5,
        surchargeAmount: null,
      );

      verifyNever(
        () => repo.setDoctorPriorityAllowance(
          doctorId: any(named: 'doctorId'),
          body: any(named: 'body'),
        ),
      );
      expect(cubit.state, isA<PriorityAllowanceIdle>());
    });
  });

  group('PriorityQuotaLineModel', () {
    test('distinguishes a doctor override from the lab default', () {
      // The same numbers mean different things depending on where they came
      // from, so the flag is the whole point of the line.
      final line = PriorityQuotaLineModel.fromJson(const {
        'priorityId': 'p1',
        'priorityNameAr': 'سريع جداً',
        'freePerMonth': 5,
        'usedThisMonth': 2,
        'remainingFree': 3,
        'isOverridden': true,
      });

      expect(line.priorityLabel, 'سريع جداً');
      expect(line.freePerMonth, 5);
      expect(line.remainingFree, 3);
      expect(line.isOverridden, isTrue);
    });
  });
}
