import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';

sealed class ZonesState {
  const ZonesState();
}

class ZonesInitial extends ZonesState {
  const ZonesInitial();
}

class ZonesLoading extends ZonesState {
  const ZonesLoading();
}

class ZonesLoaded extends ZonesState {
  const ZonesLoaded(this.zones);
  final List<ZoneModel> zones;
}

class ZonesError extends ZonesState {
  const ZonesError(this.message);
  final String message;
}

/// Emitted after an optimistic delete is rolled back — a toast only, never
/// something the list rebuilds on directly.
class ZonesActionError extends ZonesState {
  const ZonesActionError(this.message);
  final String message;
}
