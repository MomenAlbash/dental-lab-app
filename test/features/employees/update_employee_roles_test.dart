import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/models/update_employee_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the update body carries both role flags', () {
    final json = UpdateEmployeeRequestModel(
      isRepresentative: false,
      isAgent: true,
    ).toJson();
    expect(json['isAgent'], isTrue);
    expect(json['isRepresentative'], isFalse);
  });

  test('unset role flags are left out of the update body', () {
    final json = UpdateEmployeeRequestModel().toJson();
    expect(json.containsKey('isAgent'), isFalse);
    expect(json.containsKey('isRepresentative'), isFalse);
  });

  test('isAgent is read from the employee', () {
    expect(
      EmployeeModel.fromJson(const {'id': 'e1', 'isAgent': true}).isAgent,
      isTrue,
    );
  });
}
