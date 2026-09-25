import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/stage_pay/data/models/stage_pay_models.dart';
import 'package:dental_lab_app/features/stage_pay/data/repos/stage_pay_repo.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_earnings/stage_earnings_cubit.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_earnings/stage_earnings_state.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_rates/stage_rates_cubit.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_rates/stage_rates_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStagePayRepo extends Mock implements StagePayRepo {}

class _MockEmployeesRepo extends Mock implements EmployeesRepo {}

StagePayRestorationTypeModel _type(
  String id, {
  required String lab,
  required List<StagePayRateModel> stages,
}) => StagePayRestorationTypeModel(
  restorationTypeId: id,
  laboratoryId: lab,
  stages: stages,
);

const _design = StagePayRateModel(rootStageId: 's1', amount: 100);
const _milling = StagePayRateModel(rootStageId: 's2');
const _otherLabStage = StagePayRateModel(rootStageId: 's3', amount: 50);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const SaveStagePayRatesRequestModel(laboratoryId: '', rates: {}),
    );
    registerFallbackValue(DateTime(2026));
  });

  group('StagePayRestorationTypeModel', () {
    test('orders stages by route order however they arrived', () {
      final type = StagePayRestorationTypeModel.fromJson({
        'restorationTypeId': 't1',
        'laboratoryId': 'l1',
        'stages': [
          {'rootStageId': 'b', 'order': 2, 'amount': 0, 'basis': 2},
          {'rootStageId': 'a', 'order': 1, 'amount': 80, 'basis': 1},
        ],
      });

      expect(type.stages.map((s) => s.rootStageId), ['a', 'b']);
      expect(type.stages.first.basis, StagePayBasis.perTooth);
      expect(type.pricedCount, 1);
    });
  });

  group('SaveStagePayRatesRequestModel', () {
    test('sends each price under its root stage id', () {
      final json = const SaveStagePayRatesRequestModel(
        laboratoryId: 'l1',
        rates: {
          's1': StagePayRateDraft(amount: 90, basis: StagePayBasis.perTooth),
        },
      ).toJson();

      expect(json['laboratoryId'], 'l1');
      expect(json['rates'], [
        {'rootStageId': 's1', 'amount': 90.0, 'basis': 1},
      ]);
    });
  });

  group('EmployeeStageEarningModel.totalOf', () {
    test('leaves voided rows out of the total', () {
      const rows = [
        EmployeeStageEarningModel(id: '1', employeeId: 'e', amount: 100),
        EmployeeStageEarningModel(
          id: '2',
          employeeId: 'e',
          amount: 40,
          isVoided: true,
        ),
      ];

      expect(EmployeeStageEarningModel.totalOf(rows), 100);
    });
  });

  group('StageRatesCubit', () {
    late _MockStagePayRepo repo;
    late StageRatesCubit cubit;

    setUp(() {
      repo = _MockStagePayRepo();
      when(() => repo.getRates()).thenAnswer(
        (_) async => Right<Failure, List<StagePayRestorationTypeModel>>([
          _type('t1', lab: 'l1', stages: [_design, _milling]),
          _type('t2', lab: 'l2', stages: [_otherLabStage]),
        ]),
      );
      when(
        () => repo.saveRates(any()),
      ).thenAnswer((_) async => const Right<Failure, void>(null));
      cubit = StageRatesCubit(repo);
    });

    tearDown(() => cubit.close());

    test('an edit becomes a draft the screen shows', () async {
      await cubit.load();

      cubit.edit(_milling, amount: 60);

      final state = cubit.state as StageRatesLoaded;
      expect(state.drafts.keys, ['s2']);
      expect(state.priceOf(_milling).amount, 60);
    });

    test('editing back to the saved price is no change at all', () async {
      await cubit.load();

      cubit.edit(_design, amount: 120);
      cubit.edit(_design, amount: 100);

      expect((cubit.state as StageRatesLoaded).hasChanges, isFalse);
    });

    test('saves one request per laboratory', () async {
      await cubit.load();
      cubit.edit(_milling, amount: 60);
      cubit.edit(_otherLabStage, basis: StagePayBasis.perTooth);

      await cubit.save();

      final requests = verify(
        () => repo.saveRates(captureAny()),
      ).captured.cast<SaveStagePayRatesRequestModel>();
      expect(
        {for (final r in requests) r.laboratoryId: r.rates.keys.toList()},
        {
          'l1': ['s2'],
          'l2': ['s3'],
        },
      );
    });

    test('a failed save keeps what was typed', () async {
      when(
        () => repo.saveRates(any()),
      ).thenAnswer((_) async => Left<Failure, void>(ServerFailure('refused')));
      await cubit.load();
      cubit.edit(_milling, amount: 60);

      await cubit.save();

      expect((cubit.state as StageRatesLoaded).drafts.keys, ['s2']);
    });
  });

  group('StageEarningsCubit', () {
    late _MockStagePayRepo repo;
    late _MockEmployeesRepo employeesRepo;
    late StageEarningsCubit cubit;

    setUp(() {
      repo = _MockStagePayRepo();
      employeesRepo = _MockEmployeesRepo();
      when(
        () => repo.getEarnings(
          from: any(named: 'from'),
          to: any(named: 'to'),
          employeeId: any(named: 'employeeId'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, List<EmployeeStageEarningModel>>([]),
      );
      when(
        () => employeesRepo.getEmployees(),
      ).thenAnswer((_) async => const Right<Failure, List<EmployeeModel>>([]));
      cubit = StageEarningsCubit(
        repo,
        employeesRepo,
        today: DateTime(2026, 9, 25, 14),
      );
    });

    tearDown(() => cubit.close());

    test('defaults to this month so far', () async {
      await cubit.init();

      verify(
        () => repo.getEarnings(
          from: DateTime(2026, 9),
          to: DateTime(2026, 9, 25),
          employeeId: null,
        ),
      ).called(1);
    });

    test('narrows to one employee', () async {
      await cubit.init();

      await cubit.setEmployee('e1');

      verify(
        () => repo.getEarnings(
          from: any(named: 'from'),
          to: any(named: 'to'),
          employeeId: 'e1',
        ),
      ).called(1);
    });

    test('no employee list still loads the earnings', () async {
      when(() => employeesRepo.getEmployees()).thenAnswer(
        (_) async => Left<Failure, List<EmployeeModel>>(ServerFailure('down')),
      );

      await cubit.init();

      expect(cubit.state, isA<StageEarningsLoaded>());
    });
  });
}
