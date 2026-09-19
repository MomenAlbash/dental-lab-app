import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/store_reports/data/models/monthly_feasibility_model.dart';
import 'package:dental_lab_app/features/store_reports/data/repos/store_reports_repo.dart';
import 'package:dental_lab_app/features/store_reports/logic/feasibility/feasibility_cubit.dart';
import 'package:dental_lab_app/features/store_reports/logic/feasibility/feasibility_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStoreReportsRepo extends Mock implements StoreReportsRepo {}

void main() {
  late _MockStoreReportsRepo repo;
  late FeasibilityCubit cubit;

  setUp(() {
    repo = _MockStoreReportsRepo();
    cubit = FeasibilityCubit(repo);
  });

  tearDown(() => cubit.close());

  test('loads with the default 12-month window', () async {
    when(
      () => repo.getStoreFeasibility(
        months: any(named: 'months'),
        laboratoryIds: any(named: 'laboratoryIds'),
      ),
    ).thenAnswer((_) async => right(const MonthlyFeasibilityModel()));

    await cubit.load();

    final loaded = cubit.state as FeasibilityLoaded;
    expect(loaded.months, 12);
    verify(
      () => repo.getStoreFeasibility(
        months: 12,
        laboratoryIds: any(named: 'laboratoryIds'),
      ),
    ).called(1);
  });

  test('a chosen window is passed through and remembered', () async {
    when(
      () => repo.getStoreFeasibility(
        months: any(named: 'months'),
        laboratoryIds: any(named: 'laboratoryIds'),
      ),
    ).thenAnswer((_) async => right(const MonthlyFeasibilityModel()));

    await cubit.load(months: 6);

    final loaded = cubit.state as FeasibilityLoaded;
    expect(loaded.months, 6);
    verify(
      () => repo.getStoreFeasibility(
        months: 6,
        laboratoryIds: any(named: 'laboratoryIds'),
      ),
    ).called(1);
  });

  test('a fetch failure reports the reason', () async {
    when(
      () => repo.getStoreFeasibility(
        months: any(named: 'months'),
        laboratoryIds: any(named: 'laboratoryIds'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

    await cubit.load();

    expect(cubit.state, isA<FeasibilityError>());
    expect((cubit.state as FeasibilityError).message, 'لا يوجد اتصال');
  });
}
