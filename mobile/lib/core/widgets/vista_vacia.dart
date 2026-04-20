import 'package:flutter/material.dart';

/// Estado vacío genérico para listas sin datos.
class VistaVacia extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;

  const VistaVacia({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 72, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}
