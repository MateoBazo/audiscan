import 'package:flutter/material.dart';

/// Muestra un AlertDialog de confirmación de eliminación.
/// Retorna `true` si el usuario confirma, `false` o `null` si cancela.
Future<bool?> mostrarDialogoConfirmarEliminacion(
  BuildContext context, {
  required String titulo,
  required String contenido,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(contenido),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}
