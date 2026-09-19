import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:dental_lab_app/features/zones/data/models/save_zone_request_models.dart';
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZoneRepresentativeModel', () {
    test(
      'reads the field names the API sends, not employeeId/employeeName',
      () {
        // `ClinicZoneRepresentativeDto` carries `userId`/`name` — a
        // representative is a login (`UserType.Representative`), not an
        // employee record. The old keys never matched anything on the wire, so
        // every representative picker in the app showed blank names.
        final rep = ZoneRepresentativeModel.fromJson(const {
          'id': 'r1',
          'userId': 'u1',
          'name': 'سارة',
          'phoneNumber': '0991234567',
          'isPrimary': true,
        });

        expect(rep.userId, 'u1');
        expect(rep.name, 'سارة');
        expect(rep.phoneNumber, '0991234567');
        expect(rep.isPrimary, isTrue);
      },
    );
  });

  group('ZoneModel', () {
    test('reads representatives with the real field names', () {
      final zone = ZoneModel.fromJson(const {
        'id': 'z1',
        'laboratoryId': 'lab1',
        'representatives': [
          {'id': 'r1', 'userId': 'u1', 'name': 'سارة'},
        ],
      });

      expect(zone.representatives.single.userId, 'u1');
      expect(zone.representatives.single.name, 'سارة');
    });
  });

  group('CreateZoneRequestModel / UpdateZoneRequestModel', () {
    test('send representativeUserIds, not representativeEmployeeIds', () {
      // `ClinicCreateZoneRequest.representativeUserIds` — the old key sent
      // representative *employee* ids under a name the server never
      // declared, so assigning a representative to a zone saved nothing.
      final createJson = const CreateZoneRequestModel(
        name: 'المزة',
        representativeUserIds: ['u1'],
      ).toJson();

      expect(createJson['representativeUserIds'], ['u1']);
      expect(createJson.containsKey('representativeEmployeeIds'), isFalse);

      final updateJson = const UpdateZoneRequestModel(
        representativeUserIds: ['u1'],
      ).toJson();

      expect(updateJson['representativeUserIds'], ['u1']);
      expect(updateJson.containsKey('representativeEmployeeIds'), isFalse);
    });
  });
}
