/*
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "دمشق"
}
 */

class CityModel {
  final String id;
  final String? name;

  CityModel({required this.id, this.name});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as String,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
