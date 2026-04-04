import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/auth_repository.dart';
import '../models/auth_models.dart';
import '../../../core/api/api_client.dart';

// ─── Estado ──────────────────────────────────────────────────────────────────

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isRestoring; // true mientras chequea el token al arrancar
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isRestoring = true, // arranca en true hasta confirmar sesión
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isRestoring,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isRestoring: isRestoring ?? this.isRestoring,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._repository, this._storage) : super(const AuthState()) {
    _restoreSession();
  }

  // Restaura la sesión al arrancar la app
  Future<void> _restoreSession() async {
    final token = await _storage.read(key: kTokenKey);

    if (token == null) {
      // No hay token guardado — ir a login
      state = state.copyWith(isRestoring: false);
      return;
    }

    // Hay token — validarlo contra el backend con GET /auth/me
    try {
      final user = await _repository.getMe(token: token);
      state = state.copyWith(user: user, isRestoring: false);
    } catch (_) {
      // Token inválido o expirado — limpiar y pedir login de nuevo
      await _storage.delete(key: kTokenKey);
      state = state.copyWith(isRestoring: false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.login(email: email, password: password);
      await _storage.write(key: kTokenKey, value: response.accessToken);
      state = state.copyWith(user: response.user, isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Error inesperado');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? licenseNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        licenseNumber: licenseNumber,
      );
      await _storage.write(key: kTokenKey, value: response.accessToken);
      state = state.copyWith(user: response.user, isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Error inesperado');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: kTokenKey);
    state = const AuthState(isRestoring: false);
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data.containsKey('detail')) {
      return data['detail'] as String;
    }
    return 'Error de conexión. Verificá tu red.';
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(secureStorageProvider),
  ),
);