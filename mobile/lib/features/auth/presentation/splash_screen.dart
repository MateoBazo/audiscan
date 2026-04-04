import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha cambios en authProvider y navega cuando isRestoring termina
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isRestoring) {
        if (next.isAuthenticated) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      }
    });

    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hearing, size: 72, color: color),
            const SizedBox(height: 20),
            Text(
              'AudiScan',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}