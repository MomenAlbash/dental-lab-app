import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/data/repos/case_stages_repo.dart';
import 'package:dental_lab_app/features/case_stages/logic/case_stages/case_stages_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CaseStagesCubit extends Cubit<CaseStagesState> {
  CaseStagesCubit(this._repo) : super(const CaseStagesInitial());

  final CaseStagesRepo _repo;

  Future<void> getCaseStages() async {
    emit(const CaseStagesLoading());

    final result = await _repo.getCaseStages();

    result.fold(
      (failure) => emit(CaseStagesError(failure.errorMessage)),
      (stages) => emit(CaseStagesLoaded(_sorted(stages))),
    );
  }

  /// Ordered the way the lab drew the workflow: by placement (everything
  /// before production, then everything after), then by the stage's own
  /// `order`. This is presentation order for pickers and filter chips; the
  /// flow itself is `order` within each half.
  List<CaseStageModel> _sorted(List<CaseStageModel> stages) {
    final sorted = [...stages];
    sorted.sort((a, b) {
      // Timing first, then order: the API stopped sending `placement`, so
      // sorting by it compared a constant and left the halves interleaved.
      final byTiming = a.timing.apiValue.compareTo(b.timing.apiValue);
      if (byTiming != 0) return byTiming;
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      return a.displayName.compareTo(b.displayName);
    });
    return sorted;
  }
}
