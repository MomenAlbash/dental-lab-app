import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_share_text.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('says who the case is for and where it stands', () {
    final text = CaseShareText.of(
      CaseDetailModel(
        id: 'c1',
        caseNumber: '120',
        patientName: 'سامي العلي',
        doctor: DoctorModel(id: 'd1', firstName: 'رامي', lastName: 'خليل'),
        clinic: ClinicModel(id: 'k1', name: 'عيادة النور'),
        phase: CasePhase.inProduction,
        dueDate: '2026-10-02T00:00:00',
        restorations: [CaseRestorationModel(id: 'r1', quantity: 3)],
        notes: 'ملاحظة داخلية',
      ),
    );

    expect(text, contains('حالة 120'));
    expect(text, contains('المريض: سامي العلي'));
    expect(text, contains('الطبيب: رامي خليل'));
    expect(text, contains('العيادة: عيادة النور'));
    expect(text, contains('× 3'));
    expect(text, contains('قيد الإنتاج'));
    expect(text, contains('موعد التسليم: 2026-10-02'));
  });

  test('leaves internal notes out — a message can be forwarded anywhere', () {
    final text = CaseShareText.of(
      CaseDetailModel(id: 'c1', notes: 'ملاحظة داخلية'),
    );

    expect(text, isNot(contains('ملاحظة داخلية')));
    expect(text, 'حالة بدون رقم');
  });
}
