import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';

sealed class DoctorDetailsState {
  const DoctorDetailsState();
}

class DoctorDetailsInitial extends DoctorDetailsState {
  const DoctorDetailsInitial();
}

class DoctorDetailsLoading extends DoctorDetailsState {
  const DoctorDetailsLoading();
}

class DoctorDetailsLoaded extends DoctorDetailsState {
  const DoctorDetailsLoaded(this.doctor, {this.isBusy = false});

  final DoctorModel doctor;

  /// True while an image/file upload or a file deletion is in flight.
  final bool isBusy;
}

class DoctorDetailsError extends DoctorDetailsState {
  const DoctorDetailsError(this.message);
  final String message;
}

/// Transient failure of an image/file action — surfaced as a toast without
/// tearing down the loaded details.
class DoctorDetailsActionError extends DoctorDetailsState {
  const DoctorDetailsActionError(this.message);
  final String message;
}

/// Transient success of an image/file action — surfaced as a toast.
class DoctorDetailsActionSuccess extends DoctorDetailsState {
  const DoctorDetailsActionSuccess(this.message);
  final String message;
}
