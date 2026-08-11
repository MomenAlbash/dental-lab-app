import 'package:dental_lab_app/features/doctors/data/models/approve_doctor_request_model.dart';
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

  /// Accepts a self-registered doctor's registration.
  ///
  /// [clinicId] links them to a clinic the lab already has; [newClinicName]
  /// creates the one they asked for. Passing neither approves without a
  /// clinic, which the API allows.
  Future<void> approve({
    String? clinicId,
    String? newClinicName,
    String? note,
  }) async {
    final doctor = _doctor;
    if (doctor == null) return;

    emit(DoctorDetailsLoaded(doctor, isBusy: true));

    final result = await _doctorsRepo.approveDoctor(
      id: doctor.id,
      approveDoctorRequestBody: ApproveDoctorRequestModel(
        clinicId: clinicId,
        newClinic: newClinicName == null
            ? null
            : NewClinicForDoctorRequestModel(name: newClinicName),
        note: note,
      ),
    );

    await result.fold(
      (failure) async {
        emit(DoctorDetailsActionError(failure.errorMessage));
        emit(DoctorDetailsLoaded(doctor));
      },
      (_) async {
        emit(const DoctorDetailsActionSuccess('تم قبول الدكتور'));
        await _refresh();
      },
    );
  }

  /// Turns a registration down. [reason] is required by the API and is shown
  /// back on the doctor's page afterwards.
  Future<void> reject(String reason) async {
    final doctor = _doctor;
    if (doctor == null) return;

    emit(DoctorDetailsLoaded(doctor, isBusy: true));

    final result = await _doctorsRepo.rejectDoctor(
      id: doctor.id,
      rejectDoctorRequestBody: RejectDoctorRequestModel(reason: reason),
    );

    await result.fold(
      (failure) async {
        emit(DoctorDetailsActionError(failure.errorMessage));
        emit(DoctorDetailsLoaded(doctor));
      },
      (_) async {
        emit(const DoctorDetailsActionSuccess('تم رفض الدكتور'));
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
