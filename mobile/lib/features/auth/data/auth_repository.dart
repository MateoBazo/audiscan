import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../../../core/api/api_client.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? licenseNumber,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
        if (licenseNumber != null && licenseNumber.isNotEmpty)
          'license_number': licenseNumber,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // Valida el token guardado y retorna el perfil del usuario
  Future<UserModel> getMe({required String token}) async {
    final response = await _dio.get(
      '/auth/me',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(dioProvider)),
);