import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/audiometria_provider.dart';
import '../../registros_clinicos/models/registro_clinico_modelo.dart';
import '../../pacientes/models/paciente_modelo.dart';
import '../../../core/widgets/boton_guardar.dart';
import '../../../core/widgets/encabezado_seccion.dart';

const _frecuencias = ['250', '500', '1000', '2000', '4000', '8000'];

class RegistrarAudiometriaPantalla extends ConsumerStatefulWidget {
  final RegistroClinicoModelo registro;
  final PacienteModelo paciente;

  const RegistrarAudiometriaPantalla({
    super.key,
    required this.registro,
    required this.paciente,
  });

  @override
  ConsumerState<RegistrarAudiometriaPantalla> createState() =>
      _RegistrarAudiometriaPantallaState();
}

class _RegistrarAudiometriaPantallaState
    extends ConsumerState<RegistrarAudiometriaPantalla> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesCtrl = TextEditingController();

  // 6 controllers por oído — índice = frecuencia (250→0, 500→1, ... 8000→5)
  final _controllersOd =
      List.generate(6, (_) => TextEditingController());
  final _controllersOi =
      List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    _observacionesCtrl.dispose();
    for (final c in _controllersOd) {
      c.dispose();
    }
    for (final c in _controllersOi) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(TextEditingController ctrl) =>
      double.parse(ctrl.text.trim());

  Future<void> _analizar() async {
    if (!_formKey.currentState!.validate()) return;

    final resultado = await ref
        .read(audiometriaProvider(widget.registro.id).notifier)
        .crear(
          odHz250: _parse(_controllersOd[0]),
          odHz500: _parse(_controllersOd[1]),
          odHz1000: _parse(_controllersOd[2]),
          odHz2000: _parse(_controllersOd[3]),
          odHz4000: _parse(_controllersOd[4]),
          odHz8000: _parse(_controllersOd[5]),
          oiHz250: _parse(_controllersOi[0]),
          oiHz500: _parse(_controllersOi[1]),
          oiHz1000: _parse(_controllersOi[2]),
          oiHz2000: _parse(_controllersOi[3]),
          oiHz4000: _parse(_controllersOi[4]),
          oiHz8000: _parse(_controllersOi[5]),
          observaciones: _observacionesCtrl.text.trim().isNotEmpty
              ? _observacionesCtrl.text.trim()
              : null,
        );

    if (!mounted) return;

    if (resultado != null) {
      context.pushReplacement(
        '/audiometria/resultado',
        extra: {
          'sesion': resultado,
          'registro': widget.registro,
          'paciente': widget.paciente,
        },
      );
    } else {
      final error =
          ref.read(audiometriaProvider(widget.registro.id)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al analizar audiometría'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(audiometriaProvider(widget.registro.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Audiometría + IA'),
            Text(
              widget.paciente.nombreCompleto,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Aviso clínico ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ingresá los umbrales auditivos por vía aérea en dB HL '
                        'para cada frecuencia.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const EncabezadoSeccion(titulo: 'Umbrales auditivos (dB HL)'),
              const SizedBox(height: 16),

              // ── Tabla de umbrales ─────────────────────────────────────────
              _TablaUmbrales(
                controllersOd: _controllersOd,
                controllersOi: _controllersOi,
              ),

              const SizedBox(height: 28),
              const EncabezadoSeccion(titulo: 'Observaciones'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _observacionesCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observaciones adicionales (opcional)',
                  prefixIcon: Icon(Icons.comment_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 36),

              BotonGuardar(
                guardando: estado.guardando,
                onPressed: _analizar,
                etiqueta: 'Analizar con IA',
              ),

              if (estado.guardando) ...[
                const SizedBox(height: 16),
                Text(
                  'El modelo de IA está clasificando el audiograma. '
                  'Esto puede tomar unos segundos.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tabla de ingreso de umbrales ─────────────────────────────────────────────

class _TablaUmbrales extends StatelessWidget {
  final List<TextEditingController> controllersOd;
  final List<TextEditingController> controllersOi;

  const _TablaUmbrales({
    required this.controllersOd,
    required this.controllersOi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorOd = theme.colorScheme.primary;
    final colorOi = Colors.red.shade600;

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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                const SizedBox(width: 80),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 10, color: colorOd),
                      const SizedBox(width: 4),
                      Text(
                        'OD (dB)',
                        style: theme.textTheme.labelMedium?.copyWith(
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
                      Icon(Icons.close, size: 10, color: colorOi),
                      const SizedBox(width: 4),
                      Text(
                        'OI (dB)',
                        style: theme.textTheme.labelMedium?.copyWith(
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
          // Filas de frecuencias
          ...List.generate(_frecuencias.length, (i) {
            final esPar = i.isEven;
            return Container(
              decoration: BoxDecoration(
                color: esPar
                    ? Colors.transparent
                    : theme.colorScheme.surfaceContainerLow.withOpacity(0.4),
                borderRadius: i == _frecuencias.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(11))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${_frecuencias[i]} Hz',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _CampoUmbral(
                        controller: controllersOd[i],
                        colorBorde: colorOd,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _CampoUmbral(
                        controller: controllersOi[i],
                        colorBorde: colorOi,
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

// ─── Campo individual de umbral ───────────────────────────────────────────────

class _CampoUmbral extends StatelessWidget {
  final TextEditingController controller;
  final Color colorBorde;

  const _CampoUmbral({required this.controller, required this.colorBorde});

  String? _validar(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Requerido';
    final n = double.tryParse(valor.trim());
    if (n == null) return 'Número';
    if (n < -10 || n > 120) return '-10 a 120';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,3}\.?\d{0,1}')),
      ],
      textAlign: TextAlign.center,
      validator: _validar,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: Theme.of(context).textTheme.bodySmall,
        suffixText: 'dB',
        suffixStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorBorde.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorBorde, width: 2),
        ),
        errorStyle: const TextStyle(fontSize: 9, height: 1.2),
        errorMaxLines: 1,
      ),
    );
  }
}
