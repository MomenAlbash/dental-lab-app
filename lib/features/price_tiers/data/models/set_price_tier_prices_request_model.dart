/// One restoration type's price within a `SetPriceTierPricesRequest`.
class PriceTierRestorationPriceRequestModel {
  final String restorationTypeId;
  final double price;

  PriceTierRestorationPriceRequestModel({
    required this.restorationTypeId,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {'restorationTypeId': restorationTypeId, 'price': price};
  }
}

/// Full replace of a price tier's restoration prices
/// (`SetPriceTierPricesRequest`). Any restoration type left out loses its
/// price in this tier.
class SetPriceTierPricesRequestModel {
  final List<PriceTierRestorationPriceRequestModel> prices;

  SetPriceTierPricesRequestModel({this.prices = const []});

  Map<String, dynamic> toJson() {
    return {'prices': prices.map((p) => p.toJson()).toList()};
  }
}
