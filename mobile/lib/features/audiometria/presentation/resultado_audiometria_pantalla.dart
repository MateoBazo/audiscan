import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/audiometria_modelo.dart';
import '../../registros_clinicos/models/registro_clinico_modelo.dart';
import '../../pacientes/models/paciente_modelo.dart';

class ResultadoAudiometriaPantalla extends StatelessWidget {
  final SesionAudiometriaModelo sesion;
  final RegistroClinicoModelo registro;
  final PacienteModelo paciente;

  const ResultadoAudiometriaPantalla({
    super.key,
    required this.sesion,
    required this.registro,
    required this.paciente,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analisis = sesion.analisis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado audiométrico'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(
            '/registros-clinicos/detalle',
            extra: {'registro': registro, 'paciente': paciente},
          ),
        ),
      ),
      body: analisis == null
          ? const Center(child: Text('Sin análisis disponible'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado paciente
                  Text(
                    paciente.nombreCompleto,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Audiometría registrada',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  if (analisis.esMock) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 16,
                              color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Modo demostración — modelo no cargado',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Resultados OD / OI
                  Row(
                    children: [
                      Expanded(
                        child: _TarjetaOido(
                          lado: 'Oído Derecho',
                          tipo: analisis.etiquetaTipo(analisis.prediccionOd),
                          grado: analisis.etiquetaGrado(analisis.gradoOd),
                          confianza: analisis.confianzaOd,
                          colorLado: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TarjetaOido(
                          lado: 'Oído Izquierdo',
                          tipo: analisis.etiquetaTipo(analisis.prediccionOi),
                          grado: analisis.etiquetaGrado(analisis.gradoOi),
                          confianza: analisis.confianzaOi,
                          colorLado: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _TablaUmbrales(sesion: sesion),

                  if (analisis.recomendacion != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.recommend_outlined,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Recomendación clínica',
                                style:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            analisis.recomendacion!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Este resultado es una herramienta de apoyo. '
                      'El médico debe validar el diagnóstico final.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => context.go(
                      '/registros-clinicos/detalle',
                      extra: {'registro': registro, 'paciente': paciente},
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver al registro'),
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
}

// ─── Tabla resumen de umbrales ingresados ─────────────────────────────────────

class _TablaUmbrales extends StatelessWidget {
  final SesionAudiometriaModelo sesion;

  const _TablaUmbrales({required this.sesion});

  static const _frecuencias = ['250', '500', '1000', '2000', '4000', '8000'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorOd = theme.colorScheme.primary;
    final colorOi = Colors.red.shade600;
    final umbralesOd = sesion.umbralOd;
    final umbralesOi = sesion.umbralOi;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Encabezado
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Frecuencia',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 8, color: colorOd),
                      const SizedBox(width: 4),
                      Text(
                        'OD',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorOd,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 8, color: colorOi),
                      const SizedBox(width: 4),
                      Text(
                        'OI',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorOi,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Filas de datos
          ...List.generate(_frecuencias.length, (i) {
            final esPar = i.isEven;
            final esUltima = i == _frecuencias.length - 1;
            final od = umbralesOd[i].toInt();
            final oi = umbralesOi[i].toInt();

            return Container(
              decoration: BoxDecoration(
                color: esPar
                    ? Colors.transparent
                    : theme.colorScheme.surfaceContainerLow.withOpacity(0.4),
                borderRadius: esUltima
                    ? const BorderRadius.vertical(
                        bottom: Radius.circular(11))
                    : null,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${_frecuencias[i]} Hz',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$od dB',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorOd,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$oi dB',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorOi,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Tarjeta de resultado por oído ────────────────────────────────────────────

class _TarjetaOido extends StatelessWidget {
  final String lado;
  final String tipo;
  final String grado;
  final double confianza;
  final Color colorLado;

  const _TarjetaOido({
    required this.lado,
    required this.tipo,
    required this.grado,
    required this.confianza,
    required this.colorLado,
  });

  Color _colorTipo(BuildContext context, String tipo) {
    switch (tipo.toLowerCase()) {
      case 'normal':
        return Colors.green.shade600;
      case 'conductiva':
        return Colors.orange.shade700;
      case 'sensorioneural':
        return Colors.blue.shade700;
      case 'mixta':
        return Colors.purple.shade600;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorTipo(context, tipo);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: colorLado.withOpacity(0.4), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lado,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorLado,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tipo,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            grado,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Confianza: ${(confianza * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
