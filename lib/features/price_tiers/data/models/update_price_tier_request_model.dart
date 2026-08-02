/// Update payload for a price tier — same as create plus [isActive]
/// (`UpdatePriceTierRequest`).
class UpdatePriceTierRequestModel {
  final String? name;
  final String? description;
  final bool? isActive;

  UpdatePriceTierRequestModel({this.name, this.description, this.isActive});

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'isActive': isActive};
  }
}
