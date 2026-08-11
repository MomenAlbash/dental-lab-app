import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CasePrioritiesCubit extends Cubit<CasePrioritiesState> {
  CasePrioritiesCubit(this._repo) : super(const CasePrioritiesInitial());

  final CasePrioritiesRepo _repo;

  /// Set only by the management screen, which has to keep showing a retired
  /// priority so it can be edited back on. Everywhere inside cases — the
  /// form, the list's badges, the filters — reads the active set, so all
  /// three offer the same priorities.
  bool _includeInactive = false;

  Future<void> getCasePriorities({bool includeInactive = false}) async {
    _includeInactive = includeInactive;
    emit(const CasePrioritiesLoading());

    final result = await _repo.getCasePriorities(
      includeInactive: includeInactive,
    );

    result.fold(
      (failure) => emit(CasePrioritiesError(failure.errorMessage)),
      (priorities) => emit(CasePrioritiesLoaded(priorities)),
    );
  }

  Future<void> deleteCasePriority(String id) async {
    final result = await _repo.deleteCasePriority(id);

    await result.fold(
      (failure) async => emit(CasePriorityDeleteError(failure.errorMessage)),
      (_) async {
        emit(const CasePriorityDeleted());
        await getCasePriorities(includeInactive: _includeInactive);
      },
    );
  }

  Future<void> seedDefaults() async {
    final result = await _repo.seedDefaultCasePriorities();

    await result.fold(
      (failure) async => emit(CasePrioritiesSeedError(failure.errorMessage)),
      (_) async {
        emit(const CasePrioritiesSeeded());
        await getCasePriorities(includeInactive: _includeInactive);
      },
    );
  }
}
