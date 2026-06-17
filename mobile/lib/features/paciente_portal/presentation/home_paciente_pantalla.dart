import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/paciente_portal_provider.dart';

class HomePacientePantalla extends ConsumerWidget {
  const HomePacientePantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authProvider).user;
    final estado = ref.watch(pacientePortalProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AudiScan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(pacientePortalProvider.notifier).cargar(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: estado.cargando
          ? const Center(child: CircularProgressIndicator())
          : estado.error != null
              ? _VistaError(
                  mensaje: estado.error!,
                  onReintentar: () =>
                      ref.read(pacientePortalProvider.notifier).cargar(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(pacientePortalProvider.notifier).cargar(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola, ${usuario?.fullName ?? 'Paciente'}!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Este es tu historial clínico personal',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Resumen
                        _TarjetaResumen(
                          registros: estado.registros.length,
                          imagenes: estado.imagenes.length,
                          audiometrias: estado.audiometrias.length,
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Mi información',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _TarjetaNavegacion(
                          icono: Icons.folder_open_outlined,
                          titulo: 'Historial clínico',
                          descripcion:
                              '${estado.registros.length} registro${estado.registros.length != 1 ? 's' : ''}',
                          onTap: () => context.push('/mi-portal/historial'),
                        ),
                        const SizedBox(height: 8),
                        _TarjetaNavegacion(
                          icono: Icons.image_outlined,
                          titulo: 'Imágenes timpánicas',
                          descripcion:
                              '${estado.imagenes.length} imagen${estado.imagenes.length != 1 ? 'es' : ''}',
                          onTap: () => context.push('/mi-portal/imagenes'),
                        ),
                        const SizedBox(height: 8),
                        _TarjetaNavegacion(
                          icono: Icons.hearing_outlined,
                          titulo: 'Audiometrías',
                          descripcion:
                              '${estado.audiometrias.length} sesión${estado.audiometrias.length != 1 ? 'es' : ''}',
                          onTap: () => context.push('/mi-portal/audiometrias'),
                        ),

                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Esta información es solo de referencia. Consultá siempre con tu médico tratante.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  final int registros;
  final int imagenes;
  final int audiometrias;

  const _TarjetaResumen({
    required this.registros,
    required this.imagenes,
    required this.audiometrias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ItemResumen(valor: registros, etiqueta: 'Consultas'),
          _Divisor(),
          _ItemResumen(valor: imagenes, etiqueta: 'Imágenes'),
          _Divisor(),
          _ItemResumen(valor: audiometrias, etiqueta: 'Audiometrías'),
        ],
      ),
    );
  }
}

class _ItemResumen extends StatelessWidget {
  final int valor;
  final String etiqueta;
  const _ItemResumen({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$valor',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          etiqueta,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Divisor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _TarjetaNavegacion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const _TarjetaNavegacion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icono, color: theme.colorScheme.onPrimaryContainer),
        ),
        title:
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(descripcion),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _VistaError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _VistaError({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
