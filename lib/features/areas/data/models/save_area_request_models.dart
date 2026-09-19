/// `ClinicCreateAreaRequest` — `cityId` cannot change after creation (there
/// is no such field on the update request), so it is only ever sent here.
class CreateAreaRequestModel {
  const CreateAreaRequestModel({
    required this.cityId,
    required this.name,
    this.nameAr,
  });

  final String cityId;
  final String name;
  final String? nameAr;

  Map<String, dynamic> toJson() => {
    'cityId': cityId,
    'name': name,
    'nameAr': nameAr,
  };
}

/// `ClinicUpdateAreaRequest`.
class UpdateAreaRequestModel {
  const UpdateAreaRequestModel({this.name, this.nameAr, this.isActive});

  final String? name;
  final String? nameAr;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
    'name': name,
    'nameAr': nameAr,
    'isActive': isActive,
  };
}
