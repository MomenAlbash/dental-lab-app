import 'package:dental_lab_app/features/patients/data/models/create_patient_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('omits gender entirely when it was not chosen', () {
    // Reproduces the 400 the API answered with: `gender` maps to a
    // non-nullable enum server-side, so an explicit null was rejected with
    // "The JSON value could not be converted to ... Gender".
    final json = CreatePatientRequestModel(
      doctorId: 'd-1',
      firstName: 'ليلى',
    ).toJson();

    expect(json.containsKey('gender'), isFalse);
    expect(json['firstName'], 'ليلى');
    expect(json['doctorId'], 'd-1');
  });

  test('sends gender when one was chosen', () {
    final json = CreatePatientRequestModel(
      doctorId: 'd-1',
      firstName: 'ليلى',
      gender: 1,
    ).toJson();

    expect(json['gender'], 1);
  });
}
