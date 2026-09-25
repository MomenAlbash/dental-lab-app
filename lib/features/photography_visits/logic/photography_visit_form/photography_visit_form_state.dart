import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';

sealed class PhotographyVisitFormState {
  const PhotographyVisitFormState();
}

class PhotographyVisitFormLoading extends PhotographyVisitFormState {
  const PhotographyVisitFormLoading();
}

/// The doctors could not be loaded — without them there is nobody to create
/// a visit for.
class PhotographyVisitFormCatalogError extends PhotographyVisitFormState {
  const PhotographyVisitFormCatalogError(this.message);
  final String message;
}

class PhotographyVisitFormReady extends PhotographyVisitFormState {
  const PhotographyVisitFormReady({
    required this.doctors,
    this.currencies = const [],
    this.patients = const [],
    this.isLoadingPatients = false,
    this.isSubmitting = false,
  });

  final List<DoctorModel> doctors;
  final List<CurrencyModel> currencies;

  /// The chosen doctor's patients — empty until a doctor is picked.
  final List<PatientModel> patients;
  final bool isLoadingPatients;
  final bool isSubmitting;
}

/// One-shot outcomes of the submit.
class PhotographyVisitFormSuccess extends PhotographyVisitFormState {
  const PhotographyVisitFormSuccess(this.visit);
  final PhotographyVisitModel visit;
}

class PhotographyVisitFormSubmitError extends PhotographyVisitFormState {
  const PhotographyVisitFormSubmitError(this.message);
  final String message;
}
