import 'package:dental_lab_app/features/purchases/data/models/purchase_model.dart';

sealed class PurchasesState {
  const PurchasesState();
}

class PurchasesInitial extends PurchasesState {
  const PurchasesInitial();
}

class PurchasesLoading extends PurchasesState {
  const PurchasesLoading();
}

class PurchasesLoaded extends PurchasesState {
  const PurchasesLoaded(this.purchases);
  final List<PurchaseModel> purchases;
}

class PurchasesError extends PurchasesState {
  const PurchasesError(this.message);
  final String message;
}
