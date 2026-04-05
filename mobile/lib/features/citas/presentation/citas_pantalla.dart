import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../models/cita_modelo.dart';
import '../providers/citas_provider.dart';

// ─── Constantes de estado ─────────────────────────────────────────────────────

const _etiquetasEstado = {
  'programada': 'Programada',
  'completada': 'Completada',
  'cancelada': 'Cancelada',
  'no_asistio': 'No asistió',
};

const _iconosEstado = {
  'programada': Icons.schedule_outlined,
  'completada': Icons.check_circle_outline,
  'cancelada': Icons.cancel_outlined,
  'no_asistio': Icons.person_off_outlined,
};

Color _colorEstado(BuildContext context, String estado) {
  final cs = Theme.of(context).colorScheme;
  return switch (estado) {
    'programada' => cs.primary,
    'completada' => Colors.green.shade600,
    'cancelada' => cs.error,
    'no_asistio' => Colors.orange.shade700,
    _ => cs.outline,
  };
}

// ─── Pantalla principal ───────────────────────────────────────────────────────

class CitasPantalla extends ConsumerWidget {
  const CitasPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(citasProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Inicio',
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agenda'),
            if (!estado.cargando && estado.citas.isNotEmpty)
              Text(
                '${estado.citasFiltradas.length} citas',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(citasProvider.notifier).cargar(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _FiltroEstado(filtroActual: estado.filtroEstado),
        ),
      ),
      body: _Cuerpo(estado: estado),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/citas/nueva'),
        icon: const Icon(Icons.event_outlined),
        label: const Text('Nueva cita'),
      ),
    );
  }
}

// ─── Chips de filtro ──────────────────────────────────────────────────────────

class _FiltroEstado extends ConsumerWidget {
  final String? filtroActual;

  const _FiltroEstado({required this.filtroActual});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(citasProvider.notifier);

    final opciones = [
      (null, 'Todas'),
      ...(_etiquetasEstado.entries.map((e) => (e.key as String?, e.value))),
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: opciones.map((opcion) {
          final (valor, etiqueta) = opcion;
          final seleccionado = filtroActual == valor;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(etiqueta),
              selected: seleccionado,
              onSelected: (_) => notifier.aplicarFiltro(valor),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _Cuerpo extends ConsumerWidget {
  final CitasEstado estado;

  const _Cuerpo({required this.estado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (estado.cargando) return const _CargandoVista();

    if (estado.error != null && estado.citas.isEmpty) {
      return _ErrorVista(
        mensaje: estado.error!,
        onReintentar: () => ref.read(citasProvider.notifier).cargar(),
      );
    }

    final citasMostradas = estado.citasFiltradas;

    if (citasMostradas.isEmpty) return const _VacioVista();

    return RefreshIndicator(
      onRefresh: () => ref.read(citasProvider.notifier).cargar(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: citasMostradas.length,
        itemBuilder: (context, indice) {
          return _TarjetaCita(cita: citasMostradas[indice]);
        },
      ),
    );
  }
}

// ─── Tarjeta de cita ──────────────────────────────────────────────────────────

class _TarjetaCita extends ConsumerWidget {
  final CitaModelo cita;

  const _TarjetaCita({required this.cita});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _colorEstado(context, cita.estado);
    final formato = DateFormat('EEE dd/MM · HH:mm', 'es');

    return Dismissible(
      key: ValueKey(cita.id),
      direction: DismissDirection.endToStart,
      background: Container(
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
      ),
      confirmDismiss: (_) => _confirmarEliminacion(context),
      onDismissed: (_) {
        ref.read(citasProvider.notifier).eliminar(cita.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cita eliminada'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/citas/detalle', extra: cita),
          onLongPress: () => _mostrarMenuEstado(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicador de estado
                Container(
                  width: 4,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cita.nombrePaciente ?? 'Paciente desconocido',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _ChipEstado(estado: cita.estado),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            formato.format(cita.fechaHora.toLocal()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '· ${cita.duracionMinutos} min',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (cita.motivo != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          cita.motivo!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarMenuEstado(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Cambiar estado',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ..._etiquetasEstado.entries.map(
              (entrada) => ListTile(
                leading: Icon(_iconosEstado[entrada.key]),
                title: Text(entrada.value),
                selected: cita.estado == entrada.key,
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(citasProvider.notifier)
                      .cambiarEstado(cita.id, entrada.key);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmarEliminacion(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: const Text('¿Eliminar esta cita? Esta acción no se puede deshacer.'),
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
}

// ─── Chip de estado ───────────────────────────────────────────────────────────

class _ChipEstado extends StatelessWidget {
  final String estado;

  const _ChipEstado({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(context, estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _etiquetasEstado[estado] ?? estado,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Estados de pantalla ──────────────────────────────────────────────────────

class _CargandoVista extends StatelessWidget {
  const _CargandoVista();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 90,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _VacioVista extends StatelessWidget {
  const _VacioVista();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined,
              size: 72, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Sin citas registradas',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tocá "Nueva cita" para agendar una',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorVista extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorVista({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_outlined,
                size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
