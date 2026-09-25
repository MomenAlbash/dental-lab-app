import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/data/repos/laboratories_repo.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_selection/laboratory_selection_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LaboratorySelectionCubit extends Cubit<LaboratorySelectionState> {
  LaboratorySelectionCubit(this._laboratoriesRepo)
    : super(const LaboratorySelectionInitial());

  final LaboratoriesRepo _laboratoriesRepo;

  List<LaboratoryModel> _laboratories = const [];
  Set<String> _selected = const {};

  /// An account is bound to a single laboratory by default, but an admin (or
  /// a user holding Branches) can reach several — only then is there a
  /// choice, and it may be more than one laboratory at once.
  Future<void> loadLaboratories() async {
    emit(const LaboratorySelectionLoading());

    final result = await _laboratoriesRepo.getLaboratories();
    if (isClosed) return;

    await result.fold(
      // Login already scoped the session to the account's laboratory, so a
      // failure here shouldn't strand the user on this screen.
      (_) async => emit(const LaboratorySelectionSkipped()),
      (laboratories) async {
        if (laboratories.isEmpty) {
          emit(const LaboratorySelectionSkipped());
          return;
        }
        if (laboratories.length == 1) {
          await _confirm(laboratories);
          return;
        }
        _laboratories = laboratories;
        // Coming back to change the scope starts from what is in effect;
        // ids no longer reachable are dropped.
        final reachable = {for (final lab in laboratories) lab.id};
        _selected = {
          for (final id in _laboratoriesRepo.selectedLaboratoryIds)
            if (reachable.contains(id)) id,
        };
        _emitLoaded();
      },
    );
  }

  void toggle(String laboratoryId) {
    final next = Set.of(_selected);
    if (!next.remove(laboratoryId)) next.add(laboratoryId);
    _selected = next;
    _emitLoaded();
  }

  void toggleAll() {
    _selected = _selected.length == _laboratories.length
        ? const {}
        : {for (final lab in _laboratories) lab.id};
    _emitLoaded();
  }

  Future<void> confirm() async {
    final chosen = [
      for (final lab in _laboratories)
        if (_selected.contains(lab.id)) lab,
    ];
    if (chosen.isEmpty) return;
    await _confirm(chosen);
  }

  Future<void> _confirm(List<LaboratoryModel> laboratories) async {
    await _laboratoriesRepo.selectLaboratories(laboratories);
    emit(LaboratorySelectionConfirmed(laboratories));
  }

  void _emitLoaded() =>
      emit(LaboratorySelectionLoaded(_laboratories, _selected));
}
