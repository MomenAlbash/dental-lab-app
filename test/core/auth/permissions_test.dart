import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

/// A `ClinicUserDto` with the given role grants.
Map<String, dynamic> userJson({
  bool isAdmin = false,
  List<Map<String, dynamic>> permissions = const [],
}) => {
  'id': 'u1',
  'isAdmin': isAdmin,
  'role': {'id': 'r1', 'permissions': permissions},
};

void main() {
  group('PermissionType.satisfies', () {
    test('full access covers a read requirement', () {
      expect(PermissionType.fullAccess.satisfies(PermissionType.read), isTrue);
    });

    test('read does not cover a full-access requirement', () {
      expect(PermissionType.read.satisfies(PermissionType.fullAccess), isFalse);
    });
  });

  group('Permissions.fromUserJson', () {
    test('reads a granted module at its level', () {
      final permissions = Permissions.fromUserJson(
        userJson(
          permissions: [
            {'name': 1, 'type': 0}, // Cases: Read
          ],
        ),
      );

      expect(permissions.canRead(PermissionName.cases), isTrue);
      expect(permissions.canEdit(PermissionName.cases), isFalse);
    });

    test('denies a module that was never granted', () {
      final permissions = Permissions.fromUserJson(
        userJson(
          permissions: [
            {'name': 1, 'type': 1},
          ],
        ),
      );

      expect(permissions.canRead(PermissionName.roles), isFalse);
    });

    test('keeps the strongest grant when a module appears twice', () {
      final permissions = Permissions.fromUserJson(
        userJson(
          permissions: [
            {'name': 7, 'type': 1}, // Users: FullAccess
            {'name': 7, 'type': 0}, // Users: Read, arriving second
          ],
        ),
      );

      expect(permissions.canEdit(PermissionName.users), isTrue);
    });

    test('drops permission ids the app does not know', () {
      final permissions = Permissions.fromUserJson(
        userJson(
          permissions: [
            {'name': 99, 'type': 1},
          ],
        ),
      );

      expect(permissions.granted, isEmpty);
    });

    test('an admin passes every check without any grants', () {
      final permissions = Permissions.fromUserJson(userJson(isAdmin: true));

      expect(permissions.granted, isEmpty);
      expect(permissions.canEdit(PermissionName.roles), isTrue);
      expect(permissions.canRead(PermissionName.finance), isTrue);
    });

    test('a user with no role is denied everything', () {
      final permissions = Permissions.fromUserJson(const {
        'id': 'u1',
        'isAdmin': false,
      });

      for (final name in PermissionName.values) {
        expect(permissions.canRead(name), isFalse, reason: '$name');
      }
    });
  });

  test('Permissions.empty denies everything', () {
    for (final name in PermissionName.values) {
      expect(Permissions.empty.canRead(name), isFalse, reason: '$name');
    }
  });

  group('cache round-trip', () {
    test('survives being written and read back', () {
      final original = Permissions.fromUserJson(
        userJson(
          permissions: [
            {'name': 1, 'type': 1},
            {'name': 8, 'type': 0},
          ],
        ),
      );

      final restored = Permissions.fromCacheJson(original.toJson());

      expect(restored.canEdit(PermissionName.cases), isTrue);
      expect(restored.canRead(PermissionName.roles), isTrue);
      expect(restored.canEdit(PermissionName.roles), isFalse);
      expect(restored.canRead(PermissionName.finance), isFalse);
    });

    test('carries the admin flag', () {
      final original = Permissions.fromUserJson(userJson(isAdmin: true));

      expect(Permissions.fromCacheJson(original.toJson()).isAdmin, isTrue);
    });
  });

  test('the numeric values match the API contract', () {
    // These are the wire format, not an internal detail — renumbering them
    // would silently regrant the wrong modules.
    expect(PermissionName.cases.value, 1);
    expect(PermissionName.caseWorkflow.value, 2);
    expect(PermissionName.finance.value, 3);
    expect(PermissionName.statistics.value, 6);
    expect(PermissionName.users.value, 7);
    expect(PermissionName.roles.value, 8);
    expect(PermissionName.branches.value, 9);
    expect(PermissionName.appointments.value, 10);
    expect(PermissionName.scannerControl.value, 11);
    expect(PermissionName.attendance.value, 12);
    expect(PermissionName.payroll.value, 13);
    expect(PermissionName.leaves.value, 14);
    // 15/16 were transposed against the API for a while: the backend inserted
    // `Doctor` at 15 and pushed `RestorationType` to 16, so a grant on either
    // was being read as the other.
    expect(PermissionName.doctor.value, 15);
    expect(PermissionName.restorationType.value, 16);
    expect(PermissionType.read.value, 0);
    expect(PermissionType.fullAccess.value, 1);
  });
}
