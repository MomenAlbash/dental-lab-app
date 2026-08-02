/// Create payload for a price tier (`CreatePriceTierRequest`).
class CreatePriceTierRequestModel {
  final String? name;
  final String? description;

  CreatePriceTierRequestModel({this.name, this.description});

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description};
  }
}
