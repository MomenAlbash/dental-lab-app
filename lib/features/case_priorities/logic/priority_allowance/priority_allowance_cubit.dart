import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/priority_allowance/priority_allowance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Hands one priority's free allowance to a set of doctors.
///
/// The API sets one doctor's allowance per call, so this walks the list.
/// Sequentially and on purpose: firing a hundred writes at once is how a
/// server starts refusing them, and a half-applied allowance is worse than a
/// slow one. Failures are collected rather than aborting the run — stopping at
/// the first would leave the lab unable to tell who was done and who was not.
class PriorityAllowanceCubit extends Cubit<PriorityAllowanceState> {
  PriorityAllowanceCubit(this._repo) : super(const PriorityAllowanceIdle());

  final CasePrioritiesRepo _repo;

  Future<void> apply({
    required String priorityId,
    required List<({String id, String name})> doctors,
    required int? freePerMonth,
    required double? surchargeAmount,
  }) async {
    if (doctors.isEmpty) return;

    final failed = <String>[];
    String? firstError;
    var succeeded = 0;

    emit(PriorityAllowanceApplying(done: 0, total: doctors.length));

    for (var i = 0; i < doctors.length; i++) {
      final doctor = doctors[i];

      final result = await _repo.setDoctorPriorityAllowance(
        doctorId: doctor.id,
        body: SetPriorityAllowanceRequestModel(
          priorityId: priorityId,
          freePerMonth: freePerMonth,
          surchargeAmount: surchargeAmount,
        ),
      );
      if (isClosed) return;

      result.fold((failure) {
        failed.add(doctor.name);
        firstError ??= failure.errorMessage;
      }, (_) => succeeded++);

      emit(PriorityAllowanceApplying(done: i + 1, total: doctors.length));
    }

    emit(
      PriorityAllowanceDone(
        succeeded: succeeded,
        failed: failed,
        firstError: firstError,
      ),
    );
  }

  /// Puts the chosen doctors back on the laboratory's default for this
  /// priority. Null is not zero — see [SetPriorityAllowanceRequestModel].
  Future<void> reset({
    required String priorityId,
    required List<({String id, String name})> doctors,
  }) => apply(
    priorityId: priorityId,
    doctors: doctors,
    freePerMonth: null,
    surchargeAmount: null,
  );
}
