class CreateLaboratoryRequestModel {
  final String name;
  final String? address;
  final String? phoneNumber;

  CreateLaboratoryRequestModel({
    required this.name,
    this.address,
    this.phoneNumber,
  });

  factory CreateLaboratoryRequestModel.fromJson(Map<String, dynamic> json) {
    return CreateLaboratoryRequestModel(
      name: json['name'] as String,
      address: json['address'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'address': address, 'phoneNumber': phoneNumber};
  }

  CreateLaboratoryRequestModel copyWith({
    String? name,
    String? address,
    String? phoneNumber,
  }) {
    return CreateLaboratoryRequestModel(
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
