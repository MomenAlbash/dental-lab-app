import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';

sealed class DoctorQuotaState {
  const DoctorQuotaState();
}

class DoctorQuotaInitial extends DoctorQuotaState {
  const DoctorQuotaInitial();
}

class DoctorQuotaLoading extends DoctorQuotaState {
  const DoctorQuotaLoading();
}

class DoctorQuotaLoaded extends DoctorQuotaState {
  const DoctorQuotaLoaded(this.quota, {this.isBusy = false});

  final DoctorPriorityQuotaModel quota;

  /// A write is in flight. Rows disable rather than the list vanishing.
  final bool isBusy;

  DoctorQuotaLoaded copyWith({DoctorPriorityQuotaModel? quota, bool? isBusy}) =>
      DoctorQuotaLoaded(quota ?? this.quota, isBusy: isBusy ?? this.isBusy);
}

class DoctorQuotaError extends DoctorQuotaState {
  const DoctorQuotaError(this.message);

  final String message;
}

/// A one-shot message: the cubit emits it, the screen toasts it, and the
/// loaded state comes straight back.
class DoctorQuotaMessage extends DoctorQuotaState {
  const DoctorQuotaMessage(this.message, {this.isError = false});

  final String message;
  final bool isError;
}
