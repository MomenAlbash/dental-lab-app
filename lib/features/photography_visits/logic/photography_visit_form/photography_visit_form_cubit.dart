import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_filters_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:dental_lab_app/features/photography_visits/data/repos/photography_visits_repo.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_form/photography_visit_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Logs a new photography visit on a doctor's behalf.
class PhotographyVisitFormCubit extends Cubit<PhotographyVisitFormState> {
  PhotographyVisitFormCubit(
    this._repo,
    this._doctorsRepo,
    this._patientsRepo,
    this._accountingRepo,
  ) : super(const PhotographyVisitFormLoading());

  final PhotographyVisitsRepo _repo;
  final DoctorsRepo _doctorsRepo;
  final PatientsRepo _patientsRepo;
  final AccountingRepo _accountingRepo;

  List<DoctorModel> _doctors = const [];
  List<CurrencyModel> _currencies = const [];
  List<PatientModel> _patients = const [];

  Future<void> loadCatalog() async {
    emit(const PhotographyVisitFormLoading());

    final doctors = await _doctorsRepo.getDoctors();
    if (isClosed) return;
    final failure = doctors.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(PhotographyVisitFormCatalogError(failure.errorMessage));
      return;
    }
    _doctors = doctors.fold((_) => const [], (list) => list);

    // Only the price's currency picker needs these.
    final currencies = await _accountingRepo.getCurrencies();
    if (isClosed) return;
    _currencies = currencies.fold((_) => const [], (list) => list);

    _emitReady();
  }

  /// Loads the doctor's patients — the patient is optional, but when given it
  /// must be one of theirs. Null clears the list.
  Future<void> selectDoctor(String? doctorId) async {
    _patients = const [];
    if (doctorId == null) {
      _emitReady();
      return;
    }
    _emitReady(isLoadingPatients: true);

    final patients = await _patientsRepo.getPatients(
      filters: PatientFiltersModel(doctorId: doctorId),
    );
    if (isClosed) return;
    // A failure leaves the optional patient picker empty, not the form.
    _patients = patients.fold((_) => const [], (list) => list);
    _emitReady();
  }

  Future<void> create(CreatePhotographyVisitRequestModel body) async {
    _emitReady(isSubmitting: true);

    final result = await _repo.create(body);
    if (isClosed) return;

    result.fold((failure) {
      emit(PhotographyVisitFormSubmitError(failure.errorMessage));
      _emitReady();
    }, (visit) => emit(PhotographyVisitFormSuccess(visit)));
  }

  void _emitReady({bool isLoadingPatients = false, bool isSubmitting = false}) {
    emit(
      PhotographyVisitFormReady(
        doctors: _doctors,
        currencies: _currencies,
        patients: _patients,
        isLoadingPatients: isLoadingPatients,
        isSubmitting: isSubmitting,
      ),
    );
  }
}
