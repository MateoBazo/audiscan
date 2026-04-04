import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class HomePlaceholder extends ConsumerWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AudiScan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hearing, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            Text(
              '¡Bienvenido, ${user?.fullName ?? 'Usuario'}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Rol: ${user?.role == 'doctor' ? 'Médico' : 'Asistente'}'),
          ],
        ),
      ),
    );
  }
}