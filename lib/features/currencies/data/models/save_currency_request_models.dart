/// `CreateCurrencyRequest`. [name] and [code] are required.
class CreateCurrencyRequestModel {
  const CreateCurrencyRequestModel({
    required this.name,
    required this.code,
    this.symbol,
  });

  final String name;
  final String code;
  final String? symbol;

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'symbol': symbol,
  };
}

/// `UpdateCurrencyRequest`. Every field optional — only what changed needs
/// sending.
class UpdateCurrencyRequestModel {
  const UpdateCurrencyRequestModel({this.name, this.code, this.symbol});

  final String? name;
  final String? code;
  final String? symbol;

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'symbol': symbol,
  };
}
