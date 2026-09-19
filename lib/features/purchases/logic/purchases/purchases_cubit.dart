import 'package:dental_lab_app/features/purchases/data/repos/purchases_repo.dart';
import 'package:dental_lab_app/features/purchases/logic/purchases/purchases_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PurchasesCubit extends Cubit<PurchasesState> {
  PurchasesCubit(this._purchasesRepo) : super(const PurchasesInitial());

  final PurchasesRepo _purchasesRepo;

  Future<void> getPurchases({DateTime? from, DateTime? to}) async {
    emit(const PurchasesLoading());

    final result = await _purchasesRepo.getPurchases(from: from, to: to);

    result.fold(
      (failure) => emit(PurchasesError(failure.errorMessage)),
      // Newest first — the same "what just happened" ordering every other
      // history list in the app uses.
      (purchases) => emit(
        PurchasesLoaded(
          [...purchases]..sort((a, b) {
            final aDate = a.purchaseDate;
            final bDate = b.purchaseDate;
            if (aDate == null || bDate == null) return 0;
            return bDate.compareTo(aDate);
          }),
        ),
      ),
    );
  }
}
