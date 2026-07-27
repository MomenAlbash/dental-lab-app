/*
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "مدير",
  "description": "صلاحيات كاملة",
  "userCount": 3
}
 */

class RoleModel {
  final String id;
  final String? name;
  final String? description;
  final int userCount;

  RoleModel({
    required this.id,
    this.name,
    this.description,
    this.userCount = 0,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      userCount: json['userCount'] as int? ?? 0,
    );
  }
}
