import 'package:dental_lab_app/features/cities/data/models/city_model.dart';

/*
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "عيادة النور",
  "code": "CL-001",
  "phoneNumber": "0112223344",
  "email": "alnoor@example.com",
  "address": "المزة، دمشق",
  "cityId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "city": { "id": "...", "name": "دمشق" },
  "websiteUrl": "https://alnoor.example.com",
  "logoPath": null,
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-01T00:00:00Z"
}
 */

class ClinicModel {
  final String id;
  final String name;
  final String? code;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? cityId;
  final CityModel? city;
  final String? websiteUrl;
  final String? logoPath;
  final String? createdAt;
  final String? updatedAt;

  ClinicModel({
    required this.id,
    required this.name,
    this.code,
    this.phoneNumber,
    this.email,
    this.address,
    this.cityId,
    this.city,
    this.websiteUrl,
    this.logoPath,
    this.createdAt,
    this.updatedAt,
  });

  /// Convenience accessor for the city name whether it arrives nested under
  /// [city] or only as a bare id.
  String? get cityName => city?.name;

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      cityId: json['cityId'] as String?,
      city: json['city'] == null
          ? null
          : CityModel.fromJson(json['city'] as Map<String, dynamic>),
      websiteUrl: json['websiteUrl'] as String?,
      logoPath: json['logoPath'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'cityId': cityId,
      'city': city?.toJson(),
      'websiteUrl': websiteUrl,
      'logoPath': logoPath,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
