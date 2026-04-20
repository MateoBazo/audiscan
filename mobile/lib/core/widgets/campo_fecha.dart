import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Campo visual para selección de fecha. No incluye lógica de picker —
/// sólo muestra la fecha seleccionada y delega el tap al caller.
class CampoFecha extends StatelessWidget {
  final DateTime? fecha;
  final String etiqueta;
  final IconData iconoPrefijo;
  final IconData? iconoSufijo;
  final String textoPorDefecto;
  final String? errorText;
  final VoidCallback onTap;

  const CampoFecha({
    super.key,
    required this.fecha,
    required this.etiqueta,
    required this.onTap,
    this.iconoPrefijo = Icons.calendar_today_outlined,
    this.iconoSufijo,
    this.textoPorDefecto = 'Seleccionar',
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formato = DateFormat('dd/MM/yyyy');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: Icon(iconoPrefijo),
          border: const OutlineInputBorder(),
          suffixIcon: iconoSufijo != null ? Icon(iconoSufijo) : null,
          errorText: errorText,
        ),
        child: Text(
          fecha != null ? formato.format(fecha!) : textoPorDefecto,
          style: fecha != null
              ? theme.textTheme.bodyLarge
              : theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}
