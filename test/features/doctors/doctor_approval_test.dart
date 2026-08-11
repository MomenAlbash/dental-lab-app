import 'package:dental_lab_app/features/doctors/data/models/approve_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoctorApprovalStatus', () {
    test('maps the API codes', () {
      expect(DoctorApprovalStatus.fromApi(1), DoctorApprovalStatus.pending);
      expect(DoctorApprovalStatus.fromApi(2), DoctorApprovalStatus.approved);
      expect(DoctorApprovalStatus.fromApi(3), DoctorApprovalStatus.rejected);
    });

    test('treats a missing status as approved', () {
      // Doctors the lab created itself come back without the field; they are
      // already part of its data and must not show up as needing review.
      expect(DoctorApprovalStatus.fromApi(null), DoctorApprovalStatus.approved);
    });
  });

  group('DoctorModel', () {
    test('reads the approval fields off the JSON', () {
      final doctor = DoctorModel.fromJson({
        'id': 'd1',
        'firstName': 'أحمد',
        'approvalStatus': 1,
        'requestedClinicName': 'عيادة النور',
        'rejectionReason': null,
      });

      expect(doctor.approvalStatus, DoctorApprovalStatus.pending);
      expect(doctor.isPending, isTrue);
      expect(doctor.requestedClinicName, 'عيادة النور');
    });

    test('a rejected doctor carries the reason', () {
      final doctor = DoctorModel.fromJson({
        'id': 'd1',
        'approvalStatus': 3,
        'rejectionReason': 'بيانات غير مكتملة',
      });

      expect(doctor.approvalStatus, DoctorApprovalStatus.rejected);
      expect(doctor.isPending, isFalse);
      expect(doctor.rejectionReason, 'بيانات غير مكتملة');
    });
  });

  group('ApproveDoctorRequestModel', () {
    test('sends only the fields that were set', () {
      const request = ApproveDoctorRequestModel(clinicId: 'c1');

      expect(request.toJson(), {'clinicId': 'c1'});
    });

    test('nests a new clinic when one is being created', () {
      const request = ApproveDoctorRequestModel(
        newClinic: NewClinicForDoctorRequestModel(name: 'عيادة النور'),
      );

      expect(request.toJson(), {
        'newClinic': {'name': 'عيادة النور'},
      });
    });

    test('omits every unset field rather than sending nulls', () {
      // The model mirrors the API, which allows an empty body; requiring a
      // clinic is the approve dialog's rule, enforced there.
      expect(const ApproveDoctorRequestModel().toJson(), isEmpty);
    });

    test('refuses an existing and a new clinic at once', () {
      // The two are alternative answers to the same question; sending both
      // would leave the outcome up to the server.
      expect(
        () => ApproveDoctorRequestModel(
          clinicId: 'c1',
          newClinic: const NewClinicForDoctorRequestModel(name: 'عيادة'),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  test('RejectDoctorRequestModel sends the reason', () {
    const request = RejectDoctorRequestModel(reason: 'بيانات غير مكتملة');

    expect(request.toJson(), {'reason': 'بيانات غير مكتملة'});
  });
}
