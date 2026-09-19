import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';

sealed class PriceTierDoctorsState {
  const PriceTierDoctorsState();
}

class PriceTierDoctorsInitial extends PriceTierDoctorsState {
  const PriceTierDoctorsInitial();
}

class PriceTierDoctorsLoading extends PriceTierDoctorsState {
  const PriceTierDoctorsLoading();
}

class PriceTierDoctorsLoaded extends PriceTierDoctorsState {
  const PriceTierDoctorsLoaded(this.doctors, {this.isBusy = false});

  final List<PriceTierDoctorModel> doctors;

  /// A write is in flight. Actions disable rather than the list vanishing —
  /// two edits racing would leave an assignment neither user chose.
  final bool isBusy;

  PriceTierDoctorsLoaded copyWith({
    List<PriceTierDoctorModel>? doctors,
    bool? isBusy,
  }) => PriceTierDoctorsLoaded(
    doctors ?? this.doctors,
    isBusy: isBusy ?? this.isBusy,
  );
}

class PriceTierDoctorsError extends PriceTierDoctorsState {
  const PriceTierDoctorsError(this.message);

  final String message;
}

/// A one-shot message: the cubit emits it, the screen toasts it, and the
/// loaded state comes straight back.
class PriceTierDoctorsMessage extends PriceTierDoctorsState {
  const PriceTierDoctorsMessage(this.message, {this.isError = false});

  final String message;
  final bool isError;
}
