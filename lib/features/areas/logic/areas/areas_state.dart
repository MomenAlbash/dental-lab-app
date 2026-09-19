import 'package:dental_lab_app/features/areas/data/models/area_model.dart';

sealed class AreasState {
  const AreasState();
}

class AreasInitial extends AreasState {
  const AreasInitial();
}

class AreasLoading extends AreasState {
  const AreasLoading();
}

class AreasLoaded extends AreasState {
  const AreasLoaded(this.areas, {this.isBusy = false});
  final List<AreaModel> areas;

  /// True while a create/update/delete is in flight.
  final bool isBusy;
}

class AreasError extends AreasState {
  const AreasError(this.message);
  final String message;
}

/// Transient failure of an action — surfaced as a toast.
class AreasActionError extends AreasState {
  const AreasActionError(this.message);
  final String message;
}
