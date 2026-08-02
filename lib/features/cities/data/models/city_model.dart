import 'package:dental_lab_app/features/countries/data/models/country_model.dart';

/*
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "دمشق",
  "countryId": "...",
  "country": { "id": "...", "name": "سوريا" }
}
 */

class CityModel {
  final String id;
  final String? name;
  final String? countryId;
  final CountryModel? country;

  CityModel({required this.id, this.name, this.countryId, this.country});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      countryId: json['countryId'] as String?,
      country: json['country'] == null
          ? null
          : CountryModel.fromJson(json['country'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
