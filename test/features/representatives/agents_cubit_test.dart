import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/representatives/logic/agents_cubit.dart';
import 'package:dental_lab_app/features/users/data/models/user_filters_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEmployeesRepo extends Mock implements EmployeesRepo {}

void main() {
  group('AgentsCubit', () {
    late _MockEmployeesRepo repo;
    setUp(() => repo = _MockEmployeesRepo());

    test('emits the agents on success', () async {
      when(() => repo.getAgents()).thenAnswer(
        (_) async => right([
          EmployeeModel.fromJson({'id': 'a1'}),
        ]),
      );
      final cubit = AgentsCubit(repo);
      await cubit.getAgents();
      expect(
        cubit.state,
        isA<AgentsLoaded>().having((s) => s.agents.single.id, 'id', 'a1'),
      );
    });

    test('emits the failure message on error', () async {
      when(
        () => repo.getAgents(),
      ).thenAnswer((_) async => left(ServerFailure('boom')));
      final cubit = AgentsCubit(repo);
      await cubit.getAgents();
      expect(
        cubit.state,
        isA<AgentsError>().having((s) => s.message, 'message', 'boom'),
      );
    });
  });

  group('UserFiltersModel.types', () {
    test('representatives only asks for employee accounts', () {
      const filters = UserFiltersModel(representativesOnly: true);
      expect(filters.types, [UserType.employee.apiValue]);
      expect(filters.isEmpty, isFalse);
    });

    test('no type sends no types', () {
      expect(const UserFiltersModel().types, isNull);
    });
  });
}
