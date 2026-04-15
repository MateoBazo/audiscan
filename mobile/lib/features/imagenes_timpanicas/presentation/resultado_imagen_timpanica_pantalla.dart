import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/imagen_timpanica_modelo.dart';
import '../../registros_clinicos/models/registro_clinico_modelo.dart';
import '../../pacientes/models/paciente_modelo.dart';

class ResultadoImagenTimpanicaPantalla extends StatelessWidget {
  final ImagenTimpanicaModelo imagen;
  final RegistroClinicoModelo registro;
  final PacienteModelo paciente;

  const ResultadoImagenTimpanicaPantalla({
    super.key,
    required this.imagen,
    required this.registro,
    required this.paciente,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analisis = imagen.analisis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado IA'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/registros-clinicos/detalle', extra: {
            'registro': registro,
            'paciente': paciente,
          }),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Encabezado ────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.hearing, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paciente.nombreCompleto,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        imagen.etiquetaOido,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Imagen timpánica ──────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imagen.rutaImagen.replaceAll(RegExp(r'\?$'), ''),
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progreso) => progreso == null
                    ? child
                    : Container(
                        height: 240,
                        color: theme.colorScheme.surfaceContainerLow,
                        child: const Center(
                            child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  height: 240,
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          size: 40,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text('No se pudo cargar la imagen',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (analisis == null) ...[
              _TarjetaInfo(
                icono: Icons.warning_amber_outlined,
                mensaje: 'No se encontró análisis IA para esta imagen.',
                color: theme.colorScheme.error,
              ),
            ] else ...[
              // ── Predicción principal ──────────────────────────────────
              _TarjetaPrediccion(analisis: analisis, theme: theme),

              const SizedBox(height: 16),

              // ── Probabilidades ────────────────────────────────────────
              _TarjetaProbabilidades(analisis: analisis, theme: theme),

              const SizedBox(height: 16),

              // ── Advertencia mock ──────────────────────────────────────
              if (analisis.esMock)
                _TarjetaInfo(
                  icono: Icons.science_outlined,
                  mensaje:
                      'Modo demostración — el modelo real no está cargado. '
                      'Los valores mostrados son simulados.',
                  color: theme.colorScheme.tertiary,
                ),

              // ── Aviso clínico ─────────────────────────────────────────
              if (!analisis.esMock)
                _TarjetaInfo(
                  icono: Icons.info_outline,
                  mensaje:
                      'Este resultado es una sugerencia del sistema de IA. '
                      'El diagnóstico final corresponde al criterio del médico.',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],

            const SizedBox(height: 24),

            // ── Botón volver al registro ──────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => context.go(
                '/registros-clinicos/detalle',
                extra: {'registro': registro, 'paciente': paciente},
              ),
              icon: const Icon(Icons.arrow_back_outlined),
              label: const Text('Volver al registro clínico'),
              style: OutlinedButton.styleFrom(
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
}

// ─── Tarjeta: predicción principal ───────────────────────────────────────────

class _TarjetaPrediccion extends StatelessWidget {
  final AnalisisIAModelo analisis;
  final ThemeData theme;

  const _TarjetaPrediccion({required this.analisis, required this.theme});

  Color _colorPrediccion() {
    switch (analisis.prediccion) {
      case 'normal':
        return Colors.green;
      case 'otitis_aguda':
        return Colors.deepOrange;
      case 'otitis_cronica':
        return Colors.orange;
      case 'cerumen':
        return Colors.amber.shade700;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorPrediccion();
    final porcentaje = (analisis.confianza * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              analisis.prediccion == 'normal'
                  ? Icons.check_circle_outline
                  : Icons.medical_services_outlined,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clasificación IA',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  analisis.etiqueta,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'Confianza: $porcentaje%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withOpacity(0.8),
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

// ─── Tarjeta: barras de probabilidad ─────────────────────────────────────────

class _TarjetaProbabilidades extends StatelessWidget {
  final AnalisisIAModelo analisis;
  final ThemeData theme;

  const _TarjetaProbabilidades(
      {required this.analisis, required this.theme});

  static const _orden = [
    ('normal', 'Normal'),
    ('otitis_aguda', 'Otitis Media Aguda'),
    ('otitis_cronica', 'Otitis Media Crónica'),
    ('cerumen', 'Tapón de Cerumen'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución de probabilidades',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ..._orden.map(((String clave, String etiqueta) entrada) {
            final prob =
                analisis.probabilidades[entrada.$1] ?? 0.0;
            final esPrediccion =
                entrada.$1 == analisis.prediccion;
            return _BarraProbabilidad(
              etiqueta: entrada.$2,
              probabilidad: prob,
              esPrediccion: esPrediccion,
              theme: theme,
            );
          }),
        ],
      ),
    );
  }
}

class _BarraProbabilidad extends StatelessWidget {
  final String etiqueta;
  final double probabilidad;
  final bool esPrediccion;
  final ThemeData theme;

  const _BarraProbabilidad({
    required this.etiqueta,
    required this.probabilidad,
    required this.esPrediccion,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = (probabilidad * 100).toStringAsFixed(1);
    final color =
        esPrediccion ? theme.colorScheme.primary : theme.colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                etiqueta,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight:
                      esPrediccion ? FontWeight.bold : FontWeight.normal,
                  color: esPrediccion
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$porcentaje%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight:
                      esPrediccion ? FontWeight.bold : FontWeight.normal,
                  color: esPrediccion
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: probabilidad,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(
                esPrediccion
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta: info / aviso ────────────────────────────────────────────────────

class _TarjetaInfo extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final Color color;

  const _TarjetaInfo({
    required this.icono,
    required this.mensaje,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
