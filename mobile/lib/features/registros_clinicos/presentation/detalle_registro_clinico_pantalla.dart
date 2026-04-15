import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/registro_clinico_modelo.dart';
import '../providers/registros_clinicos_provider.dart';
import '../../pacientes/models/paciente_modelo.dart';
import '../../../core/utils/color_paciente.dart';

class DetalleRegistroClinicoPantalla extends ConsumerWidget {
  final RegistroClinicoModelo registro;
  final PacienteModelo paciente;

  const DetalleRegistroClinicoPantalla({
    super.key,
    required this.registro,
    required this.paciente,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Leer el registro actualizado desde el provider
    final registroActual = ref
        .watch(registrosClinicosProvider(paciente.id))
        .registros
        .where((r) => r.id == registro.id)
        .firstOrNull ?? registro;

    final theme = Theme.of(context);
    final formatoFecha =
        DateFormat("EEEE d 'de' MMMM 'de' yyyy", 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro clínico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => context.push(
              '/registros-clinicos/editar',
              extra: {'registro': registroActual, 'paciente': paciente},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorDePaciente(paciente.nombreCompleto),
                  child: Text(
                    paciente.iniciales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paciente.nombreCompleto,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatoFecha.format(registroActual.fecha),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Campos clínicos ───────────────────────────────────────────
            if (registroActual.anamnesis != null)
              _TarjetaCampo(
                icono: Icons.notes_outlined,
                titulo: 'Anamnesis / Motivo de consulta',
                contenido: registroActual.anamnesis!,
              ),

            if (registroActual.exploracionFisica != null)
              _TarjetaCampo(
                icono: Icons.search_outlined,
                titulo: 'Exploración física',
                contenido: registroActual.exploracionFisica!,
              ),

            if (registroActual.diagnostico != null)
              _TarjetaCampo(
                icono: Icons.medical_information_outlined,
                titulo: 'Diagnóstico',
                contenido: registroActual.diagnostico!,
                destacado: true,
              ),

            if (registroActual.tratamiento != null)
              _TarjetaCampo(
                icono: Icons.medication_outlined,
                titulo: 'Tratamiento / Indicaciones',
                contenido: registroActual.tratamiento!,
              ),

            if (registroActual.observaciones != null)
              _TarjetaCampo(
                icono: Icons.comment_outlined,
                titulo: 'Observaciones',
                contenido: registroActual.observaciones!,
              ),

            if (_todosVacios(registroActual))
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Este registro no tiene contenido aún.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ── Botón imagen timpánica ────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => context.push(
                '/imagenes-timpanicas/capturar',
                extra: {'registro': registroActual, 'paciente': paciente},
              ),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Imagen timpánica + IA'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Botón editar ──────────────────────────────────────────────
            FilledButton.icon(
              onPressed: () => context.push(
                '/registros-clinicos/editar',
                extra: {'registro': registroActual, 'paciente': paciente},
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar registro'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _todosVacios(RegistroClinicoModelo r) =>
      r.anamnesis == null &&
      r.exploracionFisica == null &&
      r.diagnostico == null &&
      r.tratamiento == null &&
      r.observaciones == null;
}

// ─── Tarjeta de campo clínico ─────────────────────────────────────────────────

class _TarjetaCampo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String contenido;
  final bool destacado;

  const _TarjetaCampo({
    required this.icono,
    required this.titulo,
    required this.contenido,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorFondo = destacado
        ? theme.colorScheme.primaryContainer.withOpacity(0.4)
        : theme.colorScheme.surfaceContainerLow;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icono,
                size: 16,
                color: destacado
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                titulo,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: destacado
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contenido,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
