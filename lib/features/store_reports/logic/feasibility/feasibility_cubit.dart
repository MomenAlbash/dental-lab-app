import 'package:dental_lab_app/features/store_reports/data/repos/store_reports_repo.dart';
import 'package:dental_lab_app/features/store_reports/logic/feasibility/feasibility_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeasibilityCubit extends Cubit<FeasibilityState> {
  FeasibilityCubit(this._storeReportsRepo) : super(const FeasibilityLoading());

  final StoreReportsRepo _storeReportsRepo;

  Future<void> load({int months = 12}) async {
    emit(const FeasibilityLoading());

    final result = await _storeReportsRepo.getStoreFeasibility(months: months);

    result.fold(
      (failure) => emit(FeasibilityError(failure.errorMessage)),
      (feasibility) => emit(FeasibilityLoaded(feasibility, months: months)),
    );
  }
}
