import 'dart:developer';

import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/auth/data/models/login_request_model.dart';
import 'package:dental_lab_app/features/auth/data/models/login_response_model.dart';

/// The `auth` endpoints — split out of
/// [ApiService], reached through the same instance.
extension AuthApi on ApiService {
  // ---------------------------------------------------------------- auth ---

  Future<LoginResponseModel> userLogin({
    required LoginRequestModel loginRequestBody,
  }) async {
    final body = loginRequestBody.toJson();

    // Never the body: it is the password.
    log('Sending Login request');

    final response = await Api().post(url: 'ClinicAuth/login', body: body);

    // Never the body: it carries the access token.
    log('Login answered ${response.statusCode}');

    return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? token,
  }) async {
    log('Sending Change Password request');

    final response = await Api().post(
      url: 'ClinicAuth/change-password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      token: token,
    );

    log('Change Password answered ${response.statusCode}');
  }


}
