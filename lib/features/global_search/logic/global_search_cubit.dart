import 'dart:async';

import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/global_search/data/recent_items_repo.dart';
import 'package:dental_lab_app/features/global_search/logic/global_search_state.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One box that finds a case, a patient or a doctor — all three searched on
/// the server at once, each shown as it arrives.
class GlobalSearchCubit extends Cubit<GlobalSearchState> {
  GlobalSearchCubit(
    this._casesRepo,
    this._patientsRepo,
    this._doctorsRepo,
    this._recentRepo, {
    this.debounce = const Duration(milliseconds: 350),
  }) : super(const GlobalSearchState());

  final CasesRepo _casesRepo;
  final PatientsRepo _patientsRepo;
  final DoctorsRepo _doctorsRepo;
  final RecentItemsRepo _recentRepo;

  /// Shows what was opened before, while nothing is typed.
  void loadRecent() => emit(state.copyWith(recent: _recentRepo.load()));

  /// Records a result the user opened, so it is one tap away next time.
  Future<void> remember(RecentItem item) async {
    final recent = await _recentRepo.remember(item);
    if (!isClosed) emit(state.copyWith(recent: recent));
  }

  Future<void> clearRecent() async {
    await _recentRepo.clear();
    if (!isClosed) emit(state.copyWith(recent: const []));
  }

  /// How long typing must pause before a search goes out — one request per
  /// thought, not per keystroke.
  final Duration debounce;

  /// A single letter matches half the laboratory.
  static const minLength = 2;

  /// Rows shown per section: this is for finding one record, not browsing.
  static const perSection = 5;

  Timer? _timer;

  /// Bumped per search, so a slow answer to an older query is dropped rather
  /// than overwriting the results for what is typed now.
  int _generation = 0;

  /// Called on every keystroke; searches once typing pauses.
  void onQueryChanged(String text) {
    _timer?.cancel();
    final query = text.trim();
    if (query.length < minLength) {
      _generation++;
      emit(GlobalSearchState(recent: state.recent));
      return;
    }
    _timer = Timer(debounce, () => search(query));
  }

  Future<void> search(String query) async {
    final generation = ++_generation;
    emit(
      GlobalSearchState(
        query: query,
        cases: const SectionLoading(),
        patients: const SectionLoading(),
        doctors: const SectionLoading(),
        recent: state.recent,
      ),
    );

    bool current() => !isClosed && generation == _generation;

    await Future.wait([
      _casesRepo.getCasesPage(search: query, pageSize: perSection).then((
        result,
      ) {
        if (!current()) return;
        emit(
          state.copyWith(
            cases: result.fold(
              (f) => SectionError(f.errorMessage),
              (page) => SectionResults(page.items, hasMore: page.hasMore),
            ),
          ),
        );
      }),
      _patientsRepo.getPatients(search: query).then((result) {
        if (!current()) return;
        emit(
          state.copyWith(
            patients: result.fold(
              (f) => SectionError(f.errorMessage),
              (list) => SectionResults(
                list.take(perSection).toList(),
                hasMore: list.length > perSection,
              ),
            ),
          ),
        );
      }),
      _doctorsRepo.searchDoctors(query).then((result) {
        if (!current()) return;
        emit(
          state.copyWith(
            doctors: result.fold(
              (f) => SectionError(f.errorMessage),
              (list) => SectionResults(
                list.take(perSection).toList(),
                hasMore: list.length > perSection,
              ),
            ),
          ),
        );
      }),
    ]);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
