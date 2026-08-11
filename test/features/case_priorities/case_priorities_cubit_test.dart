import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCasePrioritiesRepo extends Mock implements CasePrioritiesRepo {}

const _priorities = [
  CasePriorityModel(id: 'p1', nameAr: 'عادية', isDefault: true),
  CasePriorityModel(id: 'p2', nameAr: 'عاجلة'),
];

void main() {
  late _MockCasePrioritiesRepo repo;
  late CasePrioritiesCubit cubit;

  setUp(() {
    repo = _MockCasePrioritiesRepo();
    cubit = CasePrioritiesCubit(repo);
  });

  tearDown(() => cubit.close());

  test('emits loading then loaded on a successful fetch', () async {
    when(
      () => repo.getCasePriorities(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => right(_priorities));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([isA<CasePrioritiesLoading>(), isA<CasePrioritiesLoaded>()]),
    );

    await cubit.getCasePriorities();
    await expectation;

    expect((cubit.state as CasePrioritiesLoaded).priorities, _priorities);
  });

  test('emits the failure message when the fetch fails', () async {
    when(
      () => repo.getCasePriorities(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

    await cubit.getCasePriorities();

    expect(cubit.state, isA<CasePrioritiesError>());
    expect((cubit.state as CasePrioritiesError).message, 'لا يوجد اتصال');
  });

  test('passes includeInactive through to the repo', () async {
    when(
      () => repo.getCasePriorities(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => right(_priorities));

    await cubit.getCasePriorities(includeInactive: true);

    verify(() => repo.getCasePriorities(includeInactive: true)).called(1);
  });

  test('a delete refetches with the same includeInactive scope', () async {
    when(
      () => repo.getCasePriorities(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer((_) async => right(_priorities));
    when(
      () => repo.deleteCasePriority(any()),
    ).thenAnswer((_) async => right(null));

    // The management screen loads inactive rows too; the refetch after a
    // delete must not silently drop them.
    await cubit.getCasePriorities(includeInactive: true);
    await cubit.deleteCasePriority('p2');

    verify(() => repo.getCasePriorities(includeInactive: true)).called(2);
  });

  test('a failed delete reports and does not refetch', () async {
    when(
      () => repo.deleteCasePriority(any()),
    ).thenAnswer((_) async => left(ServerFailure('الأولوية مستخدمة')));

    await cubit.deleteCasePriority('p2');

    expect(cubit.state, isA<CasePriorityDeleteError>());
    verifyNever(
      () => repo.getCasePriorities(
        includeInactive: any(named: 'includeInactive'),
      ),
    );
  });
}
