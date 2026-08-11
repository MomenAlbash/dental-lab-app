/*
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "سوريا"
}
 */

class CountryModel {
  final String id;
  final String? name;

  CountryModel({required this.id, this.name});

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] as String,
      name: json['name'] as String?,
    );
  }
}
