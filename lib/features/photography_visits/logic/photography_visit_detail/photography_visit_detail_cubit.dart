import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:dental_lab_app/features/photography_visits/data/repos/photography_visits_repo.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_detail/photography_visit_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One photography visit and everything that can be done to it: schedule,
/// complete (which bills the doctor), cancel, and manage its photos.
class PhotographyVisitDetailCubit extends Cubit<PhotographyVisitDetailState> {
  PhotographyVisitDetailCubit(
    this._repo,
    this._employeesRepo,
    this._accountingRepo,
  ) : super(const PhotographyVisitDetailLoading());

  final PhotographyVisitsRepo _repo;
  final EmployeesRepo _employeesRepo;
  final AccountingRepo _accountingRepo;

  late String _id;
  PhotographyVisitModel? _visit;
  List<EmployeeModel> _employees = const [];
  List<CurrencyModel> _currencies = const [];

  /// True once something changed the visit, so the list behind this screen
  /// knows to reload when it comes back.
  bool changed = false;

  Future<void> load(String id) async {
    _id = id;
    emit(const PhotographyVisitDetailLoading());

    final result = await _repo.getVisit(id);
    if (isClosed) return;

    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(PhotographyVisitDetailError(failure.errorMessage));
      return;
    }
    _visit = result.fold((_) => null, (v) => v);

    // Only the action sheets need these, so a failure leaves a picker empty
    // rather than hiding the visit.
    final employees = await _employeesRepo.getEmployees();
    final currencies = await _accountingRepo.getCurrencies();
    if (isClosed) return;
    _employees = employees.fold((_) => const [], (list) => list);
    _currencies = currencies.fold((_) => const [], (list) => list);

    _emitLoaded();
  }

  Future<void> schedule(SchedulePhotographyVisitRequestModel body) =>
      _run(() => _repo.schedule(_id, body), 'تمت جدولة الزيارة');

  Future<void> complete(CompletePhotographyVisitRequestModel body) =>
      _run(() => _repo.complete(_id, body), 'اكتملت الزيارة وسُجّل رسمها');

  Future<void> cancel({String? note}) =>
      _run(() => _repo.cancel(_id, note: note), 'أُلغيت الزيارة');

  Future<void> uploadPhotos(List<String> filePaths) async {
    if (filePaths.isEmpty) return;
    await _run(() => _repo.uploadPhotos(_id, filePaths), 'تم رفع الصور');
  }

  /// The delete answers with nothing, so the visit is refetched to show the
  /// photo gone.
  Future<void> deletePhoto(String photoId) => _run(() async {
    final deleted = await _repo.deletePhoto(_id, photoId);
    return deleted.fold(
      (failure) async => Left<Failure, PhotographyVisitModel>(failure),
      (_) => _repo.getVisit(_id),
    );
  }, 'تم حذف الصورة');

  /// Every action answers with the updated visit; it replaces the old one.
  Future<void> _run(
    Future<Either<Failure, PhotographyVisitModel>> Function() action,
    String successMessage,
  ) async {
    if (_visit == null) return;
    _emitLoaded(isBusy: true);

    final result = await action();
    if (isClosed) return;

    result.fold(
      (failure) => emit(PhotographyVisitActionError(failure.errorMessage)),
      (visit) {
        _visit = visit;
        changed = true;
        emit(PhotographyVisitActionSuccess(successMessage));
      },
    );
    _emitLoaded();
  }

  void _emitLoaded({bool isBusy = false}) {
    emit(
      PhotographyVisitDetailLoaded(
        visit: _visit!,
        employees: _employees,
        currencies: _currencies,
        isBusy: isBusy,
      ),
    );
  }
}
