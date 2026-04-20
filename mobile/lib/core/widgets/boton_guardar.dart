import 'package:flutter/material.dart';

/// Botón de guardar para formularios. Muestra un spinner mientras [guardando] es true.
class BotonGuardar extends StatelessWidget {
  final bool guardando;
  final VoidCallback onPressed;
  final String etiqueta;

  const BotonGuardar({
    super.key,
    required this.guardando,
    required this.onPressed,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: guardando ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: guardando
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(etiqueta, style: const TextStyle(fontSize: 16)),
    );
  }
}
