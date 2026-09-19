/// One currency's list price for a restoration type
/// (`SaveRestorationTypePriceRequest`). [currencyId] is required by the API:
/// a restoration type is priced per currency alone — there is no
/// currency-less default price.
class SaveRestorationTypePriceRequestModel {
  const SaveRestorationTypePriceRequestModel({
    required this.currencyId,
    required this.price,
  });

  final String currencyId;
  final double price;

  Map<String, dynamic> toJson() => {'currencyId': currencyId, 'price': price};
}
