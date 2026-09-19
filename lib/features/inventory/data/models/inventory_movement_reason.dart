/// `InventoryMovementReason` — why a stock quantity changed.
///
/// [purchase] is never picked by a person: a purchase records its own
/// movement automatically (see `IInventoryService.RecordPurchaseMovementAsync`)
/// the moment `POST /Purchases` lands, and `RecordInventoryMovementRequest`
/// — the manual-entry endpoint — refuses it. [manualReasons] is the set a
/// picker may actually offer.
enum InventoryMovementReason {
  purchase(0, 'شراء'),
  consumption(1, 'استهلاك'),
  adjustmentIncrease(2, 'تصحيح بالزيادة'),
  adjustmentDecrease(3, 'تصحيح بالنقصان');

  const InventoryMovementReason(this.apiValue, this.arabicLabel);

  final int apiValue;
  final String arabicLabel;

  /// Whether this reason adds to stock or takes from it — purely a display
  /// hint (a "+" or "-" beside the quantity); the server is the one that
  /// actually applies the sign.
  bool get isIncrease =>
      this == InventoryMovementReason.purchase ||
      this == InventoryMovementReason.adjustmentIncrease;

  /// What a person recording a manual movement may choose from — never
  /// [purchase].
  static const manualReasons = [
    InventoryMovementReason.consumption,
    InventoryMovementReason.adjustmentIncrease,
    InventoryMovementReason.adjustmentDecrease,
  ];

  static InventoryMovementReason fromApi(int? value) =>
      InventoryMovementReason.values.firstWhere(
        (reason) => reason.apiValue == value,
        orElse: () => InventoryMovementReason.adjustmentIncrease,
      );
}
