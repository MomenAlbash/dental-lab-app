/// One row in the prices editor: a restoration type and its price within
/// the tier (0 if not priced yet).
class PriceTierPriceItem {
  final String restorationTypeId;
  final String restorationTypeName;
  final double price;

  const PriceTierPriceItem({
    required this.restorationTypeId,
    required this.restorationTypeName,
    required this.price,
  });

  PriceTierPriceItem copyWith({double? price}) {
    return PriceTierPriceItem(
      restorationTypeId: restorationTypeId,
      restorationTypeName: restorationTypeName,
      price: price ?? this.price,
    );
  }
}

sealed class PriceTierPricesState {
  const PriceTierPricesState();
}

class PriceTierPricesInitial extends PriceTierPricesState {
  const PriceTierPricesInitial();
}

class PriceTierPricesLoading extends PriceTierPricesState {
  const PriceTierPricesLoading();
}

class PriceTierPricesLoaded extends PriceTierPricesState {
  const PriceTierPricesLoaded(this.items, {this.isBusy = false});

  final List<PriceTierPriceItem> items;

  /// True while a save is in flight.
  final bool isBusy;
}

class PriceTierPricesError extends PriceTierPricesState {
  const PriceTierPricesError(this.message);
  final String message;
}

/// Transient failure of a save — surfaced as a toast.
class PriceTierPricesActionError extends PriceTierPricesState {
  const PriceTierPricesActionError(this.message);
  final String message;
}

/// Transient success of a save — surfaced as a toast.
class PriceTierPricesActionSuccess extends PriceTierPricesState {
  const PriceTierPricesActionSuccess(this.message);
  final String message;
}
