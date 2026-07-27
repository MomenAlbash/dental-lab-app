import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClinicsCubit extends Cubit<ClinicsState> {
  ClinicsCubit(this._clinicsRepo) : super(const ClinicsInitial());

  final ClinicsRepo _clinicsRepo;

  Future<void> getClinics() async {
    emit(const ClinicsLoading());

    final result = await _clinicsRepo.getClinics();

    result.fold(
      (failure) => emit(ClinicsError(failure.errorMessage)),
      (clinics) => emit(ClinicsLoaded(clinics)),
    );
  }

  Future<void> deleteClinic(String id) async {
    final result = await _clinicsRepo.deleteClinic(id);

    await result.fold(
      (failure) async => emit(ClinicDeleteError(failure.errorMessage)),
      (_) async {
        emit(const ClinicDeleted());
        await getClinics();
      },
    );
  }
}
