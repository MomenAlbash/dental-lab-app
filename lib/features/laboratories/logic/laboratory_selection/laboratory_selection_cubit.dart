import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/data/repos/laboratories_repo.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_selection/laboratory_selection_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LaboratorySelectionCubit extends Cubit<LaboratorySelectionState> {
  LaboratorySelectionCubit(this._laboratoriesRepo)
    : super(const LaboratorySelectionInitial());

  final LaboratoriesRepo _laboratoriesRepo;

  /// An account is bound to a single laboratory by default, but an admin can
  /// own several. Only in that case does the user get to pick one — otherwise
  /// the single lab is selected automatically.
  Future<void> loadLaboratories() async {
    emit(const LaboratorySelectionLoading());

    final result = await _laboratoriesRepo.getLaboratories();

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
          await selectLaboratory(laboratories.first);
          return;
        }
        emit(
          LaboratorySelectionLoaded(
            laboratories,
            _laboratoriesRepo.activeLaboratoryId,
          ),
        );
      },
    );
  }

  Future<void> selectLaboratory(LaboratoryModel laboratory) async {
    await _laboratoriesRepo.selectLaboratory(laboratory);
    emit(LaboratorySelectionConfirmed(laboratory));
  }
}
