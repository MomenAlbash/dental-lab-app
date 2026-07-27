/*
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "مخبر الابتسامة الذهبية",
  "address": "المزة، دمشق",
  "phoneNumber": "0112223344",
  "isActive": true,
  "userCount": 5,
  "doctorCount": 8,
  "caseCount": 142
}
 */

class LaboratoryModel {
  final String id;
  final String? name;
  final String? address;
  final String? phoneNumber;
  final bool isActive;
  final int userCount;
  final int doctorCount;
  final int caseCount;

  LaboratoryModel({
    required this.id,
    this.name,
    this.address,
    this.phoneNumber,
    required this.isActive,
    required this.userCount,
    required this.doctorCount,
    required this.caseCount,
  });

  factory LaboratoryModel.fromJson(Map<String, dynamic> json) {
    return LaboratoryModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      address: json['address'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      userCount: json['userCount'] as int? ?? 0,
      doctorCount: json['doctorCount'] as int? ?? 0,
      caseCount: json['caseCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
      'userCount': userCount,
      'doctorCount': doctorCount,
      'caseCount': caseCount,
    };
  }
}
