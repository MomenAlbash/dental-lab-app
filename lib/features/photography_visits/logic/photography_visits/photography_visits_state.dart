import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';

sealed class PhotographyVisitsState {
  const PhotographyVisitsState({
    this.status,
    this.doctorId,
    this.doctors = const [],
  });

  /// The filters travel with every state so the controls stay put while the
  /// list reloads. A null [status] is the "all" tab.
  final PhotographyVisitStatus? status;
  final String? doctorId;
  final List<DoctorModel> doctors;
}

class PhotographyVisitsLoading extends PhotographyVisitsState {
  const PhotographyVisitsLoading({super.status, super.doctorId, super.doctors});
}

class PhotographyVisitsError extends PhotographyVisitsState {
  const PhotographyVisitsError(
    this.message, {
    super.status,
    super.doctorId,
    super.doctors,
  });

  final String message;
}

class PhotographyVisitsLoaded extends PhotographyVisitsState {
  const PhotographyVisitsLoaded(
    this.visits, {
    super.status,
    super.doctorId,
    super.doctors,
  });

  final List<PhotographyVisitModel> visits;
}
