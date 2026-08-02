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
}
