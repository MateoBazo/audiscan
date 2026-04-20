import 'package:flutter/material.dart';

/// Título de sección para formularios con estilo primario consistente.
class EncabezadoSeccion extends StatelessWidget {
  final String titulo;

  const EncabezadoSeccion({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      titulo,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
