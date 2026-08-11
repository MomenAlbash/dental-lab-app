import 'package:dental_lab_app/features/doctors/data/models/doctor_filters_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The `GET /Doctors` endpoint doesn't support server-side filtering (no
/// clinic/city/gender query params), so filters are applied client-side over
/// the fetched list instead.
class DoctorsCubit extends Cubit<DoctorsState> {
  DoctorsCubit(this._doctorsRepo) : super(const DoctorsInitial());

  final DoctorsRepo _doctorsRepo;

  List<DoctorModel> _allDoctors = [];
  DoctorFiltersModel _filters = DoctorFiltersModel.empty;

  DoctorFiltersModel get filters => _filters;

  Future<void> getDoctors() async {
    emit(const DoctorsLoading());

    final result = await _doctorsRepo.getDoctors();

    result.fold((failure) => emit(DoctorsError(failure.errorMessage)), (
      doctors,
    ) {
      _allDoctors = doctors;
      emit(DoctorsLoaded(_applyFilters(doctors)));
    });
  }

  List<DoctorModel> _applyFilters(List<DoctorModel> doctors) {
    if (_filters.isEmpty) return doctors;
    return doctors.where((doctor) {
      if (_filters.clinicId != null && doctor.clinicId != _filters.clinicId) {
        return false;
      }
      if (_filters.cityId != null && doctor.cityId != _filters.cityId) {
        return false;
      }
      if (_filters.gender != null && doctor.gender != _filters.gender) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Replaces the active filters and re-applies them to the already-fetched
  /// list, without another network call.
  void applyFilters(DoctorFiltersModel filters) {
    _filters = filters;
    emit(DoctorsLoaded(_applyFilters(_allDoctors)));
  }

  Future<void> deleteDoctor(String id) async {
    final result = await _doctorsRepo.deleteDoctor(id);

    await result.fold(
      (failure) async => emit(DoctorDeleteError(failure.errorMessage)),
      (_) async {
        emit(const DoctorDeleted());
        await getDoctors();
      },
    );
  }
}
