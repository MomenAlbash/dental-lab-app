import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CaseDetailsCubit extends Cubit<CaseDetailsState> {
  CaseDetailsCubit(this._casesRepo) : super(const CaseDetailsInitial());

  final CasesRepo _casesRepo;

  CaseDetailModel? _case;

  Future<void> getCase(String id) async {
    emit(const CaseDetailsLoading());

    final result = await _casesRepo.getCaseById(id);

    result.fold((failure) => emit(CaseDetailsError(failure.errorMessage)), (
      caseDetail,
    ) {
      _case = caseDetail;
      emit(CaseDetailsLoaded(caseDetail));
    });
  }

  /// Sets the stage of one restoration on the loaded case.
  Future<void> setRestorationStage({
    required String restorationId,
    required String stageId,
    String? note,
  }) async {
    final caseDetail = _case;
    if (caseDetail == null) return;

    emit(CaseDetailsLoaded(caseDetail, isBusy: true));

    final result = await _casesRepo.setRestorationStage(
      caseId: caseDetail.id,
      restorationId: restorationId,
      stageId: stageId,
      note: note,
    );

    await result.fold(
      (failure) async {
        emit(CaseDetailsActionError(failure.errorMessage));
        emit(CaseDetailsLoaded(caseDetail));
      },
      (_) async {
        emit(const CaseDetailsActionSuccess('تم تغيير المرحلة'));
        await _refresh();
      },
    );
  }

  /// Moves the case along its own workflow — distinct from a restoration's
  /// route. [toStageId] is a stage the lab declared, not an enum member.

  /// The fixed lifecycle checkpoints. Each is its own call — none of them is a
  /// stage move — and each refetches the case, because passing one changes
  /// what the case may do next.
  Future<void> receiveMaterial({String? note}) => _runPhaseAction(
    'تم تسجيل استلام العمل',
    (id) => _casesRepo.receiveMaterial(id: id, note: note),
  );

  Future<void> passQualityCheck({String? note}) => _runPhaseAction(
    'تم اجتياز فحص الجودة',
    (id) => _casesRepo.passQualityCheck(id: id, note: note),
  );

  /// Walks a wrongly-recorded arrival back to `New`. The front desk records
  /// arrivals against the wrong case sometimes, and without this the case is
  /// stuck in a phase nothing else can leave.
  Future<void> undoMaterialReceived() => _runPhaseAction(
    'تم التراجع عن تسجيل الاستلام',
    (id) => _casesRepo.undoMaterialReceived(id: id),
  );

  Future<void> approveTrying({String? note}) => _runPhaseAction(
    'تم قبول التجربة',
    (id) => _casesRepo.approveTrying(id: id, note: note),
  );

  /// The doctor refused the fit: the flagged pieces go back to the stage each
  /// one names, and the case drops back into production — one call, because
  /// the server records it as one decision.
  Future<void> rejectTrying({
    required List<({String restorationId, String stageId, String? note})>
    restorations,
    String? note,
  }) => _runPhaseAction(
    'تم تسجيل رفض التجربة',
    (id) => _casesRepo.rejectTrying(
      id: id,
      restorations: restorations,
      note: note,
    ),
  );

  /// Declines a proposed move for one piece: it stays where it is, and the
  /// refusal is written to its history. Not the same act as sending it back —
  /// that is [setRestorationStage] onto a rework target.
  Future<void> rejectRestorationStage({
    required String restorationId,
    required String attemptedStageId,
    required String reason,
  }) => _runPhaseAction(
    'تم رفض النقل',
    (id) => _casesRepo.rejectRestorationStage(
      caseId: id,
      restorationId: restorationId,
      attemptedStageId: attemptedStageId,
      reason: reason,
    ),
  );

  Future<void> setDelayReason({required String reason, String? note}) =>
      _runPhaseAction(
        'تم تسجيل سبب التأخير',
        (id) => _casesRepo.setDelayReason(id: id, reason: reason, note: note),
      );

  Future<void> _runPhaseAction(
    String successMessage,
    Future<Either<Failure, void>> Function(String id) action,
  ) async {
    final caseDetail = _case;
    if (caseDetail == null) return;

    emit(CaseDetailsLoaded(caseDetail, isBusy: true));

    final result = await action(caseDetail.id);
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(CaseDetailsActionError(failure.errorMessage));
        emit(CaseDetailsLoaded(caseDetail));
      },
      (_) async {
        emit(CaseDetailsActionSuccess(successMessage));
        await getCase(caseDetail.id);
      },
    );
  }

  Future<void> moveStage({
    required String toStageId,
    String? note,
    String? rejectionReason,
  }) async {
    final caseDetail = _case;
    if (caseDetail == null) return;

    emit(CaseDetailsLoaded(caseDetail, isBusy: true));

    final result = await _casesRepo.moveCaseStage(
      id: caseDetail.id,
      toStageId: toStageId,
      note: note,
      rejectionReason: rejectionReason,
    );

    await result.fold(
      (failure) async {
        emit(CaseDetailsActionError(failure.errorMessage));
        emit(CaseDetailsLoaded(caseDetail));
      },
      (_) async {
        emit(const CaseDetailsActionSuccess('تم نقل الحالة'));
        await _refresh();
      },
    );
  }

  Future<void> uploadFile(String filePath) async {
    final caseDetail = _case;
    if (caseDetail == null) return;

    emit(CaseDetailsLoaded(caseDetail, isBusy: true));

    final result = await _casesRepo.uploadFile(
      id: caseDetail.id,
      filePath: filePath,
    );

    await result.fold(
      (failure) async {
        emit(CaseDetailsActionError(failure.errorMessage));
        emit(CaseDetailsLoaded(caseDetail));
      },
      (_) async {
        emit(const CaseDetailsActionSuccess('تمت إضافة الملف'));
        await _refresh();
      },
    );
  }

  Future<void> deleteFile(String fileId) async {
    final caseDetail = _case;
    if (caseDetail == null) return;

    emit(CaseDetailsLoaded(caseDetail, isBusy: true));

    final result = await _casesRepo.deleteFile(
      id: caseDetail.id,
      fileId: fileId,
    );

    await result.fold(
      (failure) async {
        emit(CaseDetailsActionError(failure.errorMessage));
        emit(CaseDetailsLoaded(caseDetail));
      },
      (_) async {
        emit(const CaseDetailsActionSuccess('تم حذف الملف'));
        await _refresh();
      },
    );
  }

  Future<void> _refresh() async {
    final caseDetail = _case;
    if (caseDetail == null) return;

    final result = await _casesRepo.getCaseById(caseDetail.id);

    result.fold((_) => emit(CaseDetailsLoaded(caseDetail)), (refreshed) {
      _case = refreshed;
      emit(CaseDetailsLoaded(refreshed));
    });
  }
}
