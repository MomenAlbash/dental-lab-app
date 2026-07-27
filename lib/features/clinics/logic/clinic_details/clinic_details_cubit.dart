import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_details/clinic_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClinicDetailsCubit extends Cubit<ClinicDetailsState> {
  ClinicDetailsCubit(this._clinicsRepo)
    : super(const ClinicDetailsInitial());

  final ClinicsRepo _clinicsRepo;

  Future<void> getClinicById(String id) async {
    emit(const ClinicDetailsLoading());

    final result = await _clinicsRepo.getClinicById(id);

    result.fold(
      (failure) => emit(ClinicDetailsError(failure.errorMessage)),
      (clinic) => emit(ClinicDetailsLoaded(clinic)),
    );
  }
}
