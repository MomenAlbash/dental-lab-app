import 'package:dental_lab_app/features/doctors/data/models/approve_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/update_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_details/doctor_details_state.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/set_price_tier_doctors_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/repos/price_tiers_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoctorDetailsCubit extends Cubit<DoctorDetailsState> {
  DoctorDetailsCubit(this._doctorsRepo, this._priceTiersRepo)
    : super(const DoctorDetailsInitial());

  final DoctorsRepo _doctorsRepo;

  /// Needed only to *remove* a doctor from a tier — see [setPriceTier].
  final PriceTiersRepo _priceTiersRepo;

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

  /// Moves this doctor onto a price tier, or off one when [priceTierId] is
  /// null.
  ///
  /// Every other field is resent from the loaded doctor because
  /// `PUT /Doctors/{id}` **replaces** rather than patches: sending the tier
  /// alone would blank their name, phone and clinic.
  Future<void> setPriceTier(String? priceTierId) async {
    if (priceTierId == null) return _detachFromTier();

    final doctor = _doctor;
    if (doctor == null) return;

    emit(DoctorDetailsLoaded(doctor, isBusy: true));

    final result = await _doctorsRepo.updateDoctor(
      id: doctor.id,
      updateDoctorRequestBody: UpdateDoctorRequestModel(
        firstName: doctor.firstName,
        lastName: doctor.lastName,
        email: doctor.email,
        phoneNumber: doctor.phoneNumber,
        address: doctor.address,
        gender: doctor.gender?.apiValue,
        dateOfBirth: doctor.dateOfBirth,
        cityId: doctor.cityId,
        clinicId: doctor.clinicId,
        priceTierId: priceTierId,
        isActive: doctor.isActive,
      ),
    );

    await result.fold(
      (failure) async {
        emit(DoctorDetailsActionError(failure.errorMessage));
        emit(DoctorDetailsLoaded(doctor));
      },
      (_) async {
        emit(const DoctorDetailsActionSuccess('تم تحديث الشريحة السعرية'));
        await _refresh();
      },
    );
  }

  /// Takes the doctor off whatever tier they are on.
  ///
  /// Done through the tier rather than through the doctor: `UpdateDoctorRequest`
  /// has no "clear" flag, and a null `priceTierId` there reads as "leave it
  /// alone" — which is why choosing "بلا شريحة" appeared to do nothing.
  /// `PUT /PriceTiers/{id}/doctors` replaces the tier's whole roster, so
  /// resending it without this doctor is an unassignment the API actually
  /// promises.
  Future<void> _detachFromTier() async {
    final doctor = _doctor;
    if (doctor == null) return;

    final tierId = doctor.priceTierId;
    if (tierId == null || tierId.isEmpty) return;

    emit(DoctorDetailsLoaded(doctor, isBusy: true));

    // The roster has to be read first: the endpoint takes the full list, so
    // sending only "everyone except this doctor" means knowing who everyone is.
    final tierResult = await _priceTiersRepo.getPriceTierById(tierId);
    if (isClosed) return;

    final tier = tierResult.fold((_) => null, (value) => value);
    if (tier == null) {
      emit(const DoctorDetailsActionError('تعذّر قراءة أطباء الشريحة الحالية'));
      emit(DoctorDetailsLoaded(doctor));
      return;
    }

    final remaining = [
      for (final assigned in tier.doctors)
        if (assigned.id != doctor.id) assigned.id,
    ];

    final result = await _priceTiersRepo.setPriceTierDoctors(
      id: tierId,
      body: SetPriceTierDoctorsRequestModel(doctorIds: remaining),
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(DoctorDetailsActionError(failure.errorMessage));
        emit(DoctorDetailsLoaded(doctor));
      },
      (_) async {
        emit(
          const DoctorDetailsActionSuccess('تم رفع الشريحة السعرية عن الطبيب'),
        );
        await _refresh();
      },
    );
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
  /// clinic, which the API allows. [zoneId]/[newZoneName] optionally assign
  /// the resolved clinic to a zone the same way — existing or new by name —
  /// left untouched when both are omitted.
  Future<void> approve({
    String? clinicId,
    String? newClinicName,
    String? zoneId,
    String? newZoneName,
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
        zoneId: zoneId,
        newZoneName: newZoneName,
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
