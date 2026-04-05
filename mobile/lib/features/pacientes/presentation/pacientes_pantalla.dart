import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../models/paciente_modelo.dart';
import '../providers/pacientes_provider.dart';
import '../../../core/utils/color_paciente.dart';

class PacientesPantalla extends ConsumerStatefulWidget {
  const PacientesPantalla({super.key});

  @override
  ConsumerState<PacientesPantalla> createState() => _PacientesPantallaState();
}

class _PacientesPantallaState extends ConsumerState<PacientesPantalla> {
  final _busquedaCtrl = TextEditingController();
  String _terminoBusqueda = '';

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  List<PacienteModelo> _filtrar(List<PacienteModelo> pacientes) {
    if (_terminoBusqueda.isEmpty) return pacientes;
    final termino = _terminoBusqueda.toLowerCase();
    return pacientes
        .where((p) => p.nombreCompleto.toLowerCase().contains(termino))
        .toList();
  }

  @override
  Widget build(BuildContext context, ) {
    final estado = ref.watch(pacientesProvider);
    final theme = Theme.of(context);
    final pacientesFiltrados = _filtrar(estado.pacientes);

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
            const Text('Mis Pacientes'),
            if (!estado.cargando && estado.pacientes.isNotEmpty)
              Text(
                _terminoBusqueda.isEmpty
                    ? '${estado.pacientes.length} registrados'
                    : '${pacientesFiltrados.length} de ${estado.pacientes.length}',
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
            onPressed: () => ref.read(pacientesProvider.notifier).cargar(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _busquedaCtrl,
              onChanged: (valor) =>
                  setState(() => _terminoBusqueda = valor.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar paciente...',
                prefixIcon: const Icon(Icons.search_outlined),
                suffixIcon: _terminoBusqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _busquedaCtrl.clear();
                          setState(() => _terminoBusqueda = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _Cuerpo(
        estado: estado,
        pacientesFiltrados: pacientesFiltrados,
        hayBusqueda: _terminoBusqueda.isNotEmpty,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pacientes/nuevo'),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nuevo paciente'),
      ),
    );
  }
}

// ─── Cuerpo principal ─────────────────────────────────────────────────────────

class _Cuerpo extends ConsumerWidget {
  final PacientesEstado estado;
  final List<PacienteModelo> pacientesFiltrados;
  final bool hayBusqueda;

  const _Cuerpo({
    required this.estado,
    required this.pacientesFiltrados,
    required this.hayBusqueda,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (estado.cargando) return const _CargandoVista();

    if (estado.error != null && estado.pacientes.isEmpty) {
      return _ErrorVista(
        mensaje: estado.error!,
        onReintentar: () => ref.read(pacientesProvider.notifier).cargar(),
      );
    }

    if (estado.pacientes.isEmpty) return const _VacioVista();

    if (pacientesFiltrados.isEmpty) return _SinResultadosVista();

    return RefreshIndicator(
      onRefresh: () => ref.read(pacientesProvider.notifier).cargar(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: pacientesFiltrados.length,
        itemBuilder: (context, indice) {
          final paciente = pacientesFiltrados[indice];
          return _TarjetaPaciente(paciente: paciente);
        },
      ),
    );
  }
}

// ─── Sin resultados de búsqueda ───────────────────────────────────────────────

class _SinResultadosVista extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined,
              size: 72, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Sin resultados',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Probá con otro nombre',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de paciente ──────────────────────────────────────────────────────

class _TarjetaPaciente extends ConsumerWidget {
  final PacienteModelo paciente;

  const _TarjetaPaciente({required this.paciente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(paciente.id),
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
        ref.read(pacientesProvider.notifier).eliminar(paciente.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${paciente.nombreCompleto} eliminado'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: colorDePaciente(paciente.nombreCompleto),
            child: Text(
              paciente.iniciales,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            paciente.nombreCompleto,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: _subtitulo(paciente, theme),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/pacientes/historial', extra: paciente),
        ),
      ),
    );
  }

  Widget? _subtitulo(PacienteModelo paciente, ThemeData theme) {
    final partes = <String>[];
    if (paciente.edad != null) partes.add('${paciente.edad} años');
    if (paciente.telefono != null) partes.add(paciente.telefono!);
    if (paciente.fechaNacimiento != null && paciente.edad == null) {
      partes.add(
        DateFormat('dd/MM/yyyy').format(paciente.fechaNacimiento!),
      );
    }
    if (partes.isEmpty) return null;
    return Text(
      partes.join(' · '),
      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
    );
  }

  Future<bool?> _confirmarEliminacion(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar paciente'),
        content: Text(
          '¿Eliminar a ${paciente.nombreCompleto}? Esta acción no se puede deshacer.',
        ),
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

// ─── Estados de la pantalla ───────────────────────────────────────────────────

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
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 80,
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
          Icon(
            Icons.person_search_outlined,
            size: 72,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin pacientes registrados',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tocá "Nuevo paciente" para agregar uno',
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
            Icon(
              Icons.wifi_off_outlined,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
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
