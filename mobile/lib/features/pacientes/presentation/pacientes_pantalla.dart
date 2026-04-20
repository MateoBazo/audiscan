import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/paciente_modelo.dart';
import '../providers/pacientes_provider.dart';
import '../../../core/utils/color_paciente.dart';
import '../../../core/widgets/vista_cargando.dart';
import '../../../core/widgets/vista_vacia.dart';
import '../../../core/widgets/vista_error.dart';
import '../../../core/widgets/fondo_dismissible.dart';
import '../../../core/widgets/dialogo_confirmar_eliminacion.dart';

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
  Widget build(BuildContext context) {
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
    if (estado.cargando) return const VistaCargando(alturaItem: 80, cantidadItems: 6);

    if (estado.error != null && estado.pacientes.isEmpty) {
      return VistaError(
        mensaje: estado.error!,
        onReintentar: () => ref.read(pacientesProvider.notifier).cargar(),
      );
    }

    if (estado.pacientes.isEmpty) {
      return const VistaVacia(
        icono: Icons.person_search_outlined,
        titulo: 'Sin pacientes registrados',
        subtitulo: 'Tocá "Nuevo paciente" para agregar uno',
      );
    }

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
      background: const FondoDismissible(),
      confirmDismiss: (_) => mostrarDialogoConfirmarEliminacion(
        context,
        titulo: 'Eliminar paciente',
        contenido:
            '¿Eliminar a ${paciente.nombreCompleto}? Esta acción no se puede deshacer.',
      ),
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
}
