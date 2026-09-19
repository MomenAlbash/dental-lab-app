import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/departments/data/models/department_model.dart';
import 'package:dental_lab_app/features/departments/data/models/save_department_request_model.dart';
import 'package:dental_lab_app/features/departments/data/repos/departments_repo.dart';
import 'package:dental_lab_app/features/departments/logic/departments/departments_cubit.dart';
import 'package:dental_lab_app/features/departments/logic/departments/departments_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDepartmentsRepo extends Mock implements DepartmentsRepo {}

DepartmentModel department(
  String id,
  String name, {
  List<String> stageIds = const [],
}) => DepartmentModel.fromJson({
  'id': id,
  'nameAr': name,
  'stages': [
    for (final stageId in stageIds) {'id': stageId},
  ],
});

void main() {
  late MockDepartmentsRepo repo;
  late DepartmentsCubit cubit;

  setUpAll(() {
    registerFallbackValue(const SaveDepartmentRequestModel(name: 'x'));
  });

  setUp(() {
    repo = MockDepartmentsRepo();
    cubit = DepartmentsCubit(repo);
  });

  tearDown(() => cubit.close());

  void stubLoad(List<DepartmentModel> departments) {
    when(
      () => repo.getDepartments(includeInactive: any(named: 'includeInactive')),
    ).thenAnswer((_) async => right(departments));
  }

  group('stageOwners', () {
    test('names the department already holding each stage', () async {
      stubLoad([
        department('d1', 'التشطيب', stageIds: ['s1', 's2']),
        department('d2', 'الصب', stageIds: ['s3']),
      ]);
      await cubit.load();

      expect(cubit.stageOwners(), {
        's1': 'التشطيب',
        's2': 'التشطيب',
        's3': 'الصب',
      });
    });

    test('excludes the department being edited', () {
      // Its own stages are already ticked; listing them as taken would make a
      // department unable to keep the stages it has.
      stubLoad([
        department('d1', 'التشطيب', stageIds: ['s1']),
      ]);

      return cubit.load().then((_) {
        expect(cubit.stageOwners(exclude: 'd1'), isEmpty);
      });
    });

    test('is empty before anything is loaded', () {
      expect(cubit.stageOwners(), isEmpty);
    });
  });

  group('setStages', () {
    test('resends the name and staff so linking does not blank them', () async {
      stubLoad([
        DepartmentModel.fromJson(const {
          'id': 'd1',
          'name': 'Finishing',
          'nameAr': 'التشطيب',
          'description': 'وصف',
          'employees': [
            {'id': 'row-1', 'employeeId': 'e1'},
          ],
        }),
      ]);
      when(
        () => repo.updateDepartment(
          id: any(named: 'id'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => right(department('d1', 'التشطيب')));

      await cubit.load();
      final loaded = (cubit.state as DepartmentsLoaded).departments.single;
      await cubit.setStages(department: loaded, stageIds: ['s1']);

      final body = verify(
        () => repo.updateDepartment(
          id: 'd1',
          body: captureAny(named: 'body'),
        ),
      ).captured.single;
      final json = (body as dynamic).toJson() as Map<String, dynamic>;

      expect(json['name'], 'Finishing');
      expect(json['description'], 'وصف');
      // The membership row id must never be sent as the employee id.
      expect(json['employeeIds'], ['e1']);
      expect(json['stageIds'], ['s1']);
    });
  });

  test('a failed write reports the reason and keeps the list', () async {
    stubLoad([department('d1', 'التشطيب')]);
    when(
      () => repo.updateDepartment(
        id: any(named: 'id'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('المرحلة مرتبطة بقسم آخر')));

    await cubit.load();
    final loaded = (cubit.state as DepartmentsLoaded).departments.single;

    final states = <DepartmentsState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.setStages(department: loaded, stageIds: ['s1']);
    // Emits reach listeners asynchronously, so drain the queue before reading
    // what the screen would have seen.
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(
      states.whereType<DepartmentsMessage>().single.message,
      'المرحلة مرتبطة بقسم آخر',
    );
    // The list comes straight back — a failed write must not replace a working
    // screen with an error page.
    expect(states.last, isA<DepartmentsLoaded>());
  });
}
