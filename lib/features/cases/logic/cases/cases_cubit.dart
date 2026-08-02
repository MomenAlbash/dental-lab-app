import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CasesCubit extends Cubit<CasesState> {
  CasesCubit(this._casesRepo) : super(const CasesInitial());

  final CasesRepo _casesRepo;

  String? _search;
  CaseFiltersModel _filters = CaseFiltersModel.empty;

  CaseFiltersModel get filters => _filters;

  Future<void> getCases({String? search}) async {
    if (search != null) _search = search;

    emit(const CasesLoading());

    final result = await _casesRepo.getCases(
      search: _search,
      filters: _filters,
    );

    result.fold(
      (failure) => emit(CasesError(failure.errorMessage)),
      (cases) => emit(CasesLoaded(cases)),
    );
  }

  /// Replaces the active filters and reloads the list.
  Future<void> applyFilters(CaseFiltersModel filters) async {
    _filters = filters;
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
