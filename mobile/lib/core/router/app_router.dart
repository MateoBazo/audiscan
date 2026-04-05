import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/home_placeholder.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/citas/models/cita_modelo.dart';
import '../../features/citas/presentation/citas_pantalla.dart';
import '../../features/citas/presentation/registrar_cita_pantalla.dart';
import '../../features/pacientes/models/paciente_modelo.dart';
import '../../features/pacientes/presentation/pacientes_pantalla.dart';
import '../../features/pacientes/presentation/registrar_paciente_pantalla.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // Solo protege rutas — la navegación inicial la maneja SplashScreen
      final authState = ref.read(authProvider);

      if (authState.isRestoring) return '/splash';

      final isAuthenticated = authState.isAuthenticated;
      final isOnSplash = state.matchedLocation == '/splash';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Evitar redirección de splash (lo maneja SplashScreen)
      if (isOnSplash) return null;

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomePlaceholder()),
      GoRoute(
        path: '/pacientes',
        builder: (_, __) => const PacientesPantalla(),
        routes: [
          GoRoute(
            path: 'nuevo',
            builder: (_, __) => const RegistrarPacientePantalla(),
          ),
          GoRoute(
            path: 'editar',
            builder: (context, state) => RegistrarPacientePantalla(
              paciente: state.extra as PacienteModelo?,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/citas',
        builder: (_, __) => const CitasPantalla(),
        routes: [
          GoRoute(
            path: 'nueva',
            builder: (_, __) => const RegistrarCitaPantalla(),
          ),
          GoRoute(
            path: 'editar',
            builder: (context, state) => RegistrarCitaPantalla(
              cita: state.extra as CitaModelo?,
            ),
          ),
        ],
      ),
    ],
  );
});
