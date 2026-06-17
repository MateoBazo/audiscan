import 'package:audiscan/features/auth/providers/auth_provider.dart';

class FakeAuthNotifier extends AuthNotifier {
  bool loginRetorna;
  bool registerRetorna;

  FakeAuthNotifier({
    AuthState? estadoInicial,
    this.loginRetorna = true,
    this.registerRetorna = true,
  }) : super.paraTest(estadoInicial ?? const AuthState(isRestoring: false));

  @override
  Future<bool> login({required String email, required String password}) async {
    return loginRetorna;
  }

  @override
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? licenseNumber,
    String? medicoEmail,
  }) async {
    return registerRetorna;
  }

  @override
  Future<void> logout() async {}

  void fijarError(String error) {
    state = state.copyWith(error: error);
  }

  void fijarCargando(bool cargando) {
    state = state.copyWith(isLoading: cargando);
  }
}
