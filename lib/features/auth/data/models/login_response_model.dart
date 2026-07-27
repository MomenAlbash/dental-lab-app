/*
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": "2026-08-24T10:12:33.000Z",
  "user": {
    "id": "94cf4d5a-97f6-4457-b334-82408007ebc6",
    "username": "momen00",
    "email": "momenbash4@gmail.com",
    "isAdmin": true,
    "roleId": null,
    "role": null,
    "employeeId": null,
    "employeeFullName": null,
    "laboratoryId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "laboratory": { ... }
  }
}
 */

import 'package:dental_lab_app/features/auth/data/models/login_data_model.dart';

class LoginResponseModel {
  final String? token;
  final DateTime? expiresAt;
  final LoginData? data;

  LoginResponseModel({this.token, this.expiresAt, this.data});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      data: json['user'] != null
          ? LoginData.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
