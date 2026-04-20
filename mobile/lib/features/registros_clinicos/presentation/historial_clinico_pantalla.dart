import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/registro_clinico_modelo.dart';
import '../providers/registros_clinicos_provider.dart';
import '../../pacientes/models/paciente_modelo.dart';
import '../../../core/utils/color_paciente.dart';
import '../../../core/widgets/vista_cargando.dart';
import '../../../core/widgets/vista_vacia.dart';
import '../../../core/widgets/vista_error.dart';
import '../../../core/widgets/fondo_dismissible.dart';
import '../../../core/widgets/dialogo_confirmar_eliminacion.dart';

class HistorialClinicoPantalla extends ConsumerWidget {
  final PacienteModelo paciente;

  const HistorialClinicoPantalla({super.key, required this.paciente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(registrosClinicosProvider(paciente.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(paciente.nombreCompleto),
            Text(
              'Historial clínico',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar paciente',
            onPressed: () =>
                context.push('/pacientes/editar', extra: paciente),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Actualizar',
            onPressed: () => ref
                .read(registrosClinicosProvider(paciente.id).notifier)
                .cargar(),
          ),
        ],
      ),
      body: Column(
        children: [
          _HeaderPaciente(paciente: paciente),
          Expanded(child: _Cuerpo(estado: estado, paciente: paciente)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/registros-clinicos/nuevo',
          extra: paciente,
        ),
        icon: const Icon(Icons.add_outlined),
        label: const Text('Nuevo registro'),
      ),
    );
  }
}

// ─── Header con datos del paciente ───────────────────────────────────────────

class _HeaderPaciente extends StatelessWidget {
  final PacienteModelo paciente;

  const _HeaderPaciente({required this.paciente});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partes = <String>[];
    if (paciente.edad != null) partes.add('${paciente.edad} años');
    if (paciente.telefono != null) partes.add(paciente.telefono!);
    if (paciente.emailContacto != null) partes.add(paciente.emailContacto!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colorDePaciente(paciente.nombreCompleto),
            child: Text(
              paciente.iniciales,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (partes.isNotEmpty)
                  Text(
                    partes.join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _Cuerpo extends ConsumerWidget {
  final RegistrosClinicosEstado estado;
  final PacienteModelo paciente;

  const _Cuerpo({required this.estado, required this.paciente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (estado.cargando) return const VistaCargando(alturaItem: 100, cantidadItems: 4);

    if (estado.error != null && estado.registros.isEmpty) {
      return VistaError(
        mensaje: estado.error!,
        onReintentar: () => ref
            .read(registrosClinicosProvider(paciente.id).notifier)
            .cargar(),
      );
    }

    if (estado.registros.isEmpty) {
      return const VistaVacia(
        icono: Icons.folder_open_outlined,
        titulo: 'Sin registros clínicos',
        subtitulo: 'Tocá "Nuevo registro" para agregar uno',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(registrosClinicosProvider(paciente.id).notifier).cargar(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: estado.registros.length,
        itemBuilder: (context, indice) {
          return _TarjetaRegistro(
            registro: estado.registros[indice],
            paciente: paciente,
          );
        },
      ),
    );
  }
}

// ─── Tarjeta de registro clínico ──────────────────────────────────────────────

class _TarjetaRegistro extends ConsumerWidget {
  final RegistroClinicoModelo registro;
  final PacienteModelo paciente;

  const _TarjetaRegistro({
    required this.registro,
    required this.paciente,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formatoFecha = DateFormat('dd/MM/yyyy', 'es');

    return Dismissible(
      key: ValueKey(registro.id),
      direction: DismissDirection.endToStart,
      background: const FondoDismissible(),
      confirmDismiss: (_) => mostrarDialogoConfirmarEliminacion(
        context,
        titulo: 'Eliminar registro',
        contenido:
            '¿Eliminar este registro clínico? Esta acción no se puede deshacer.',
      ),
      onDismissed: (_) {
        ref
            .read(registrosClinicosProvider(paciente.id).notifier)
            .eliminar(registro.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro eliminado'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(
            '/registros-clinicos/detalle',
            extra: {'registro': registro, 'paciente': paciente},
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatoFecha.format(registro.fecha),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (registro.diagnostico != null) ...[
                  const SizedBox(height: 8),
                  _CampoResumen(
                    icono: Icons.medical_information_outlined,
                    etiqueta: 'Diagnóstico',
                    valor: registro.diagnostico!,
                    theme: theme,
                  ),
                ],
                if (registro.anamnesis != null) ...[
                  const SizedBox(height: 6),
                  _CampoResumen(
                    icono: Icons.notes_outlined,
                    etiqueta: 'Motivo',
                    valor: registro.anamnesis!,
                    theme: theme,
                  ),
                ],
                if (registro.tratamiento != null) ...[
                  const SizedBox(height: 6),
                  _CampoResumen(
                    icono: Icons.medication_outlined,
                    etiqueta: 'Tratamiento',
                    valor: registro.tratamiento!,
                    theme: theme,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoResumen extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final ThemeData theme;

  const _CampoResumen({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: theme.textTheme.bodySmall,
              children: [
                TextSpan(
                  text: '$etiqueta: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: valor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
