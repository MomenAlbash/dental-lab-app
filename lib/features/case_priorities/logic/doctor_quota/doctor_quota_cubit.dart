import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/doctor_quota/doctor_quota_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One doctor's allowances across every priority.
///
/// The mirror of [PriorityAllowanceCubit]: that one takes a priority and hands
/// it to many doctors, this one takes a doctor and shows every priority. Both
/// exist because both are real questions — "who gets five free rushes" and
/// "what does this doctor get" — and answering only the first makes the second
/// a hunt through every priority in turn.
class DoctorQuotaCubit extends Cubit<DoctorQuotaState> {
  DoctorQuotaCubit(this._repo) : super(const DoctorQuotaInitial());

  final CasePrioritiesRepo _repo;

  late String _doctorId;

  /// Kept so a failed write can put the rows back rather than replacing a
  /// working screen with an error.
  DoctorPriorityQuotaModel? _lastLoaded;

  Future<void> load(String doctorId) async {
    _doctorId = doctorId;
    emit(const DoctorQuotaLoading());

    final result = await _repo.getDoctorPriorityQuota(doctorId);
    if (isClosed) return;

    result.fold((failure) => emit(DoctorQuotaError(failure.errorMessage)), (
      quota,
    ) {
      _lastLoaded = quota;
      emit(DoctorQuotaLoaded(quota));
    });
  }

  /// Sets this doctor's allowance for one priority.
  ///
  /// Null in both figures clears the override and puts the doctor back on the
  /// laboratory's default — it is not the same as zero.
  Future<void> setAllowance({
    required String priorityId,
    required int? freePerMonth,
    required double? surchargeAmount,
  }) async {
    final current = state;
    if (current is DoctorQuotaLoaded) emit(current.copyWith(isBusy: true));

    final body = SetPriorityAllowanceRequestModel(
      priorityId: priorityId,
      freePerMonth: freePerMonth,
      surchargeAmount: surchargeAmount,
    );

    final result = await _repo.setDoctorPriorityAllowance(
      doctorId: _doctorId,
      body: body,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(DoctorQuotaMessage(failure.errorMessage, isError: true));
        final last = _lastLoaded;
        if (last != null) emit(DoctorQuotaLoaded(last));
      },
      (quota) {
        _lastLoaded = quota;
        emit(
          DoctorQuotaMessage(
            body.isReset ? 'تم إرجاعه لإعداد المخبر' : 'تم تحديث الحصة',
          ),
        );
        emit(DoctorQuotaLoaded(quota));
      },
    );
  }
}
