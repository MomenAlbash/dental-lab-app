import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_progress/case_progress_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the case's progress board from `GET /Cases/{id}/flow`.
///
/// One request, where this used to be the stage catalogue plus one route
/// request per restoration type, stitched together here. The stitching was
/// wrong in a way no amount of care could fix from the client: a case travels
/// the plan frozen when it was created, so a lab that edits a route redraws
/// every in-flight case's board — and the parallel steps, the held stages and
/// the production barrier were all being re-derived from a catalogue that
/// never knew about them. The server assembles all of it now, and every node
/// arrives already marked done/current/pending/skipped.
class CaseProgressCubit extends Cubit<CaseProgressState> {
  CaseProgressCubit(this._casesRepo) : super(const CaseProgressInitial());

  final CasesRepo _casesRepo;

  Future<void> load(CaseDetailModel caseDetail) async {
    emit(const CaseProgressLoading());

    final result = await _casesRepo.getCaseFlow(caseDetail.id);
    if (isClosed) return;

    result.fold((failure) => emit(CaseProgressError(failure.errorMessage)), (
      flow,
    ) {
      // Keyed lookup rather than a positional zip: the flow orders pieces by
      // the route it assembled, the detail by how they were entered, and a
      // case with two identical crowns would otherwise pair them wrongly.
      final detailRows = <String, CaseRestorationModel>{
        for (final restoration in caseDetail.restorations)
          restoration.id: restoration,
      };

      emit(
        CaseProgressLoaded(
          caseDetail: caseDetail,
          flow: flow,
          restorations: [
            for (final restoration in flow.restorations)
              RestorationProgress(
                flow: restoration,
                restoration: detailRows[restoration.restorationId],
              ),
          ],
        ),
      );
    });
  }
}
