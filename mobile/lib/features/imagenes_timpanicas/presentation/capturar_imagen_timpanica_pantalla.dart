import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/imagen_timpanica_modelo.dart';
import '../providers/imagenes_timpanicas_provider.dart';
import '../../registros_clinicos/models/registro_clinico_modelo.dart';
import '../../pacientes/models/paciente_modelo.dart';

class CapturarImagenTimpanicaPantalla extends ConsumerStatefulWidget {
  final RegistroClinicoModelo registro;
  final PacienteModelo paciente;

  const CapturarImagenTimpanicaPantalla({
    super.key,
    required this.registro,
    required this.paciente,
  });

  @override
  ConsumerState<CapturarImagenTimpanicaPantalla> createState() =>
      _CapturarImagenTimpanicaPantallaState();
}

class _CapturarImagenTimpanicaPantallaState
    extends ConsumerState<CapturarImagenTimpanicaPantalla> {
  File? _archivoSeleccionado;
  String _oido = 'derecho';
  final _picker = ImagePicker();

  Future<void> _seleccionarImagen(ImageSource fuente) async {
    final imagen = await _picker.pickImage(
      source: fuente,
      imageQuality: 90,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (imagen == null) return;
    setState(() => _archivoSeleccionado = File(imagen.path));
  }

  Future<void> _subirImagen() async {
    if (_archivoSeleccionado == null) return;

    final resultado = await ref
        .read(imagenesTimpanicasProvider(widget.registro.id).notifier)
        .subir(archivo: _archivoSeleccionado!, oido: _oido);

    if (!mounted) return;

    if (resultado != null) {
      context.pushReplacement(
        '/imagenes-timpanicas/resultado',
        extra: {
          'imagen': resultado,
          'registro': widget.registro,
          'paciente': widget.paciente,
        },
      );
    } else {
      final error = ref
          .read(imagenesTimpanicasProvider(widget.registro.id))
          .error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al subir la imagen'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(imagenesTimpanicasProvider(widget.registro.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Imagen timpánica')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Selección de imagen ───────────────────────────────────────
            _archivoSeleccionado == null
                ? _SelectorImagen(onSeleccionar: _seleccionarImagen)
                : _VistaPrevia(
                    archivo: _archivoSeleccionado!,
                    onCambiar: () =>
                        setState(() => _archivoSeleccionado = null),
                  ),

            const SizedBox(height: 28),

            // ── Selección de oído ─────────────────────────────────────────
            Text(
              'Oído examinado',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            _SelectorOido(
              oido: _oido,
              onCambio: (valor) => setState(() => _oido = valor),
            ),

            const SizedBox(height: 32),

            // ── Botón subir ───────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _archivoSeleccionado != null && !estado.subiendo
                  ? _subirImagen
                  : null,
              icon: estado.subiendo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_outlined),
              label: Text(estado.subiendo
                  ? 'Analizando con IA...'
                  : 'Subir y analizar'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            if (estado.subiendo) ...[
              const SizedBox(height: 16),
              Text(
                'El modelo de IA está clasificando la imagen. Esto puede tomar unos segundos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Widget: selector de imagen ───────────────────────────────────────────────

class _SelectorImagen extends StatelessWidget {
  final void Function(ImageSource) onSeleccionar;

  const _SelectorImagen({required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona una imagen',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => onSeleccionar(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Cámara'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => onSeleccionar(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Widget: vista previa ─────────────────────────────────────────────────────

class _VistaPrevia extends StatelessWidget {
  final File archivo;
  final VoidCallback onCambiar;

  const _VistaPrevia({required this.archivo, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            archivo,
            width: double.infinity,
            height: 280,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onCambiar,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Widget: selector de oído ─────────────────────────────────────────────────

class _SelectorOido extends StatelessWidget {
  final String oido;
  final void Function(String) onCambio;

  const _SelectorOido({required this.oido, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: _Opcion(
          etiqueta: 'Derecho',
          valor: 'derecho',
          seleccionado: oido == 'derecho',
          onTap: () => onCambio('derecho'),
          theme: theme,
        )),
        const SizedBox(width: 12),
        Expanded(child: _Opcion(
          etiqueta: 'Izquierdo',
          valor: 'izquierdo',
          seleccionado: oido == 'izquierdo',
          onTap: () => onCambio('izquierdo'),
          theme: theme,
        )),
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool seleccionado;
  final VoidCallback onTap;
  final ThemeData theme;

  const _Opcion({
    required this.etiqueta,
    required this.valor,
    required this.seleccionado,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: seleccionado
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seleccionado
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Text(
          etiqueta,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: seleccionado
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight:
                seleccionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
