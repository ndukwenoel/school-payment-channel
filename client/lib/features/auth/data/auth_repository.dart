import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: LoginRequest(email: email, password: password).toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  Future<User> register(String email, String password, String fullName, String role) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: RegisterRequest(email: email, password: password, fullName: fullName, role: role).toJson(),
      );
      return User.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      return User.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }
}
