class CreateClinicRequestModel {
  final String name;
  final String? code;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? cityId;
  final String? websiteUrl;

  CreateClinicRequestModel({
    required this.name,
    this.code,
    this.phoneNumber,
    this.email,
    this.address,
    this.cityId,
    this.websiteUrl,
  });

  factory CreateClinicRequestModel.fromJson(Map<String, dynamic> json) {
    return CreateClinicRequestModel(
      name: json['name'] as String,
      code: json['code'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      cityId: json['cityId'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'cityId': cityId,
      'websiteUrl': websiteUrl,
    };
  }

  CreateClinicRequestModel copyWith({
    String? name,
    String? code,
    String? phoneNumber,
    String? email,
    String? address,
    String? cityId,
    String? websiteUrl,
  }) {
    return CreateClinicRequestModel(
      name: name ?? this.name,
      code: code ?? this.code,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      cityId: cityId ?? this.cityId,
      websiteUrl: websiteUrl ?? this.websiteUrl,
    );
  }
}
