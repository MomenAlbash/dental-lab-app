/// A marked tooth on a restoration — used both for display
/// (`ClinicCaseToothMarkDto`) and as a create/update request item
/// (`ClinicToothMarkRequest`).
///
/// [connectedToToothNumber] links this tooth to another tooth on the same
/// restoration to represent a bridge/span: a chain where each tooth points to
/// the tooth selected right before it (`null` means it stands on its own /
/// starts a new span).
///
/// [toothNumber] and [connectedToToothNumber] are always FDI (ISO 3950)
/// throughout the app — the chart is drawn in FDI, and every other read of
/// this field assumes it. The API's `ToothNumber` is the Universal
/// Numbering System (1-32) instead, so the two are converted at the JSON
/// boundary only ([_fdiToUniversal] / [_universalToFdi]); nothing above this
/// file should ever see a Universal number.
class ToothMarkModel {
  final int toothNumber;
  final String? description;
  final int? connectedToToothNumber;

  ToothMarkModel({
    required this.toothNumber,
    this.description,
    this.connectedToToothNumber,
  });

  factory ToothMarkModel.fromJson(Map<String, dynamic> json) {
    return ToothMarkModel(
      toothNumber: _universalToFdi(json['toothNumber'] as int?) ?? 0,
      description: json['description'] as String?,
      connectedToToothNumber: _universalToFdi(
        json['connectedToToothNumber'] as int?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toothNumber': _fdiToUniversal(toothNumber),
      'description': description,
      'connectedToToothNumber': _fdiToUniversal(connectedToToothNumber),
    };
  }

  ToothMarkModel copyWith({
    String? description,
    int? connectedToToothNumber,
    bool clearConnection = false,
  }) {
    return ToothMarkModel(
      toothNumber: toothNumber,
      description: description ?? this.description,
      connectedToToothNumber: clearConnection
          ? null
          : (connectedToToothNumber ?? this.connectedToToothNumber),
    );
  }

  /// FDI quadrant/position (e.g. 38 = lower-left third molar) to Universal
  /// 1-32 (e.g. 17). Overloaded for nullable use on
  /// [connectedToToothNumber].
  static int? _fdiToUniversal(int? fdi) {
    if (fdi == null) return null;
    final quadrant = fdi ~/ 10;
    final position = fdi % 10;
    return switch (quadrant) {
      1 => 9 - position,
      2 => 8 + position,
      3 => 25 - position,
      4 => 24 + position,
      _ => fdi,
    };
  }

  /// The inverse of [_fdiToUniversal].
  static int? _universalToFdi(int? universal) {
    if (universal == null) return null;
    if (universal < 1 || universal > 32) return universal;
    if (universal <= 8) return 10 + (9 - universal);
    if (universal <= 16) return 20 + (universal - 8);
    if (universal <= 24) return 30 + (25 - universal);
    return 40 + (universal - 24);
  }
}
