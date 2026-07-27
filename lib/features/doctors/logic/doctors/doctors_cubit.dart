import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoctorsCubit extends Cubit<DoctorsState> {
  DoctorsCubit(this._doctorsRepo) : super(const DoctorsInitial());

  final DoctorsRepo _doctorsRepo;

  Future<void> getDoctors() async {
    emit(const DoctorsLoading());

    final result = await _doctorsRepo.getDoctors();

    result.fold(
      (failure) => emit(DoctorsError(failure.errorMessage)),
      (doctors) => emit(DoctorsLoaded(doctors)),
    );
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
