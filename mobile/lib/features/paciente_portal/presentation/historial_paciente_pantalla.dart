import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/paciente_portal_provider.dart';
import '../../registros_clinicos/models/registro_clinico_modelo.dart';
import '../../imagenes_timpanicas/models/imagen_timpanica_modelo.dart';
import '../../audiometria/models/audiometria_modelo.dart';

// ─── Historial clínico ────────────────────────────────────────────────────────

class HistorialPacientePantalla extends ConsumerWidget {
  const HistorialPacientePantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(pacientePortalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi historial clínico')),
      body: estado.cargando
          ? const Center(child: CircularProgressIndicator())
          : estado.registros.isEmpty
              ? const _VacioVista(mensaje: 'No tenés registros clínicos aún.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: estado.registros.length,
                  itemBuilder: (_, i) => _TarjetaRegistro(registro: estado.registros[i]),
                ),
    );
  }
}

class _TarjetaRegistro extends StatelessWidget {
  final RegistroClinicoModelo registro;
  const _TarjetaRegistro({required this.registro});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formato = DateFormat("d 'de' MMMM 'de' yyyy", 'es');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  formato.format(registro.fecha),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (registro.diagnostico != null) ...[
              const SizedBox(height: 10),
              _CampoRegistro(
                  icono: Icons.medical_information_outlined,
                  titulo: 'Diagnóstico',
                  contenido: registro.diagnostico!,
                  destacado: true),
            ],
            if (registro.tratamiento != null) ...[
              const SizedBox(height: 6),
              _CampoRegistro(
                  icono: Icons.medication_outlined,
                  titulo: 'Tratamiento',
                  contenido: registro.tratamiento!),
            ],
            if (registro.observaciones != null) ...[
              const SizedBox(height: 6),
              _CampoRegistro(
                  icono: Icons.comment_outlined,
                  titulo: 'Observaciones',
                  contenido: registro.observaciones!),
            ],
          ],
        ),
      ),
    );
  }
}

class _CampoRegistro extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String contenido;
  final bool destacado;

  const _CampoRegistro({
    required this.icono,
    required this.titulo,
    required this.contenido,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: destacado
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono,
                  size: 14,
                  color: destacado
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                titulo,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: destacado
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(contenido, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ─── Imágenes timpánicas del paciente ────────────────────────────────────────

class ImagenesPacientePantalla extends ConsumerWidget {
  const ImagenesPacientePantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(pacientePortalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis imágenes timpánicas')),
      body: estado.cargando
          ? const Center(child: CircularProgressIndicator())
          : estado.imagenes.isEmpty
              ? const _VacioVista(mensaje: 'No tenés imágenes registradas aún.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: estado.imagenes.length,
                  itemBuilder: (_, i) => _TarjetaImagen(imagen: estado.imagenes[i]),
                ),
    );
  }
}

class _TarjetaImagen extends StatelessWidget {
  final ImagenTimpanicaModelo imagen;
  const _TarjetaImagen({required this.imagen});

  Color _colorPrediccion(String pred) {
    switch (pred) {
      case 'normal': return Colors.green.shade600;
      case 'otitis_aguda': return Colors.red.shade600;
      case 'otitis_cronica': return Colors.orange.shade700;
      case 'cerumen': return Colors.amber.shade700;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analisis = imagen.analisis;
    final formato = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imagen.rutaImagen,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: theme.colorScheme.surfaceContainerLow,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _colorPrediccion(analisis.prediccion).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            analisis.etiqueta,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _colorPrediccion(analisis.prediccion),
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
          ],
        ),
      ),
    );
  }
}

// ─── Audiometrías del paciente ────────────────────────────────────────────────

class AudiometriasPacientePantalla extends ConsumerWidget {
  const AudiometriasPacientePantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(pacientePortalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis audiometrías')),
      body: estado.cargando
          ? const Center(child: CircularProgressIndicator())
          : estado.audiometrias.isEmpty
              ? const _VacioVista(mensaje: 'No tenés audiometrías registradas aún.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: estado.audiometrias.length,
                  itemBuilder: (_, i) =>
                      _TarjetaAudiometria(sesion: estado.audiometrias[i]),
                ),
    );
  }
}

class _TarjetaAudiometria extends StatelessWidget {
  final SesionAudiometriaModelo sesion;
  const _TarjetaAudiometria({required this.sesion});

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'normal': return Colors.green.shade600;
      case 'conductiva': return Colors.orange.shade700;
      case 'sensorioneural': return Colors.blue.shade700;
      case 'mixta': return Colors.purple.shade600;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analisis = sesion.analisis;
    final formato = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hearing_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  sesion.realizadoEn != null
                      ? formato.format(sesion.realizadoEn!.toLocal())
                      : 'Fecha no disponible',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (analisis != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ChipResultado(
                      etiqueta: 'OD',
                      tipo: analisis.etiquetaTipo(analisis.prediccionOd),
                      grado: analisis.etiquetaGrado(analisis.gradoOd),
                      color: _colorTipo(analisis.prediccionOd),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChipResultado(
                      etiqueta: 'OI',
                      tipo: analisis.etiquetaTipo(analisis.prediccionOi),
                      grado: analisis.etiquetaGrado(analisis.gradoOi),
                      color: _colorTipo(analisis.prediccionOi),
                    ),
                  ),
                ],
              ),
              if (analisis.recomendacion != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    analisis.recomendacion!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipResultado extends StatelessWidget {
  final String etiqueta;
  final String tipo;
  final String grado;
  final Color color;

  const _ChipResultado({
    required this.etiqueta,
    required this.tipo,
    required this.grado,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            tipo,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
          Text(
            grado,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ─── Widget vacío compartido ──────────────────────────────────────────────────

class _VacioVista extends StatelessWidget {
  final String mensaje;
  const _VacioVista({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
