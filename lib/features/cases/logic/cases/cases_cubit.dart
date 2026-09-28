import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/cases_page_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CasesCubit extends Cubit<CasesState> {
  CasesCubit(this._casesRepo) : super(const CasesInitial());

  final CasesRepo _casesRepo;

  String? _search;
  CaseFiltersModel _filters = CaseFiltersModel.empty;
  CasePhaseCountsModel _phaseCounts = CasePhaseCountsModel.empty;
  CaseSlaCountsModel _slaCounts = CaseSlaCountsModel.empty;

  /// Rows per request. Small enough that the list opens fast, large enough
  /// that a normal scroll is not a stream of spinners.
  static const pageSize = 30;

  /// Rows per request when every case is wanted at once — see
  /// [loadEverything]. The server's own cap on a page.
  static const _bulkPageSize = 200;

  /// How far [loadEverything] goes before stopping: past this a client-side
  /// schedule is the wrong tool, and the server should filter instead.
  static const _maxBulkPages = 10;

  int _pageSize = pageSize;

  /// The client-side narrowing (city) can leave a whole page empty; the list
  /// looks further rather than stopping, but only this far in one go.
  static const _maxPagesPerFetch = 10;

  List<CaseListItemModel> _cases = const [];
  int _page = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  /// Bumped by every full reload, so a page still in flight from before it
  /// is recognised as stale when it lands.
  int _generation = 0;

  /// True once the list has been narrowed to the stages this login is assigned
  /// — the "my tasks" queue rather than the whole laboratory.
  bool _isMyTasks = false;

  CaseFiltersModel get filters => _filters;
  CasePhaseCountsModel get phaseCounts => _phaseCounts;
  CaseSlaCountsModel get slaCounts => _slaCounts;
  bool get isMyTasks => _isMyTasks;

  /// What the search box is currently narrowing by. Exposed so the box can be
  /// restored after a rebuild rather than silently disagreeing with the list
  /// it is filtering.
  String? get search => _search;

  /// Searches, or clears the search when [term] is empty.
  ///
  /// Empty is a real value here, not "leave alone": clearing the box has to
  /// widen the list again, and `getCases(search: '')` would otherwise be
  /// indistinguishable from not passing one.
  Future<void> setSearch(String term) async {
    final trimmed = term.trim();
    _search = trimmed.isEmpty ? null : trimmed;
    await getCases();
  }

  Future<void> getCases({String? search}) async {
    if (search != null) _search = search;

    _generation++;
    _isLoadingMore = false;
    emit(const CasesLoading());

    // The rows and the two badge sets are one screen, so they are asked for
    // together — but the counts never take the list down with them: a failed
    // badge shows its last value, a failed list is what the user must know
    // about.
    // Started together, awaited in turn: three sequential round-trips would
    // make the tab bar arrive noticeably after the rows it labels.
    final listRequest = _fetchFrom(1);
    final phaseRequest = _casesRepo.getPhaseCounts(
      search: _search,
      filters: _filters,
    );
    final slaRequest = _casesRepo.getSlaCounts(
      search: _search,
      filters: _filters,
    );

    final list = await listRequest;
    final phase = await phaseRequest;
    final sla = await slaRequest;
    if (isClosed) return;

    _phaseCounts = phase.fold((_) => _phaseCounts, (counts) => counts);
    _slaCounts = sla.fold((_) => _slaCounts, (counts) => counts);

    list.fold((failure) => emit(CasesError(failure.errorMessage)), (page) {
      _cases = page.items;
      _page = page.lastPage;
      _hasMore = page.hasMore;
      _emitLoaded();
    });
  }

  /// Every case, not a page — for a view that sorts or groups the whole list
  /// itself (the due-date schedule), where a first page would silently leave
  /// out whatever sorted after it. Fetched in large pages, up to a cap.
  Future<void> loadEverything() async {
    _pageSize = _bulkPageSize;
    await getCases();
    var pages = 1;
    while (_hasMore && pages < _maxBulkPages && !isClosed) {
      await loadMore();
      pages++;
    }
  }

  /// Appends the next page. Ignored while one is already coming, when there
  /// is nothing more, or before the first page has arrived.
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state is! CasesLoaded) return;

    _isLoadingMore = true;
    _emitLoaded();

    final generation = _generation;
    final result = await _fetchFrom(_page + 1);
    // The list was reloaded meanwhile (a filter, a tab): this page belongs
    // to the old one and must not be appended to the new.
    if (isClosed || generation != _generation) return;
    _isLoadingMore = false;

    result.fold(
      // The rows already shown stay; scrolling to the end again retries.
      (_) => _emitLoaded(),
      (page) {
        // A case created or moved between two requests can shift into the
        // next page — never show it twice.
        final shown = {for (final c in _cases) c.id};
        _cases = [..._cases, ...page.items.where((c) => !shown.contains(c.id))];
        _page = page.lastPage;
        _hasMore = page.hasMore;
        _emitLoaded();
      },
    );
  }

  /// Fetches from [firstPage] on until a page has rows left after the
  /// client-side narrowing, or the list ends.
  Future<
    Either<
      Failure,
      ({List<CaseListItemModel> items, int lastPage, bool hasMore})
    >
  >
  _fetchFrom(int firstPage) async {
    var page = firstPage;
    while (true) {
      final result = await _casesRepo.getCasesPage(
        search: _search,
        filters: _filters,
        page: page,
        pageSize: _pageSize,
      );
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) return left(failure);

      final fetched = result.getOrElse(() => const CasesPageModel());
      final keepLooking =
          fetched.items.isEmpty &&
          fetched.hasMore &&
          page - firstPage + 1 < _maxPagesPerFetch;
      if (!keepLooking) {
        return right((
          items: fetched.items,
          lastPage: page,
          hasMore: fetched.hasMore,
        ));
      }
      page++;
    }
  }

  void _emitLoaded() => emit(
    CasesLoaded(
      _cases,
      phaseCounts: _phaseCounts,
      slaCounts: _slaCounts,
      filters: _filters,
      isMyTasks: _isMyTasks,
      hasMore: _hasMore,
      isLoadingMore: _isLoadingMore,
    ),
  );

  /// Replaces the active filters and reloads the list.
  Future<void> applyFilters(CaseFiltersModel filters) async {
    _filters = filters;
    await getCases();
  }

  /// Switches the lifecycle tab. Its own entry point rather than going through
  /// [applyFilters] so the tab bar cannot accidentally drop the sheet's
  /// filters on its way past.
  Future<void> setPhaseTab(CasePhaseTab tab) async {
    if (_filters.phaseTab == tab) return;
    _filters = _filters.copyWith(phaseTab: tab);
    await getCases();
  }

  /// Selects — or, when [filter] is already on, clears — the date segment.
  Future<void> toggleSlaFilter(CaseSlaFilter filter) async {
    final next = _filters.sla == filter ? CaseSlaFilter.none : filter;
    _filters = _filters.copyWith(sla: next);
    await getCases();
  }

  /// Narrows to the stages this login is assigned, or widens back to the whole
  /// laboratory.
  ///
  /// The assignment lists are fetched, never derived: they are the union of
  /// being named personally and belonging to a department the stage lists,
  /// through the employee's active membership — none of which the client
  /// holds. An empty answer means nothing is assigned, and the queue says so
  /// rather than falling back to every case in the lab.
  Future<void> setMyTasks(bool enabled) async {
    if (_isMyTasks == enabled) return;

    if (!enabled) {
      _isMyTasks = false;
      _filters = _filters.copyWith(
        clearStages: true,
        clearRestorationStages: true,
      );
      await getCases();
      return;
    }

    emit(const CasesLoading());

    final result = await _casesRepo.getMyWorkflowAssignments();
    if (isClosed) return;

    await result.fold(
      (failure) async => emit(CasesError(failure.errorMessage)),
      (assignments) async {
        if (assignments.isEmpty) {
          _isMyTasks = true;
          emit(const CasesNoAssignments());
          return;
        }

        _isMyTasks = true;
        // An admin acts on every stage, so "my tasks" is the whole list — no
        // stage filter at all rather than an empty one.
        _filters = assignments.allStages
            ? _filters.copyWith(clearStages: true, clearRestorationStages: true)
            : _filters.copyWith(
                stageIds: assignments.caseStageIds.toSet(),
                restorationStageIds: assignments.restorationStageIds.toSet(),
                overriddenRestorationIds: assignments
                    .overriddenCaseRestorationIds
                    .toSet(),
                matchAnyAssignedStage: true,
              );
        await getCases();
      },
    );
  }

  /// "تم التسليم" for the selected cases: each is walked through every
  /// remaining step of its route. The per-case outcome is announced, then the
  /// list reloads — the delivered ones have left whatever tab they were on.
  Future<void> deliverDirectly(List<String> caseIds, {String? note}) async {
    if (caseIds.isEmpty) return;
    emit(const CasesLoading());

    final result = await _casesRepo.deliverDirectly(
      caseIds: caseIds,
      note: note,
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(CasesDeliverDirectlyError(failure.errorMessage)),
      (results) => emit(CasesDeliveredDirectly(results)),
    );
    await getCases();
  }

  Future<void> deleteCase(String id) async {
    final result = await _casesRepo.deleteCase(id);

    await result.fold(
      (failure) async => emit(CaseDeleteError(failure.errorMessage)),
      (_) async {
        emit(const CaseDeleted());
        await getCases();
      },
    );
  }
}
