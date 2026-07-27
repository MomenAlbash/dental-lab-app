class UpdateLaboratoryRequestModel {
  final String? name;
  final String? address;
  final String? phoneNumber;
  final bool? isActive;

  UpdateLaboratoryRequestModel({
    this.name,
    this.address,
    this.phoneNumber,
    this.isActive,
  });

  factory UpdateLaboratoryRequestModel.fromJson(Map<String, dynamic> json) {
    return UpdateLaboratoryRequestModel(
      name: json['name'] as String?,
      address: json['address'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isActive: json['isActive'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
    };
  }

  UpdateLaboratoryRequestModel copyWith({
    String? name,
    String? address,
    String? phoneNumber,
    bool? isActive,
  }) {
    return UpdateLaboratoryRequestModel(
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isActive: isActive ?? this.isActive,
    );
  }
}
