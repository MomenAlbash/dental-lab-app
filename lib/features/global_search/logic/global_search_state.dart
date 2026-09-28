import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/global_search/data/recent_items_repo.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';

/// One kind of result — cases, patients or doctors. Each is fetched on its
/// own, so one failing never hides the others.
sealed class SearchSection<T> {
  const SearchSection();
}

class SectionIdle<T> extends SearchSection<T> {
  const SectionIdle();
}

class SectionLoading<T> extends SearchSection<T> {
  const SectionLoading();
}

class SectionResults<T> extends SearchSection<T> {
  const SectionResults(this.items, {this.hasMore = false});
  final List<T> items;

  /// More matched than are shown — the user should narrow the query.
  final bool hasMore;
}

class SectionError<T> extends SearchSection<T> {
  const SectionError(this.message);
  final String message;
}

class GlobalSearchState {
  const GlobalSearchState({
    this.query = '',
    this.cases = const SectionIdle(),
    this.patients = const SectionIdle(),
    this.doctors = const SectionIdle(),
    this.recent = const [],
  });

  /// Records opened from the search before, newest first — shown while
  /// nothing is typed.
  final List<RecentItem> recent;

  /// What the results are for — trimmed, as sent.
  final String query;
  final SearchSection<CaseListItemModel> cases;
  final SearchSection<PatientModel> patients;
  final SearchSection<DoctorModel> doctors;

  /// Nothing typed yet, or too little to search on.
  bool get isIdle => cases is SectionIdle;

  /// Every section answered, and none found anything.
  bool get isEmpty => [cases, patients, doctors].every(
    (s) => switch (s) {
      SectionResults(:final items) => items.isEmpty,
      _ => false,
    },
  );

  GlobalSearchState copyWith({
    SearchSection<CaseListItemModel>? cases,
    SearchSection<PatientModel>? patients,
    SearchSection<DoctorModel>? doctors,
    List<RecentItem>? recent,
  }) => GlobalSearchState(
    query: query,
    cases: cases ?? this.cases,
    patients: patients ?? this.patients,
    doctors: doctors ?? this.doctors,
    recent: recent ?? this.recent,
  );
}
