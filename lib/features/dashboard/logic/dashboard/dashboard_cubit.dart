import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/dashboard/data/repos/dashboard_repo.dart';
import 'package:dental_lab_app/features/dashboard/logic/dashboard/dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the home dashboard's eight endpoints.
///
/// Split into two waves on purpose. The counters and the recent cases load the
/// moment the screen opens; the six breakdowns wait until the user scrolls to
/// them. Firing all eight on open would mean eight round trips before the
/// first pixel that matters, most of them for content below the fold that many
/// sessions never reach.
///
/// Within a wave the requests run concurrently — they are independent reads,
/// so awaiting them in sequence would just add up their latencies.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repo) : super(const DashboardState());

  final DashboardRepo _repo;

  /// The counters and recent cases. Safe to call again — it is also the
  /// pull-to-refresh path for the top of the screen.
  Future<void> loadEssentials() async {
    emit(
      state.copyWith(
        summary: const SectionLoading(),
        recentCases: const SectionLoading(),
      ),
    );

    await Future.wait([
      _repo.getSummary().then((r) {
        if (isClosed) return;
        emit(state.copyWith(summary: _toSection(r)));
      }),
      _repo.getRecentCases().then((r) {
        if (isClosed) return;
        emit(state.copyWith(recentCases: _toSection(r)));
      }),
    ]);
  }

  /// The six breakdowns below the fold. Ignored if they have already been
  /// asked for, so a scroll listener can call it freely; [force] is for
  /// pull-to-refresh, which does want them re-fetched.
  Future<void> loadDeferred({bool force = false}) async {
    if (state.deferredRequested && !force) return;

    emit(
      state.copyWith(
        casesByStage: const SectionLoading(),
        casesByPhase: const SectionLoading(),
        caseFlow: const SectionLoading(),
        userCaseWork: const SectionLoading(),
        casesByPriority: const SectionLoading(),
        upcomingDueCases: const SectionLoading(),
        topDoctors: const SectionLoading(),
        revenueByMonth: const SectionLoading(),
        recentActivity: const SectionLoading(),
      ),
    );

    await Future.wait([
      _repo.getCasesByStage().then((r) {
        if (isClosed) return;
        emit(state.copyWith(casesByStage: _toSection(r)));
      }),
      _repo.getCasesByPhase().then((r) {
        if (isClosed) return;
        emit(state.copyWith(casesByPhase: _toSection(r)));
      }),
      _repo.getCaseFlow().then((r) {
        if (isClosed) return;
        emit(state.copyWith(caseFlow: _toSection(r)));
      }),
      _repo.getUserCaseWork().then((r) {
        if (isClosed) return;
        emit(state.copyWith(userCaseWork: _toSection(r)));
      }),
      _repo.getCasesByPriority().then((r) {
        if (isClosed) return;
        emit(state.copyWith(casesByPriority: _toSection(r)));
      }),
      _repo.getUpcomingDueCases().then((r) {
        if (isClosed) return;
        emit(state.copyWith(upcomingDueCases: _toSection(r)));
      }),
      _repo.getTopDoctors().then((r) {
        if (isClosed) return;
        emit(state.copyWith(topDoctors: _toSection(r)));
      }),
      _repo.getRevenueByMonth().then((r) {
        if (isClosed) return;
        emit(state.copyWith(revenueByMonth: _toSection(r)));
      }),
      _repo.getRecentActivity().then((r) {
        if (isClosed) return;
        emit(state.copyWith(recentActivity: _toSection(r)));
      }),
    ]);
  }

  /// Reloads the essentials, plus the deferred half only if it was ever shown
  /// — refreshing must not pull down six sections the user never opened.
  Future<void> refresh() async {
    final alsoDeferred = state.deferredRequested;
    await Future.wait([
      loadEssentials(),
      if (alsoDeferred) loadDeferred(force: true),
    ]);
  }

  static DashboardSection<T> _toSection<T>(Either<Failure, T> result) {
    return result.fold(
      (failure) => SectionError<T>(failure.errorMessage),
      (value) => SectionData<T>(value),
    );
  }
}
