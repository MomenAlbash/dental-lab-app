import 'package:dental_lab_app/features/patients/data/models/patient_filters_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PatientsCubit extends Cubit<PatientsState> {
  PatientsCubit(this._patientsRepo) : super(const PatientsInitial());

  final PatientsRepo _patientsRepo;

  String? _search;
  PatientFiltersModel _filters = PatientFiltersModel.empty;

  PatientFiltersModel get filters => _filters;

  Future<void> getPatients({String? search}) async {
    if (search != null) _search = search;

    emit(const PatientsLoading());

    final result = await _patientsRepo.getPatients(
      search: _search,
      filters: _filters,
    );

    result.fold(
      (failure) => emit(PatientsError(failure.errorMessage)),
      (patients) => emit(PatientsLoaded(patients)),
    );
  }

  /// Replaces the active filters and reloads the list.
  Future<void> applyFilters(PatientFiltersModel filters) async {
    _filters = filters;
    await getPatients();
  }

  /// Deletes a patient, then reloads so the list reflects the server rather
  /// than a locally pruned copy — the delete can cascade to counts this list
  /// shows.
  Future<void> deletePatient(String id) async {
    final result = await _patientsRepo.deletePatient(id);

    await result.fold(
      (failure) async => emit(PatientDeleteError(failure.errorMessage)),
      (_) async {
        emit(const PatientDeleted());
        await getPatients();
      },
    );
  }
}
