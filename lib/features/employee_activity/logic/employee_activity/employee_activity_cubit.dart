import 'package:dental_lab_app/features/employee_activity/data/models/employee_activity_model.dart';
import 'package:dental_lab_app/features/employee_activity/data/repos/employee_activity_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class EmployeeActivityState {
  const EmployeeActivityState();
}

class EmployeeActivityLoading extends EmployeeActivityState {
  const EmployeeActivityLoading();
}

class EmployeeActivityError extends EmployeeActivityState {
  const EmployeeActivityError(this.message);
  final String message;
}

class EmployeeActivityLoaded extends EmployeeActivityState {
  const EmployeeActivityLoaded({
    required this.filters,
    required this.summary,
    this.daily = const [],
    this.timeline,
    this.isLoadingMore = false,
  });

  final EmployeeActivityFiltersModel filters;
  final EmployeeActivitySummaryModel summary;
  final List<EmployeeActivityDailyModel> daily;

  /// Null until the timeline tab is opened. The events are the heaviest of the
  /// three reads and most sessions never leave the summary, so they are not
  /// fetched with it.
  final ActivityTimelineModel? timeline;

  final bool isLoadingMore;

  EmployeeActivityLoaded copyWith({
    EmployeeActivitySummaryModel? summary,
    List<EmployeeActivityDailyModel>? daily,
    ActivityTimelineModel? timeline,
    bool? isLoadingMore,
  }) => EmployeeActivityLoaded(
    filters: filters,
    summary: summary ?? this.summary,
    daily: daily ?? this.daily,
    timeline: timeline ?? this.timeline,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

class EmployeeActivityExported extends EmployeeActivityState {
  const EmployeeActivityExported(this.bytes);
  final List<int> bytes;
}

class EmployeeActivityActionError extends EmployeeActivityState {
  const EmployeeActivityActionError(this.message);
  final String message;
}

/// The team-activity report: a summary, a day-by-employee grid, and the
/// individual events.
///
/// All three read the **same filters** — a summary that covers a different
/// window from the timeline under it is how a report stops being evidence.
class EmployeeActivityCubit extends Cubit<EmployeeActivityState> {
  EmployeeActivityCubit(this._repo) : super(const EmployeeActivityLoading());

  final EmployeeActivityRepo _repo;

  EmployeeActivityFiltersModel _filters = _defaultFilters();

  EmployeeActivityFiltersModel get filters => _filters;

  /// The last 30 days. A report with no window would ask the server for the
  /// laboratory's entire history on first open.
  static EmployeeActivityFiltersModel _defaultFilters() {
    final now = DateTime.now();
    return EmployeeActivityFiltersModel(
      from: DateTime(now.year, now.month, now.day).subtract(
        const Duration(days: 30),
      ),
      to: now,
    );
  }

  /// Loads the summary and the daily grid for [filters], or for the current
  /// ones when omitted.
  Future<void> load({EmployeeActivityFiltersModel? filters}) async {
    // The page resets with the window: page 4 of a query that no longer has
    // four pages is an empty screen the user cannot explain.
    _filters = (filters ?? _filters).copyWith(page: 1);
    emit(const EmployeeActivityLoading());

    final summary = await _repo.getSummary(_filters);
    if (isClosed) return;

    await summary.fold(
      (failure) async => emit(EmployeeActivityError(failure.errorMessage)),
      (value) async {
        final daily = await _repo.getDaily(_filters);
        if (isClosed) return;

        emit(
          EmployeeActivityLoaded(
            filters: _filters,
            summary: value,
            daily: daily.fold((_) => const [], (list) => list),
          ),
        );
      },
    );
  }

  /// Fetches the first page of events. Called when the timeline tab opens.
  Future<void> loadTimeline() async {
    final current = state;
    if (current is! EmployeeActivityLoaded) return;
    if (current.timeline != null) return;

    _filters = _filters.copyWith(page: 1);
    final result = await _repo.getTimeline(_filters);
    if (isClosed) return;

    result.fold(
      (failure) => emit(EmployeeActivityActionError(failure.errorMessage)),
      (timeline) => emit(current.copyWith(timeline: timeline)),
    );
  }

  /// Appends the next page of events.
  Future<void> loadMoreTimeline() async {
    final current = state;
    if (current is! EmployeeActivityLoaded) return;

    final timeline = current.timeline;
    if (timeline == null || !timeline.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    _filters = _filters.copyWith(page: timeline.page + 1);
    final result = await _repo.getTimeline(_filters);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(EmployeeActivityActionError(failure.errorMessage));
        emit(current.copyWith(isLoadingMore: false));
      },
      (next) => emit(
        current.copyWith(
          // Appended, not replaced — and the *new* page's own paging figures
          // are kept, so `hasMore` reflects where the list actually is.
          timeline: ActivityTimelineModel(
            items: [...timeline.items, ...next.items],
            page: next.page,
            pageSize: next.pageSize,
            totalCount: next.totalCount,
            totalPages: next.totalPages,
          ),
          isLoadingMore: false,
        ),
      ),
    );
  }

  /// Exports the report as it is currently filtered.
  Future<void> export() async {
    final current = state;

    final result = await _repo.export(_filters);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(EmployeeActivityActionError(failure.errorMessage));
        if (current is EmployeeActivityLoaded) emit(current);
      },
      (bytes) {
        emit(EmployeeActivityExported(bytes));
        if (current is EmployeeActivityLoaded) emit(current);
      },
    );
  }
}
