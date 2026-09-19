import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/features/departments/data/models/department_user_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_doctor_scope_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionName', () {
    test('15 is Doctor and 16 is RestorationType', () {
      // The backend inserted `Doctor` at 15 and pushed `RestorationType` to
      // 16. This client had 15 mapped to RestorationType, which silently read
      // every "may manage doctors" grant as "may manage the catalogue".
      expect(PermissionName.fromValue(15), PermissionName.doctor);
      expect(PermissionName.fromValue(16), PermissionName.restorationType);
    });

    test('carries the agent module it never gates on', () {
      // A value this app does not act on is still one a role may hold —
      // dropping it would round-trip that grant through the cache missing.
      expect(
        PermissionName.fromValue(300),
        PermissionName.agentRepresentatives,
      );
    });

    test('every clinic module has a label for the role editor', () {
      for (final permission in PermissionName.values) {
        if (permission.value > 16) continue;
        expect(
          permission.label,
          isNotNull,
          reason: '${permission.name} has no Arabic label',
        );
      }
    });

    test('an unknown value is dropped rather than guessed at', () {
      expect(PermissionName.fromValue(999), isNull);
      expect(PermissionName.fromValue(null), isNull);
    });
  });

  group('EmployeeModel', () {
    test('a terminated employee stays a real record', () {
      // Terminating is not deleting: their attendance, payslips and case
      // history are all still attached to them.
      final employee = EmployeeModel.fromJson({
        'id': 'e1',
        'firstName': 'أحمد',
        'isActive': false,
        'terminationDate': '2026-03-01T00:00:00Z',
      });

      expect(employee.isActive, isFalse);
      expect(employee.terminationDate, isNotNull);
      expect(employee.fullName, 'أحمد');
    });

    test('no login is a different state from a suspended one', () {
      // Null userIsActive means there is no login at all; false means one
      // exists but cannot sign in — and only one of those is somebody's
      // mistake.
      final noLogin = EmployeeModel.fromJson({'id': 'e1'});
      final suspended = EmployeeModel.fromJson({
        'id': 'e2',
        'userId': 'u1',
        'username': 'ahmad',
        'userIsActive': false,
      });

      expect(noLogin.hasLogin, isFalse);
      expect(noLogin.userIsActive, isNull);
      expect(suspended.hasLogin, isTrue);
      expect(suspended.userIsActive, isFalse);
    });

    test('defaults to employed when the server says nothing', () {
      final employee = EmployeeModel.fromJson({'id': 'e1'});
      expect(employee.isActive, isTrue);
      expect(employee.isRepresentative, isFalse);
    });
  });

  group('EmployeeNoteModel', () {
    test('carries who wrote it and when', () {
      // A personnel note nobody can trace to an author is not a record.
      final note = EmployeeNoteModel.fromJson({
        'id': 'n1',
        'employeeId': 'e1',
        'authorName': 'سامر',
        'note': 'تأخر متكرر',
        'createdAt': '2026-03-01T09:00:00Z',
      });

      expect(note.authorName, 'سامر');
      expect(note.createdAt, isNotNull);
    });
  });

  group('UserDoctorScopeSummaryModel', () {
    test('an empty doctor list means unrestricted, not "no doctors"', () {
      // Getting this backwards would hide every doctor from the people who
      // can currently see them all.
      final row = UserDoctorScopeSummaryModel.fromJson({
        'userId': 'u1',
        'username': 'ahmad',
        'doctorIds': <String>[],
      });

      expect(row.isUnrestricted, isTrue);
    });

    test('an admin row is listed but never editable', () {
      // Admins see every doctor by design — offering a scope editor would be
      // offering a setting the server ignores.
      final admin = UserDoctorScopeSummaryModel.fromJson({
        'userId': 'u1',
        'isAdmin': true,
        'doctorIds': ['d1'],
      });

      expect(admin.isEditable, isFalse);
    });

    test('falls back to the username when there is no display name', () {
      final row = UserDoctorScopeSummaryModel.fromJson({
        'userId': 'u1',
        'username': 'ahmad',
      });

      expect(row.label, 'ahmad');
    });
  });

  group('DepartmentUserModel', () {
    test('keeps the login apart from the person', () {
      // userId is what a stage assignment stores; employeeId is only there to
      // link to their page.
      final member = DepartmentUserModel.fromJson({
        'userId': 'u1',
        'employeeId': 'e1',
        'name': 'أحمد',
        'isSupervisor': true,
      });

      expect(member.userId, 'u1');
      expect(member.employeeId, 'e1');
      expect(member.isSupervisor, isTrue);
    });

    test('a suspended login stays listed', () {
      // It is the explanation for why somebody the lab expects on a stage is
      // not picking work up.
      final member = DepartmentUserModel.fromJson({
        'userId': 'u1',
        'employeeId': 'e1',
        'username': 'ahmad',
        'isActive': false,
      });

      expect(member.isActive, isFalse);
      expect(member.displayName, 'ahmad');
    });
  });
}
