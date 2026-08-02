/// A marked tooth on a restoration — used both for display
/// (`ClinicCaseToothMarkDto`) and as a create/update request item
/// (`ClinicToothMarkRequest`).
///
/// [connectedToToothNumber] links this tooth to another tooth on the same
/// restoration to represent a bridge/span: a chain where each tooth points to
/// the tooth selected right before it (`null` means it stands on its own /
/// starts a new span).
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
      toothNumber: json['toothNumber'] as int? ?? 0,
      description: json['description'] as String?,
      connectedToToothNumber: json['connectedToToothNumber'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toothNumber': toothNumber,
      'description': description,
      'connectedToToothNumber': connectedToToothNumber,
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
}
