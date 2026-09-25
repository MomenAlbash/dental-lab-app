import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_filters_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:dental_lab_app/features/photography_visits/data/repos/photography_visits_repo.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_detail/photography_visit_detail_cubit.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_detail/photography_visit_detail_state.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_form/photography_visit_form_cubit.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_form/photography_visit_form_state.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visits/photography_visits_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockVisitsRepo extends Mock implements PhotographyVisitsRepo {}

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

class _MockPatientsRepo extends Mock implements PatientsRepo {}

class _MockEmployeesRepo extends Mock implements EmployeesRepo {}

class _MockAccountingRepo extends Mock implements AccountingRepo {}

const _requested = PhotographyVisitModel(id: 'v1', doctorId: 'd1');
const _completed = PhotographyVisitModel(
  id: 'v1',
  doctorId: 'd1',
  status: PhotographyVisitStatus.completed,
  invoiceId: 'inv1',
);

void main() {
  setUpAll(() {
    registerFallbackValue(const CompletePhotographyVisitRequestModel());
    registerFallbackValue(PatientFiltersModel.empty);
  });

  group('PhotographyVisitModel', () {
    test('reads status, type, shade and photos', () {
      final visit = PhotographyVisitModel.fromJson({
        'id': 'v1',
        'doctorId': 'd1',
        'visitType': 2,
        'status': 3,
        'toothShade': 'A2',
        'shadeGuideUsed': true,
        'price': 50,
        'currencyCode': 'USD',
        'photos': [
          {'id': 'p1', 'filePath': '/uploads/p1.jpg'},
        ],
      });

      expect(
        visit.visitType,
        PhotographyVisitType.doctorSendsPhotosElectronically,
      );
      expect(visit.status, PhotographyVisitStatus.completed);
      expect(visit.shade.toothShade, 'A2');
      expect(visit.shade.shadeGuideUsed, isTrue);
      expect(visit.priceLabel, '50.00 USD');
      expect(visit.photos.single.filePath, '/uploads/p1.jpg');
    });

    test('only a visit to the clinic can be scheduled', () {
      expect(
        PhotographyVisitType.labTechnicianVisitsClinic.isSchedulable,
        isTrue,
      );
      expect(
        PhotographyVisitType.doctorSendsPhotosElectronically.isSchedulable,
        isFalse,
      );
    });

    test('only a requested or scheduled visit is still open', () {
      expect(PhotographyVisitStatus.requested.isOpen, isTrue);
      expect(PhotographyVisitStatus.scheduled.isOpen, isTrue);
      expect(PhotographyVisitStatus.completed.isOpen, isFalse);
      expect(PhotographyVisitStatus.cancelled.isOpen, isFalse);
    });
  });

  group('requests', () {
    test('create carries no case id and sends the shade fields', () {
      final json = const CreatePhotographyVisitRequestModel(
        doctorId: 'd1',
        visitType: PhotographyVisitType.labTechnicianVisitsClinic,
        shade: PhotographyShadeNotes(toothShade: 'B1'),
      ).toJson();

      expect(json.containsKey('caseId'), isFalse);
      expect(json['visitType'], 1);
      expect(json['toothShade'], 'B1');
    });

    test('schedule leaves the price out when it is unchanged', () {
      // A null price keeps the one set on request; sending it would not.
      final json = SchedulePhotographyVisitRequestModel(
        scheduledAt: DateTime.utc(2026, 10, 1, 9),
      ).toJson();

      expect(json.containsKey('price'), isFalse);
      expect(json.containsKey('currencyId'), isFalse);
      expect(json['scheduledAt'], '2026-10-01T09:00:00.000Z');
    });

    test('complete sends a changed price', () {
      final json = const CompletePhotographyVisitRequestModel(
        price: 75,
        currencyId: 'c1',
      ).toJson();

      expect(json['price'], 75);
      expect(json['currencyId'], 'c1');
    });
  });

  group('PhotographyVisitsCubit', () {
    test('filters by status on the server', () async {
      final repo = _MockVisitsRepo();
      final doctors = _MockDoctorsRepo();
      when(
        () => doctors.getDoctors(),
      ).thenAnswer((_) async => const Right<Failure, List<DoctorModel>>([]));
      when(
        () => repo.getVisits(
          doctorId: any(named: 'doctorId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, List<PhotographyVisitModel>>([]),
      );
      final cubit = PhotographyVisitsCubit(repo, doctors);
      addTearDown(cubit.close);

      await cubit.init();
      await cubit.setStatus(PhotographyVisitStatus.scheduled);

      verify(
        () => repo.getVisits(
          doctorId: null,
          status: PhotographyVisitStatus.scheduled,
        ),
      ).called(1);
    });
  });

  group('PhotographyVisitDetailCubit', () {
    late _MockVisitsRepo repo;
    late PhotographyVisitDetailCubit cubit;

    setUp(() {
      repo = _MockVisitsRepo();
      final employees = _MockEmployeesRepo();
      final accounting = _MockAccountingRepo();
      when(() => repo.getVisit('v1')).thenAnswer(
        (_) async => const Right<Failure, PhotographyVisitModel>(_requested),
      );
      when(
        () => employees.getEmployees(),
      ).thenAnswer((_) async => const Right<Failure, List<EmployeeModel>>([]));
      when(
        () => accounting.getCurrencies(),
      ).thenAnswer((_) async => const Right<Failure, List<CurrencyModel>>([]));
      cubit = PhotographyVisitDetailCubit(repo, employees, accounting);
    });

    tearDown(() => cubit.close());

    test('completing replaces the visit and marks the list stale', () async {
      when(() => repo.complete('v1', any())).thenAnswer(
        (_) async => const Right<Failure, PhotographyVisitModel>(_completed),
      );
      await cubit.load('v1');

      await cubit.complete(const CompletePhotographyVisitRequestModel());

      final state = cubit.state as PhotographyVisitDetailLoaded;
      expect(state.visit.status, PhotographyVisitStatus.completed);
      expect(cubit.changed, isTrue);
    });

    test('a refused action keeps the visit as it was', () async {
      when(() => repo.cancel('v1', note: any(named: 'note'))).thenAnswer(
        (_) async =>
            Left<Failure, PhotographyVisitModel>(ServerFailure('refused')),
      );
      await cubit.load('v1');

      await cubit.cancel();

      final state = cubit.state as PhotographyVisitDetailLoaded;
      expect(state.visit.status, PhotographyVisitStatus.requested);
      expect(cubit.changed, isFalse);
    });

    test('deleting a photo refetches the visit', () async {
      when(
        () => repo.deletePhoto('v1', 'p1'),
      ).thenAnswer((_) async => const Right<Failure, void>(null));
      await cubit.load('v1');

      await cubit.deletePhoto('p1');

      // Once on open, once after the delete.
      verify(() => repo.getVisit('v1')).called(2);
    });
  });

  group('PhotographyVisitFormCubit', () {
    late _MockDoctorsRepo doctors;
    late _MockPatientsRepo patients;
    late PhotographyVisitFormCubit cubit;

    setUp(() {
      doctors = _MockDoctorsRepo();
      patients = _MockPatientsRepo();
      final accounting = _MockAccountingRepo();
      when(
        () => accounting.getCurrencies(),
      ).thenAnswer((_) async => const Right<Failure, List<CurrencyModel>>([]));
      cubit = PhotographyVisitFormCubit(
        _MockVisitsRepo(),
        doctors,
        patients,
        accounting,
      );
    });

    tearDown(() => cubit.close());

    test('no doctors means nothing to create a visit for', () async {
      when(() => doctors.getDoctors()).thenAnswer(
        (_) async => Left<Failure, List<DoctorModel>>(ServerFailure('down')),
      );

      await cubit.loadCatalog();

      expect(cubit.state, isA<PhotographyVisitFormCatalogError>());
    });

    test('picking a doctor loads only their patients', () async {
      when(
        () => doctors.getDoctors(),
      ).thenAnswer((_) async => const Right<Failure, List<DoctorModel>>([]));
      when(
        () => patients.getPatients(filters: any(named: 'filters')),
      ).thenAnswer((_) async => const Right<Failure, List<PatientModel>>([]));
      await cubit.loadCatalog();

      await cubit.selectDoctor('d1');

      final filters =
          verify(
                () =>
                    patients.getPatients(filters: captureAny(named: 'filters')),
              ).captured.single
              as PatientFiltersModel;
      expect(filters.doctorId, 'd1');
    });
  });
}
