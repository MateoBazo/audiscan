import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/cita_modelo.dart';
import '../providers/citas_provider.dart';
import '../../pacientes/providers/pacientes_provider.dart';

const _etiquetasEstado = {
  'programada': 'Programada',
  'completada': 'Completada',
  'cancelada': 'Cancelada',
  'no_asistio': 'No asistió',
};

const _iconosEstado = {
  'programada': Icons.schedule_outlined,
  'completada': Icons.check_circle_outline,
  'cancelada': Icons.cancel_outlined,
  'no_asistio': Icons.person_off_outlined,
};

Color _colorEstado(BuildContext context, String estado) {
  final cs = Theme.of(context).colorScheme;
  return switch (estado) {
    'programada' => cs.primary,
    'completada' => Colors.green.shade600,
    'cancelada' => cs.error,
    'no_asistio' => Colors.orange.shade700,
    _ => cs.outline,
  };
}

class DetalleCitaPantalla extends ConsumerWidget {
  final CitaModelo cita;

  const DetalleCitaPantalla({super.key, required this.cita});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Leer la cita actualizada desde el provider (puede haber cambiado el estado)
    final citaActual = ref
        .watch(citasProvider)
        .citas
        .where((c) => c.id == cita.id)
        .firstOrNull ?? cita;

    final theme = Theme.of(context);
    final formatoFecha = DateFormat("EEEE d 'de' MMMM 'de' yyyy", 'es');
    final formatoHora = DateFormat('HH:mm');
    final color = _colorEstado(context, citaActual.estado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de cita'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => context.push('/citas/editar', extra: citaActual),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Paciente ──────────────────────────────────────────────────
            _SeccionHeader(
              icono: Icons.person_outline,
              titulo: citaActual.nombrePaciente ?? 'Paciente',
              subtitulo: 'Paciente',
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),

            // ── Estado ────────────────────────────────────────────────────
            Row(
              children: [
                Icon(_iconosEstado[citaActual.estado], color: color, size: 20),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _etiquetasEstado[citaActual.estado] ?? citaActual.estado,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Fecha y hora ──────────────────────────────────────────────
            _TarjetaInfo(
              children: [
                _FilaInfo(
                  icono: Icons.calendar_today_outlined,
                  etiqueta: 'Fecha',
                  valor: formatoFecha.format(citaActual.fechaHora.toLocal()),
                ),
                const Divider(height: 24),
                _FilaInfo(
                  icono: Icons.access_time_outlined,
                  etiqueta: 'Hora',
                  valor: formatoHora.format(citaActual.fechaHora.toLocal()),
                ),
                const Divider(height: 24),
                _FilaInfo(
                  icono: Icons.timelapse_outlined,
                  etiqueta: 'Duración',
                  valor: '${citaActual.duracionMinutos} minutos',
                ),
              ],
            ),

            if (citaActual.motivo != null) ...[
              const SizedBox(height: 16),
              _TarjetaInfo(
                children: [
                  _FilaInfo(
                    icono: Icons.medical_information_outlined,
                    etiqueta: 'Motivo',
                    valor: citaActual.motivo!,
                  ),
                ],
              ),
            ],

            if (citaActual.notas != null) ...[
              const SizedBox(height: 16),
              _TarjetaInfo(
                children: [
                  _FilaInfo(
                    icono: Icons.notes_outlined,
                    etiqueta: 'Notas',
                    valor: citaActual.notas!,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // ── Acciones ──────────────────────────────────────────────────
            _BotonAccion(
              icono: Icons.folder_open_outlined,
              etiqueta: 'Ver historial del paciente',
              onTap: () => _irAHistorial(context, ref, citaActual),
            ),
            const SizedBox(height: 8),
            _BotonAccion(
              icono: Icons.edit_outlined,
              etiqueta: 'Editar cita',
              onTap: () => context.push('/citas/editar', extra: citaActual),
            ),
          ],
        ),
      ),
    );
  }

  void _irAHistorial(
      BuildContext context, WidgetRef ref, CitaModelo citaActual) {
    final pacientes = ref.read(pacientesProvider).pacientes;
    final paciente = pacientes
        .where((p) => p.id == citaActual.idPaciente)
        .firstOrNull;

    if (paciente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente no encontrado'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.push('/pacientes/historial', extra: paciente);
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SeccionHeader extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;

  const _SeccionHeader({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icono, color: color, size: 28),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitulo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TarjetaInfo extends StatelessWidget {
  final List<Widget> children;

  const _TarjetaInfo({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _FilaInfo extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _FilaInfo({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(valor, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  const _BotonAccion({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icono, color: theme.colorScheme.primary),
        title: Text(etiqueta),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
