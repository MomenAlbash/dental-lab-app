import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_details/doctor_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoctorDetailsCubit extends Cubit<DoctorDetailsState> {
  DoctorDetailsCubit(this._doctorsRepo) : super(const DoctorDetailsInitial());

  final DoctorsRepo _doctorsRepo;

  DoctorModel? _doctor;

  Future<void> getDoctor(String id) async {
    emit(const DoctorDetailsLoading());

    final result = await _doctorsRepo.getDoctorById(id);

    result.fold((failure) => emit(DoctorDetailsError(failure.errorMessage)), (
      doctor,
    ) {
      _doctor = doctor;
      emit(DoctorDetailsLoaded(doctor));
    });
  }

  Future<void> uploadFile(String filePath) async {
    final doctor = _doctor;
    if (doctor == null) return;

    emit(DoctorDetailsLoaded(doctor, isBusy: true));

    final result = await _doctorsRepo.uploadDoctorFile(
      id: doctor.id,
      filePath: filePath,
    );

    await result.fold(
      (failure) async {
        emit(DoctorDetailsActionError(failure.errorMessage));
        emit(DoctorDetailsLoaded(doctor));
      },
      (_) async {
        emit(const DoctorDetailsActionSuccess('تمت إضافة الملف'));
        await _refresh();
      },
    );
  }

  Future<void> deleteFile(String fileId) async {
    final doctor = _doctor;
    if (doctor == null) return;

    emit(DoctorDetailsLoaded(doctor, isBusy: true));

    final result = await _doctorsRepo.deleteDoctorFile(
      id: doctor.id,
      fileId: fileId,
    );

    await result.fold(
      (failure) async {
        emit(DoctorDetailsActionError(failure.errorMessage));
        emit(DoctorDetailsLoaded(doctor));
      },
      (_) async {
        emit(const DoctorDetailsActionSuccess('تم حذف الملف'));
        await _refresh();
      },
    );
  }

  /// Re-fetches the doctor so the attachments list reflects the latest state.
  Future<void> _refresh() async {
    final doctor = _doctor;
    if (doctor == null) return;

    final result = await _doctorsRepo.getDoctorById(doctor.id);

    result.fold((_) => emit(DoctorDetailsLoaded(doctor)), (refreshed) {
      _doctor = refreshed;
      emit(DoctorDetailsLoaded(refreshed));
    });
  }
}
