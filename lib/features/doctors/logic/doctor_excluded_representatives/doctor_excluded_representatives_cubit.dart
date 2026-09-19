import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_excluded_representatives/doctor_excluded_representatives_state.dart';
import 'package:dental_lab_app/features/zones/data/repos/zones_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Who is vetoed from taking this doctor's scanner sessions
/// (`DoctorRouting`).
///
/// Two different reads feed one screen: the doctor's own exclusion list
/// (`GET /doctors/{id}/excluded-representatives`) and their zone's whole
/// representative roster (`GET /Zones/{id}`) — the candidate pool, since
/// excluding someone who could never be offered the session in the first
/// place is not a real choice.
class DoctorExcludedRepresentativesCubit
    extends Cubit<DoctorExcludedRepresentativesState> {
  DoctorExcludedRepresentativesCubit(this._doctorsRepo, this._zonesRepo)
    : super(const DoctorExcludedRepresentativesLoading());

  final DoctorsRepo _doctorsRepo;
  final ZonesRepo _zonesRepo;

  late String _doctorId;
  String? _zoneId;

  Future<void> load({required String doctorId, String? zoneId}) async {
    _doctorId = doctorId;
    _zoneId = zoneId;
    emit(const DoctorExcludedRepresentativesLoading());

    final excludedResult = await _doctorsRepo.getExcludedRepresentatives(
      doctorId,
    );
    if (isClosed) return;

    await excludedResult.fold(
      (failure) async =>
          emit(DoctorExcludedRepresentativesError(failure.errorMessage)),
      (excluded) async {
        // No zone, no candidates — a real state, not an error: a doctor with
        // no area or an unpinned one simply has nobody to exclude yet.
        if (zoneId == null || zoneId.isEmpty) {
          emit(
            DoctorExcludedRepresentativesLoaded(
              excluded: excluded,
              zoneRepresentatives: const [],
            ),
          );
          return;
        }

        final zoneResult = await _zonesRepo.getZoneById(zoneId);
        if (isClosed) return;

        emit(
          DoctorExcludedRepresentativesLoaded(
            excluded: excluded,
            zoneRepresentatives: zoneResult.fold(
              (_) => const [],
              (zone) => zone.representatives,
            ),
          ),
        );
      },
    );
  }

  Future<void> exclude({required String userId, String? reason}) async {
    final current = state;
    if (current is! DoctorExcludedRepresentativesLoaded) return;
    emit(current.copyWith(isBusy: true));

    final result = await _doctorsRepo.excludeRepresentative(
      doctorId: _doctorId,
      userId: userId,
      reason: reason,
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(
          DoctorExcludedRepresentativesMessage(
            failure.errorMessage,
            isError: true,
          ),
        );
        emit(current);
      },
      (_) async {
        emit(const DoctorExcludedRepresentativesMessage('تم استثناء المندوب'));
        await load(doctorId: _doctorId, zoneId: _zoneId);
      },
    );
  }

  /// Removes an exclusion. Optimistic — the row disappears immediately and is
  /// put back with a toast if the server refuses, rather than making the tap
  /// wait on a round trip for a single-item removal.
  Future<void> unexclude(String userId) async {
    final current = state;
    if (current is! DoctorExcludedRepresentativesLoaded) return;

    final optimistic = current.copyWith(
      excluded: [
        for (final rep in current.excluded)
          if (rep.userId != userId) rep,
      ],
    );
    emit(optimistic);

    final result = await _doctorsRepo.removeExcludedRepresentative(
      doctorId: _doctorId,
      userId: userId,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          DoctorExcludedRepresentativesMessage(
            failure.errorMessage,
            isError: true,
          ),
        );
        emit(current);
      },
      (_) {
        emit(const DoctorExcludedRepresentativesMessage('تم إلغاء الاستثناء'));
        emit(optimistic);
      },
    );
  }
}
