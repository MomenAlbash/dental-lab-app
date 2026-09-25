import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the delete guidance the API sends', () {
    final patient = PatientModel.fromJson({
      'id': 'p1',
      'firstName': 'خالد',
      'canDelete': false,
      'deleteMessage': 'للمريض حالات مسجّلة',
    });

    expect(patient.canDelete, isFalse);
    expect(patient.deleteMessage, 'للمريض حالات مسجّلة');
  });

  test('treats a patient as deletable when the API omits the field', () {
    final patient = PatientModel.fromJson({'id': 'p1', 'firstName': 'خالد'});

    expect(patient.canDelete, isTrue);
    expect(patient.deleteMessage, isNull);
  });
}
