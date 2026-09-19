import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class PriorityOverviewState {
  const PriorityOverviewState();
}

class PriorityOverviewLoading extends PriorityOverviewState {
  const PriorityOverviewLoading();
}

class PriorityOverviewError extends PriorityOverviewState {
  const PriorityOverviewError(this.message);
  final String message;
}

class PriorityOverviewLoaded extends PriorityOverviewState {
  const PriorityOverviewLoaded(
    this.overview, {
    this.search = '',
    this.isBusy = false,
  });

  final PriorityOverviewModel overview;
  final String search;
  final bool isBusy;

  PriorityOverviewLoaded copyWith({bool? isBusy}) => PriorityOverviewLoaded(
    overview,
    search: search,
    isBusy: isBusy ?? this.isBusy,
  );
}

class PriorityOverviewActionSuccess extends PriorityOverviewState {
  const PriorityOverviewActionSuccess(this.message);
  final String message;
}

class PriorityOverviewActionError extends PriorityOverviewState {
  const PriorityOverviewActionError(this.message);
  final String message;
}

/// Every doctor's rush-priority standing for the current period.
///
/// One query for the whole laboratory rather than a round trip per doctor,
/// which is the difference between a "who has what" screen somebody opens and
/// one nobody does.
class PriorityOverviewCubit extends Cubit<PriorityOverviewState> {
  PriorityOverviewCubit(this._repo) : super(const PriorityOverviewLoading());

  final CasePrioritiesRepo _repo;

  String _search = '';

  String get search => _search;

  Future<void> load({String? search}) async {
    _search = search ?? _search;
    emit(const PriorityOverviewLoading());

    final result = await _repo.getOverview(
      search: _search.isEmpty ? null : _search,
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(PriorityOverviewError(failure.errorMessage)),
      (overview) =>
          emit(PriorityOverviewLoaded(overview, search: _search)),
    );
  }

  /// Bumps one doctor's allowance at one level.
  Future<void> increase({
    required String doctorId,
    required String priorityId,
    required IncreasePriorityAllowanceRequestModel body,
  }) => _write(
    body.isPaid
        ? 'تمت زيادة الحصة وإصدار فاتورة'
        : 'تمت زيادة الحصة وإشعار الطبيب',
    () => _repo.increaseAllowance(
      doctorId: doctorId,
      priorityId: priorityId,
      body: body,
    ),
  );

  /// Writes one level's terms onto a set of doctors.
  ///
  /// Not a replace — doctors outside [body.doctorIds] keep what they had,
  /// which matters because this screen is usually showing a filtered slice.
  Future<void> setAllowances({
    required String priorityId,
    required BulkSetPriorityAllowanceRequestModel body,
  }) => _write(
    body.freePerMonth == null
        ? 'تمت إعادة الأطباء إلى الشروط الافتراضية'
        : 'تم حفظ الحصص',
    () => _repo.setAllowances(priorityId: priorityId, body: body),
  );

  Future<void> _write<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() request,
  ) async {
    final current = state;
    if (current is PriorityOverviewLoaded) {
      emit(current.copyWith(isBusy: true));
    }

    final result = await request();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(PriorityOverviewActionError(failure.errorMessage));
        if (current is PriorityOverviewLoaded) emit(current);
      },
      (_) async {
        emit(PriorityOverviewActionSuccess(successMessage));
        await load();
      },
    );
  }
}
