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

  Future<void> setStage({required String stageId, String? note}) async {
    final caseDetail = _case;
    if (caseDetail == null) return;

    emit(CaseDetailsLoaded(caseDetail, isBusy: true));

    final result = await _casesRepo.setStage(
      id: caseDetail.id,
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
