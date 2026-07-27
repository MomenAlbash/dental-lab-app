class LoginRequestModel {
  final String username;
  final String password;

  LoginRequestModel({required this.username, required this.password});

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) {
    return LoginRequestModel(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }

  LoginRequestModel copyWith({String? username, String? password}) {
    return LoginRequestModel(
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}
