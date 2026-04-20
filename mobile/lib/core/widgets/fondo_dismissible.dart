import 'package:flutter/material.dart';

/// Fondo rojo estándar para el gesto de eliminación en listas Dismissible.
class FondoDismissible extends StatelessWidget {
  const FondoDismissible({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.delete_outline,
        color: theme.colorScheme.onErrorContainer,
      ),
    );
  }
}
