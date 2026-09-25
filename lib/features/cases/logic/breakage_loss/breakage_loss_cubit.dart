import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/stage_pay/data/models/stage_pay_models.dart';
import 'package:dental_lab_app/features/stage_pay/data/repos/stage_pay_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class BreakageLossState {
  const BreakageLossState();
}

class BreakageLossLoading extends BreakageLossState {
  const BreakageLossLoading();
}

/// What the breakage would throw away, and who could be responsible.
class BreakageLossReady extends BreakageLossState {
  const BreakageLossReady({this.preview, this.employees = const []});

  /// Null when the preview could not be read — the breakage can still be
  /// recorded, just without the suggested figure.
  final LossPreviewModel? preview;
  final List<EmployeeModel> employees;

  /// People whose stage pay the send-back would redo, first — they are who
  /// the recorder is most likely choosing between.
  List<EmployeeModel> get orderedEmployees {
    final lost = {
      for (final row in preview?.lostEarnings ?? const []) row.employeeId,
    };
    return [
      ...employees.where((e) => lost.contains(e.id)),
      ...employees.where((e) => !lost.contains(e.id)),
    ];
  }
}

/// Loads the breakage section of a send-back: the lost work's value for the
/// chosen target stage (`GET /StagePay/loss-preview`) and the employees.
class BreakageLossCubit extends Cubit<BreakageLossState> {
  BreakageLossCubit(this._stagePayRepo, this._employeesRepo)
    : super(const BreakageLossLoading());

  final StagePayRepo _stagePayRepo;
  final EmployeesRepo _employeesRepo;

  Future<void> load({
    required String caseId,
    required String restorationId,
    required String targetStageId,
  }) async {
    emit(const BreakageLossLoading());

    // Started together, awaited in turn — independent reads.
    final previewRequest = _stagePayRepo.getLossPreview(
      caseId: caseId,
      restorationId: restorationId,
      targetStageId: targetStageId,
    );
    final employeesRequest = _employeesRepo.getEmployees();
    final preview = await previewRequest;
    final employees = await employeesRequest;
    if (isClosed) return;

    // Either half failing still leaves the breakage recordable: the preview
    // is advice, and the picker simply comes up empty.
    emit(
      BreakageLossReady(
        preview: preview.fold((_) => null, (p) => p),
        employees: employees.fold((_) => const [], (list) => list),
      ),
    );
  }
}
