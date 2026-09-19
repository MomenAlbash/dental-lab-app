import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/scan_task/scan_task_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Turns a scanned piece into the one question its holder can answer:
/// "this is your stage — done with it?"
///
/// **Eligibility is never computed here.** Which stages a person may work is
/// resolved server-side inside the move call itself, out of the stage's
/// department/user pools, and no endpoint exposes those pools to a client.
/// So the screen offers the move, and a `403` is a first-class outcome
/// meaning "not your stage" — not an error. Guessing locally would disagree
/// with the server the moment a lab edits a department roster, and would also
/// be wrong in the opposite direction: a stage naming nobody at all is open to
/// everyone, so an empty pool must not read as "locked".
class ScanTaskCubit extends Cubit<ScanTaskState> {
  ScanTaskCubit(this._repo) : super(const ScanTaskLoading());

  final CasesRepo _repo;

  Future<void> load({
    required CaseDetailModel caseDetail,
    required String restorationId,
  }) async {
    emit(const ScanTaskLoading());

    final restoration = _restorationIn(caseDetail, restorationId);
    if (restoration == null) {
      // The scan resolved a piece the case response does not list. Nothing
      // useful can be said about a stage that isn't there.
      emit(const ScanTaskError('تعذّر العثور على التعويض ضمن هذه الحالة'));
      return;
    }

    final typeId =
        restoration.restorationTypeId ?? restoration.restorationType?.id;

    var ready = ScanTaskReady(
      caseDetail: caseDetail,
      restoration: restoration,
      currentStage: restoration.currentStage,
      currentStageName: restoration.currentStageName,
    );
    emit(ready);

    // Without a type there is no route to read, so neither the stage's name
    // nor the next step can be resolved. The card still names the piece, and
    // the move stays unavailable rather than aimed at a guess.
    if (typeId == null || typeId.isEmpty) return;

    // The name first, and only when the response did not already carry it: a
    // restricted response omits the expanded `currentStage`, and a stage the
    // screen cannot name is one the user cannot act on with confidence.
    final name = ready.currentStageName;
    if (name == null || name.isEmpty) {
      final route = await _repo.getRestorationRoute(restorationTypeId: typeId);
      if (isClosed) return;

      route.fold((_) {}, (stages) {
        for (final stage in stages) {
          if (stage.id != restoration.currentStageId) continue;
          ready = ready.copyWith(
            currentStage: stage,
            currentStageName: stage.displayName,
          );
          emit(ready);
          break;
        }
      });
    }

    final next = await _repo.getNextRestorationStages(
      restorationTypeId: typeId,
      currentStageId: restoration.currentStageId,
      intake: caseDetail.impressionMethod,
    );
    if (isClosed) return;

    next.fold(
      // A route the client could not read is not a reason to strand the user.
      (_) {},
      (stages) => emit(ready.copyWith(nextStages: stages)),
    );
  }

  /// Attempts the move.
  ///
  /// A `403` becomes [ScanTaskReady.refusal] rather than an error, carrying
  /// the server's own sentence — it already names the stage, which is more
  /// than the client knows. Any other failure is a genuine error.
  Future<void> completeStage({String? note}) async {
    final current = state;
    if (current is! ScanTaskReady) return;
    if (!current.hasNextStep || current.isSubmitting) return;

    emit(current.copyWith(isSubmitting: true, clearRefusal: true));

    // The first of the step: stages sharing an `order` are entered together,
    // and the server lands the piece on the whole step from any one of them.
    final target = current.nextStages.first;

    final result = await _repo.setRestorationStage(
      caseId: current.caseDetail.id,
      restorationId: current.restoration.id,
      stageId: target.id,
      note: note,
    );
    if (isClosed) return;

    result.fold((failure) {
      if (failure.statusCode == 403) {
        emit(
          current.copyWith(isSubmitting: false, refusal: failure.errorMessage),
        );
      } else {
        emit(ScanTaskError(failure.errorMessage));
      }
    }, (_) => emit(current.copyWith(isSubmitting: false, isDone: true)));
  }

  static CaseRestorationModel? _restorationIn(
    CaseDetailModel caseDetail,
    String id,
  ) {
    for (final restoration in caseDetail.restorations) {
      if (restoration.id == id) return restoration;
    }
    return null;
  }
}
