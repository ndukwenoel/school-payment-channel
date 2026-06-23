import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String role;
  @JsonKey(name: 'credit_balance')
  final double creditBalance;
  @JsonKey(name: 'auto_pay_enabled')
  final bool autoPayEnabled;

  User({
    required this.id, 
    required this.email, 
    this.fullName, 
    required this.role,
    this.creditBalance = 0.0,
    this.autoPayEnabled = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'user_id')
  final int userId;
  final String role;

  AuthResponse({required this.accessToken, required this.userId, required this.role});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String role;

  RegisterRequest({required this.email, required this.password, required this.fullName, this.role = 'parent'});

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}
