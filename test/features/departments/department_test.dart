import 'package:dental_lab_app/features/departments/data/models/department_model.dart';
import 'package:dental_lab_app/features/departments/data/models/save_department_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DepartmentModel', () {
    test('parses the stages it owns with their restoration type', () {
      final department = DepartmentModel.fromJson(const {
        'id': 'd1',
        'nameAr': 'التشطيب',
        'name': 'Finishing',
        'parentId': 'd0',
        'parentName': 'الإنتاج',
        'activeWorkloadCount': 7,
        'stages': [
          {
            'id': 's1',
            'name': 'التلميع',
            'order': 2,
            'restorationTypeNameAr': 'زيركون',
            'activeCount': 3,
          },
        ],
        'employees': [
          {'id': 'm1', 'employeeId': 'e1', 'employeeName': 'سارة'},
        ],
      });

      expect(department.displayName, 'التشطيب');
      expect(department.parentName, 'الإنتاج');
      expect(department.activeWorkloadCount, 7);
      expect(department.stages.single.restorationTypeLabel, 'زيركون');
      expect(department.stages.single.activeCount, 3);
      expect(department.employees.single.employeeId, 'e1');
    });

    test('a department with no stages parses rather than throwing', () {
      // The stage list is sorted on parse; a `const []` default would make
      // every stage-less department a runtime error.
      final department = DepartmentModel.fromJson(const {'id': 'd1'});

      expect(department.stages, isEmpty);
      expect(department.isUnwired, isTrue);
    });

    test('stages come back in route order', () {
      final department = DepartmentModel.fromJson(const {
        'id': 'd1',
        'stages': [
          {'id': 'b', 'order': 5},
          {'id': 'a', 'order': 1},
        ],
      });

      expect(department.stages.map((s) => s.id), ['a', 'b']);
    });

    test('the membership row id is not the employee id', () {
      // Saving takes employeeId; sending the row id would link nobody.
      final department = DepartmentModel.fromJson(const {
        'id': 'd1',
        'employees': [
          {'id': 'row-1', 'employeeId': 'emp-1'},
        ],
      });

      expect(department.employees.single.id, 'row-1');
      expect(department.employees.single.employeeId, 'emp-1');
    });
  });

  group('SaveDepartmentRequestModel', () {
    test('sends an empty stage list so the last link can be removed', () {
      final json = const SaveDepartmentRequestModel(
        name: 'Finishing',
        stageIds: [],
      ).toJson();

      expect(json.containsKey('stageIds'), isTrue);
      expect(json['stageIds'], isEmpty);
    });

    test('omits the lists entirely when they are untouched', () {
      // A rename must not empty the department of its stages and staff.
      final json = const SaveDepartmentRequestModel(name: 'Finishing').toJson();

      expect(json.containsKey('stageIds'), isFalse);
      expect(json.containsKey('employeeIds'), isFalse);
      expect(json['name'], 'Finishing');
    });

    test('refuses a nameless department', () {
      expect(
        () => SaveDepartmentRequestModel(name: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('refuses a name past the API cap', () {
      expect(
        () => SaveDepartmentRequestModel(name: 'x' * 151),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
