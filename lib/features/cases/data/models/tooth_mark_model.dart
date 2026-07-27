/// A marked tooth on a case — used both for display (`ClinicCaseToothMarkDto`)
/// and as a create/update request item (`ClinicToothMarkRequest`).
class ToothMarkModel {
  final int toothNumber;
  final String? description;

  ToothMarkModel({required this.toothNumber, this.description});

  factory ToothMarkModel.fromJson(Map<String, dynamic> json) {
    return ToothMarkModel(
      toothNumber: json['toothNumber'] as int? ?? 0,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'toothNumber': toothNumber, 'description': description};
  }
}
