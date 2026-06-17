import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:audiscan/features/auth/presentation/login_screen.dart';
import 'package:audiscan/features/auth/providers/auth_provider.dart';
import '../../helpers/fake_auth_notifier.dart';

Widget construirApp({FakeAuthNotifier? notifier}) {
  final fakeNotifier = notifier ?? FakeAuthNotifier();

  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (_, __) => const Scaffold(body: Text('Registro')),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => fakeNotifier),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('muestra los campos de email, contraseña y botón de login',
        (tester) async {
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('muestra error si el email está vacío', (tester) async {
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      expect(find.text('Ingresá tu email'), findsOneWidget);
    });

    testWidgets('muestra error si el email no tiene arroba', (tester) async {
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'correosinArroba');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('muestra error si la contraseña está vacía', (tester) async {
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'doctor@test.com');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      expect(find.text('Ingresá tu contraseña'), findsOneWidget);
    });

    testWidgets('muestra error si la contraseña tiene menos de 6 caracteres',
        (tester) async {
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'doctor@test.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('el ícono del ojo alterna la visibilidad de la contraseña',
        (tester) async {
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('muestra el error del estado cuando authState tiene error',
        (tester) async {
      final notifier = FakeAuthNotifier(
        estadoInicial: const AuthState(
          isRestoring: false,
          error: 'Credenciales incorrectas',
        ),
      );

      await tester.pumpWidget(construirApp(notifier: notifier));
      await tester.pumpAndSettle();

      expect(find.text('Credenciales incorrectas'), findsOneWidget);
    });
  });
}
