/// `CurrencyDto`.
class CurrencyModel {
  const CurrencyModel({
    required this.id,
    this.name,
    this.code,
    this.symbol,
    this.canDelete = true,
    this.deleteMessage,
  });

  final String id;
  final String? name;
  final String? code;
  final String? symbol;

  /// False once this currency is in use (priced on a restoration type, on a
  /// case, ...) — [deleteMessage] then says why, the same delete-guard
  /// convention as every other lookup entity in the app.
  final bool canDelete;
  final String? deleteMessage;

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      code: json['code'] as String?,
      symbol: json['symbol'] as String?,
      canDelete: json['canDelete'] as bool? ?? true,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }

  /// `1,250.00 ل.س` / `1,250.00 USD` — the symbol when the server sent one,
  /// the code otherwise, never a bare number with nothing beside it.
  String format(double amount) {
    final whole = amount.toStringAsFixed(2);
    final parts = whole.split('.');
    final buffer = StringBuffer();
    final intPart = parts[0];
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    final unit = (symbol?.trim().isNotEmpty ?? false)
        ? symbol!.trim()
        : (code?.trim() ?? '');
    return '$buffer.${parts[1]} $unit'.trim();
  }
}
