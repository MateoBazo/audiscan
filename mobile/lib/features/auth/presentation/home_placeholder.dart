import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../../citas/models/cita_modelo.dart';
import '../../citas/providers/citas_provider.dart';

class HomePlaceholder extends ConsumerWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AudiScan'),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo
            Text(
              '¡Bienvenido, ${usuario?.fullName ?? 'Usuario'}!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              usuario?.role == 'doctor'
                  ? 'Médico otorrinolaringólogo'
                  : 'Asistente',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Citas de hoy
            const _SeccionCitasHoy(),
            const SizedBox(height: 32),

            // Módulos
            Text(
              'Módulos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _TarjetaModulo(
              icono: Icons.people_outline,
              titulo: 'Mis Pacientes',
              descripcion: 'Registrar y gestionar pacientes',
              onTap: () => context.go('/pacientes'),
            ),
            const SizedBox(height: 8),
            _TarjetaModuloBadge(
              icono: Icons.calendar_month_outlined,
              titulo: 'Agenda',
              descripcion: 'Consultar y gestionar citas',
              onTap: () => context.go('/citas'),
              badge: ref.watch(citasProvider).citas.where((c) {
                final hoy = DateTime.now();
                final fecha = c.fechaHora.toLocal();
                return fecha.year == hoy.year &&
                    fecha.month == hoy.month &&
                    fecha.day == hoy.day &&
                    c.estado == 'programada';
              }).length,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sección citas de hoy ─────────────────────────────────────────────────────

class _SeccionCitasHoy extends ConsumerWidget {
  const _SeccionCitasHoy();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final estadoCitas = ref.watch(citasProvider);
    final hoy = DateTime.now();

    final citasHoy = estadoCitas.citas.where((c) {
      final fecha = c.fechaHora.toLocal();
      return fecha.year == hoy.year &&
          fecha.month == hoy.month &&
          fecha.day == hoy.day &&
          c.estado == 'programada';
    }).toList()
      ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));

    final citasMostradas = citasHoy.take(3).toList();
    final hayMas = citasHoy.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hoy',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('EEEE d/MM', 'es').format(hoy),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (citasHoy.isNotEmpty)
              TextButton(
                onPressed: () => context.go('/citas'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Ver agenda'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (estadoCitas.cargando)
          _CargandoCitasVista()
        else if (citasHoy.isEmpty)
          _SinCitasHoyVista()
        else ...[
          ...citasMostradas.map((c) => _TarjetaCitaHoy(cita: c)),
          if (hayMas)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${citasHoy.length - 3} citas más',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _TarjetaCitaHoy extends StatelessWidget {
  final CitaModelo cita;

  const _TarjetaCitaHoy({required this.cita});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hora = DateFormat('HH:mm').format(cita.fechaHora.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/citas'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hora,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.nombrePaciente ?? 'Paciente',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cita.motivo != null)
                      Text(
                        cita.motivo!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                '${cita.duracionMinutos} min',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SinCitasHoyVista extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Sin citas programadas para hoy',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CargandoCitasVista extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// ─── Tarjetas de módulo ───────────────────────────────────────────────────────

class _TarjetaModuloBadge extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;
  final int badge;

  const _TarjetaModuloBadge({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Badge(
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          child: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icono, color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(descripcion),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _TarjetaModulo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const _TarjetaModulo({
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icono, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(descripcion),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
