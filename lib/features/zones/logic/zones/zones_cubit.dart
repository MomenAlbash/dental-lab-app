import 'package:dental_lab_app/features/zones/data/repos/zones_repo.dart';
import 'package:dental_lab_app/features/zones/logic/zones/zones_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ZonesCubit extends Cubit<ZonesState> {
  ZonesCubit(this._zonesRepo) : super(const ZonesInitial());

  final ZonesRepo _zonesRepo;

  Future<void> getZones() async {
    emit(const ZonesLoading());

    final result = await _zonesRepo.getZones(includeInactive: true);

    result.fold(
      (failure) => emit(ZonesError(failure.errorMessage)),
      (zones) => emit(ZonesLoaded(zones)),
    );
  }

  /// Removes the zone optimistically — the confirm dialog already asked
  /// once. Rolled back (with a toast, via [ZonesActionError]) if the server
  /// call fails.
  Future<void> deleteZone(String id) async {
    final state = this.state;
    if (state is! ZonesLoaded) return;

    final previous = state.zones;
    emit(
      ZonesLoaded([
        for (final z in previous)
          if (z.id != id) z,
      ]),
    );

    final result = await _zonesRepo.deleteZone(id);

    result.fold((failure) {
      emit(ZonesLoaded(previous));
      emit(ZonesActionError(failure.errorMessage));
    }, (_) {});
  }
}
