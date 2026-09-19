import 'package:dental_lab_app/features/doctors/data/models/doctor_lookup_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/footer_contact_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_lookup_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoctorLookupModel', () {
    test('the clinic is the subtitle — it is what tells namesakes apart', () {
      final doctor = DoctorLookupModel.fromJson(const {
        'id': 'd1',
        'fullName': 'سامر',
        'phoneNumber': '0900',
        'clinicName': 'عيادة النور',
      });

      expect(doctor.subtitle, 'عيادة النور');
    });

    test('the phone stands in when there is no clinic', () {
      final doctor = DoctorLookupModel.fromJson(const {
        'id': 'd1',
        'fullName': 'سامر',
        'phoneNumber': '0900',
      });

      expect(doctor.subtitle, '0900');
    });

    test('a nameless row shows a dash rather than an empty picker line', () {
      final doctor = DoctorLookupModel.fromJson(const {'id': 'd1'});

      expect(doctor.displayName, '—');
    });
  });

  group('PatientLookupModel', () {
    test('age is computed from the birth date, not stored', () {
      final born = DateTime.now().subtract(const Duration(days: 365 * 30 + 8));
      final patient = PatientLookupModel.fromJson({
        'id': 'p1',
        'dateOfBirth': born.toIso8601String().split('T').first,
      });

      expect(patient.age, 30);
    });

    test('a birthday later this year has not happened yet', () {
      final now = DateTime.now();
      // Exactly one year old minus a day: still zero.
      final born = now.subtract(const Duration(days: 364));
      final patient = PatientLookupModel.fromJson({
        'id': 'p1',
        'dateOfBirth': born.toIso8601String().split('T').first,
      });

      expect(patient.age, 0);
    });

    test('no birth date gives no age rather than zero', () {
      final patient = PatientLookupModel.fromJson(const {'id': 'p1'});

      expect(patient.age, isNull);
    });

    test('the referring doctor comes through — it reveals a mis-pick', () {
      final patient = PatientLookupModel.fromJson(const {
        'id': 'p1',
        'fullName': 'ليلى',
        'doctorName': 'د. سامر',
      });

      expect(patient.doctorName, 'د. سامر');
    });
  });

  group('FooterContactModel', () {
    test('displayOrder is read explicitly, not taken from list position', () {
      final contact = FooterContactModel.fromJson(const {
        'id': 'f1',
        'name': 'الاستقبال',
        'phoneNumber': '0900',
        'displayOrder': 3,
      });

      expect(contact.displayOrder, 3);
    });
  });

  group('SaveFooterContactModel', () {
    test('an existing row keeps its id so the server edits in place', () {
      final json = SaveFooterContactModel.fromModel(
        FooterContactModel.fromJson(const {
          'id': 'f1',
          'name': 'الاستقبال',
          'phoneNumber': '0900',
        }),
      ).toJson();

      expect(json['id'], 'f1');
      expect(json['name'], 'الاستقبال');
    });

    test('a row with no id is a create, not an edit of the empty string', () {
      final json = const SaveFooterContactModel(
        name: 'المحاسبة',
        phoneNumber: '0911',
      ).toJson();

      expect(json['id'], isNull);
    });
  });

  group('LaboratoryModel', () {
    test('footer contacts are parsed off the laboratory', () {
      final laboratory = LaboratoryModel.fromJson(const {
        'id': 'l1',
        'logoPath': '/media/logo.png',
        'footerContacts': [
          {'id': 'f1', 'name': 'الاستقبال', 'displayOrder': 0},
          {'id': 'f2', 'name': 'المحاسبة', 'displayOrder': 1},
        ],
      });

      expect(laboratory.footerContacts, hasLength(2));
      expect(laboratory.logoPath, '/media/logo.png');
    });

    test('no logo is null, which is not the same as an empty one', () {
      final laboratory = LaboratoryModel.fromJson(const {'id': 'l1'});

      expect(laboratory.logoPath, isNull);
      expect(laboratory.footerContacts, isEmpty);
    });

    test('the contacts survive a cache round-trip', () {
      final original = LaboratoryModel.fromJson(const {
        'id': 'l1',
        'logoPath': '/media/logo.png',
        'footerContacts': [
          {'id': 'f1', 'name': 'الاستقبال', 'phoneNumber': '0900'},
        ],
      });

      final restored = LaboratoryModel.fromJson(original.toJson());

      expect(restored.footerContacts.single.name, 'الاستقبال');
      expect(restored.logoPath, '/media/logo.png');
    });
  });
}
