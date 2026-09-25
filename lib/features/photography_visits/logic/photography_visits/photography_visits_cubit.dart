import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:dental_lab_app/features/photography_visits/data/repos/photography_visits_repo.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visits/photography_visits_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The photography visits list, by status tab and optionally one doctor.
/// Both filters are server-side.
class PhotographyVisitsCubit extends Cubit<PhotographyVisitsState> {
  PhotographyVisitsCubit(this._repo, this._doctorsRepo)
    : super(const PhotographyVisitsLoading());

  final PhotographyVisitsRepo _repo;
  final DoctorsRepo _doctorsRepo;

  PhotographyVisitStatus? _status;
  String? _doctorId;
  List<DoctorModel> _doctors = const [];

  /// Loads the doctor filter once, then the list.
  Future<void> init() async {
    final doctors = await _doctorsRepo.getDoctors();
    if (isClosed) return;
    // Only the filter needs these; the list works without them.
    _doctors = doctors.fold((_) => const [], (list) => list);
    await load();
  }

  Future<void> load() async {
    emit(
      PhotographyVisitsLoading(
        status: _status,
        doctorId: _doctorId,
        doctors: _doctors,
      ),
    );

    final result = await _repo.getVisits(doctorId: _doctorId, status: _status);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        PhotographyVisitsError(
          failure.errorMessage,
          status: _status,
          doctorId: _doctorId,
          doctors: _doctors,
        ),
      ),
      (visits) => emit(
        PhotographyVisitsLoaded(
          visits,
          status: _status,
          doctorId: _doctorId,
          doctors: _doctors,
        ),
      ),
    );
  }

  Future<void> setStatus(PhotographyVisitStatus? status) async {
    if (_status == status) return;
    _status = status;
    await load();
  }

  Future<void> setDoctor(String? doctorId) async {
    if (_doctorId == doctorId) return;
    _doctorId = doctorId;
    await load();
  }
}
