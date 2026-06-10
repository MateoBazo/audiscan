import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/registro_clinico_modelo.dart';
import '../providers/registros_clinicos_provider.dart';
import '../../pacientes/models/paciente_modelo.dart';
import '../../imagenes_timpanicas/models/imagen_timpanica_modelo.dart';
import '../../imagenes_timpanicas/providers/imagenes_timpanicas_provider.dart';
import '../../audiometria/models/audiometria_modelo.dart';
import '../../audiometria/providers/audiometria_provider.dart';
import '../../reports/presentation/visor_pdf_pantalla.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/color_paciente.dart';
import '../../../core/widgets/dialogo_confirmar_eliminacion.dart';
import '../../../core/widgets/encabezado_seccion.dart';
import '../../../core/widgets/fondo_dismissible.dart';

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
    final registroActual = ref
            .watch(registrosClinicosProvider(paciente.id))
            .registros
            .where((r) => r.id == registro.id)
            .firstOrNull ??
        registro;

    final estadoImagenes =
        ref.watch(imagenesTimpanicasProvider(registroActual.id));
    final estadoAudiometria =
        ref.watch(audiometriaProvider(registroActual.id));

    final theme = Theme.of(context);
    final formatoFecha = DateFormat("EEEE d 'de' MMMM 'de' yyyy", 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro clínico'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/pacientes/historial', extra: paciente),
        ),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Este registro no tiene contenido aún.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // ── Sección: Imágenes timpánicas ──────────────────────────────
            const EncabezadoSeccion(titulo: 'Imágenes timpánicas'),
            const SizedBox(height: 12),
            _SeccionImagenes(
              estado: estadoImagenes,
              registro: registroActual,
              paciente: paciente,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(
                '/imagenes-timpanicas/capturar',
                extra: {'registro': registroActual, 'paciente': paciente},
              ),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Nueva imagen + IA'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Sección: Audiometrías ─────────────────────────────────────
            const EncabezadoSeccion(titulo: 'Audiometrías'),
            const SizedBox(height: 12),
            _SeccionAudiometrias(
              estado: estadoAudiometria,
              registro: registroActual,
              paciente: paciente,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(
                '/audiometria/registrar',
                extra: {'registro': registroActual, 'paciente': paciente},
              ),
              icon: const Icon(Icons.hearing_outlined),
              label: const Text('Nueva audiometría + IA'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Botón PDF ─────────────────────────────────────────────────
            _BotonGenerarPdf(registro: registroActual, paciente: paciente),

            const SizedBox(height: 10),

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

            const SizedBox(height: 16),
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

// ─── Sección historial de imágenes timpánicas ─────────────────────────────────

class _SeccionImagenes extends ConsumerWidget {
  final ImagenesTimpanicasEstado estado;
  final RegistroClinicoModelo registro;
  final PacienteModelo paciente;

  const _SeccionImagenes({
    required this.estado,
    required this.registro,
    required this.paciente,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (estado.cargando) return const _CargandoInline();
    if (estado.imagenes.isEmpty) {
      return _TextoVacio('Sin imágenes timpánicas registradas.');
    }
    return Column(
      children: estado.imagenes.map((img) {
        return Dismissible(
          key: ValueKey(img.id),
          direction: DismissDirection.endToStart,
          background: const FondoDismissible(),
          confirmDismiss: (_) => mostrarDialogoConfirmarEliminacion(
            context,
            titulo: 'Eliminar imagen',
            contenido:
                '¿Eliminar esta imagen timpánica y su análisis IA? Esta acción no se puede deshacer.',
          ),
          onDismissed: (_) async {
            final exito = await ref
                .read(imagenesTimpanicasProvider(registro.id).notifier)
                .eliminar(img.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(exito
                      ? 'Imagen eliminada'
                      : 'Error al eliminar imagen'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: exito
                      ? null
                      : Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          child: _TarjetaImagen(
            imagen: img,
            registro: registro,
            paciente: paciente,
          ),
        );
      }).toList(),
    );
  }
}

class _TarjetaImagen extends StatelessWidget {
  final ImagenTimpanicaModelo imagen;
  final RegistroClinicoModelo registro;
  final PacienteModelo paciente;

  const _TarjetaImagen({
    required this.imagen,
    required this.registro,
    required this.paciente,
  });

  Color _colorPrediccion(String prediccion) {
    switch (prediccion) {
      case 'normal':
        return Colors.green.shade600;
      case 'otitis_aguda':
        return Colors.red.shade600;
      case 'otitis_cronica':
        return Colors.orange.shade700;
      case 'cerumen':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analisis = imagen.analisis;
    final formato = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '/imagenes-timpanicas/resultado',
          extra: {
            'imagen': imagen,
            'registro': registro,
            'paciente': paciente,
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Miniatura
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imagen.rutaImagen,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: theme.colorScheme.surfaceContainerLow,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 24,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            imagen.etiquetaOido,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        if (analisis != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _colorPrediccion(analisis.prediccion)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              analisis.etiqueta,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    _colorPrediccion(analisis.prediccion),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (analisis != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Confianza: ${(analisis.confianza * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      imagen.capturadoEn != null
                          ? formato.format(imagen.capturadoEn!.toLocal())
                          : 'Fecha no disponible',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sección historial de audiometrías ────────────────────────────────────────

class _SeccionAudiometrias extends ConsumerWidget {
  final AudiometriaEstado estado;
  final RegistroClinicoModelo registro;
  final PacienteModelo paciente;

  const _SeccionAudiometrias({
    required this.estado,
    required this.registro,
    required this.paciente,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (estado.cargando) return const _CargandoInline();
    if (estado.sesiones.isEmpty) {
      return _TextoVacio('Sin audiometrías registradas.');
    }
    return Column(
      children: estado.sesiones.map((s) {
        return Dismissible(
          key: ValueKey(s.id),
          direction: DismissDirection.endToStart,
          background: const FondoDismissible(),
          confirmDismiss: (_) => mostrarDialogoConfirmarEliminacion(
            context,
            titulo: 'Eliminar audiometría',
            contenido:
                '¿Eliminar esta sesión de audiometría y su análisis IA? Esta acción no se puede deshacer.',
          ),
          onDismissed: (_) async {
            final exito = await ref
                .read(audiometriaProvider(registro.id).notifier)
                .eliminar(s.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(exito
                      ? 'Audiometría eliminada'
                      : 'Error al eliminar audiometría'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: exito
                      ? null
                      : Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          child: _TarjetaAudiometria(
            sesion: s,
            registro: registro,
            paciente: paciente,
          ),
        );
      }).toList(),
    );
  }
}

class _TarjetaAudiometria extends StatelessWidget {
  final SesionAudiometriaModelo sesion;
  final RegistroClinicoModelo registro;
  final PacienteModelo paciente;

  const _TarjetaAudiometria({
    required this.sesion,
    required this.registro,
    required this.paciente,
  });

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'normal':
        return Colors.green.shade600;
      case 'conductiva':
        return Colors.orange.shade700;
      case 'sensorioneural':
        return Colors.blue.shade700;
      case 'mixta':
        return Colors.purple.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analisis = sesion.analisis;
    final formato = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '/audiometria/resultado',
          extra: {
            'sesion': sesion,
            'registro': registro,
            'paciente': paciente,
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ícono
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.hearing_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (analisis != null) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _ChipOido(
                            etiqueta: 'OD',
                            tipo: analisis.prediccionOd,
                            grado: analisis.gradoOd,
                            color: _colorTipo(analisis.prediccionOd),
                          ),
                          _ChipOido(
                            etiqueta: 'OI',
                            tipo: analisis.prediccionOi,
                            grado: analisis.gradoOi,
                            color: _colorTipo(analisis.prediccionOi),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ] else
                      Text(
                        'Sin análisis IA',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      sesion.realizadoEn != null
                          ? formato.format(sesion.realizadoEn!.toLocal())
                          : 'Fecha no disponible',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipOido extends StatelessWidget {
  final String etiqueta;
  final String tipo;
  final String grado;
  final Color color;

  const _ChipOido({
    required this.etiqueta,
    required this.tipo,
    required this.grado,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$etiqueta: $tipo · $grado',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _CargandoInline extends StatelessWidget {
  const _CargandoInline();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _TextoVacio extends StatelessWidget {
  final String mensaje;
  const _TextoVacio(this.mensaje);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        mensaje,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ─── Botón generar PDF ────────────────────────────────────────────────────────

class _BotonGenerarPdf extends ConsumerStatefulWidget {
  final RegistroClinicoModelo registro;
  final PacienteModelo paciente;

  const _BotonGenerarPdf({required this.registro, required this.paciente});

  @override
  ConsumerState<_BotonGenerarPdf> createState() => _BotonGenerarPdfState();
}

class _BotonGenerarPdfState extends ConsumerState<_BotonGenerarPdf> {
  bool _generando = false;

  Future<void> _generarPdf() async {
    setState(() => _generando = true);
    try {
      final dio = ref.read(dioProvider);
      final respuesta = await dio.get(
        '/reportes/registro/${widget.registro.id}',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final directorio = await getTemporaryDirectory();
      final ruta = '${directorio.path}/reporte_${widget.registro.id.substring(0, 8)}.pdf';
      final archivo = File(ruta);
      await archivo.writeAsBytes(respuesta.data as List<int>);

      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => VisorPdfPantalla(
            rutaArchivo: ruta,
            titulo: 'Reporte — ${widget.paciente.nombreCompleto}',
          ),
        ));
      }
    } on DioException catch (e) {
      if (mounted) {
        final mensaje = (e.response?.data is Map &&
                (e.response!.data as Map).containsKey('detail'))
            ? e.response!.data['detail'] as String
            : 'Error al generar el PDF. Verificá tu conexión.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error inesperado al generar el PDF.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _generando ? null : _generarPdf,
      icon: _generando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      label: Text(_generando ? 'Generando PDF...' : 'Generar reporte PDF'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
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
