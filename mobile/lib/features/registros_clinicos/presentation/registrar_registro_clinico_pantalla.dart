import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/registro_clinico_modelo.dart';
import '../providers/registros_clinicos_provider.dart';
import '../../pacientes/models/paciente_modelo.dart';
import '../../citas/providers/citas_provider.dart';

class RegistrarRegistroClinicoPantalla extends ConsumerStatefulWidget {
  final PacienteModelo paciente;
  final RegistroClinicoModelo? registro;

  const RegistrarRegistroClinicoPantalla({
    super.key,
    required this.paciente,
    this.registro,
  });

  @override
  ConsumerState<RegistrarRegistroClinicoPantalla> createState() =>
      _RegistrarRegistroClinicoPantallaState();
}

class _RegistrarRegistroClinicoPantallaState
    extends ConsumerState<RegistrarRegistroClinicoPantalla> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _anamnesisCtrl;
  late final TextEditingController _exploracionFisicaCtrl;
  late final TextEditingController _diagnosticoCtrl;
  late final TextEditingController _tratamientoCtrl;
  late final TextEditingController _observacionesCtrl;

  late DateTime _fecha;
  String? _idCitaSeleccionada;
  bool _guardando = false;

  bool get _esEdicion => widget.registro != null;

  @override
  void initState() {
    super.initState();
    final r = widget.registro;
    _fecha = r?.fecha ?? DateTime.now();
    _idCitaSeleccionada = r?.idCita;
    _anamnesisCtrl = TextEditingController(text: r?.anamnesis ?? '');
    _exploracionFisicaCtrl =
        TextEditingController(text: r?.exploracionFisica ?? '');
    _diagnosticoCtrl = TextEditingController(text: r?.diagnostico ?? '');
    _tratamientoCtrl = TextEditingController(text: r?.tratamiento ?? '');
    _observacionesCtrl = TextEditingController(text: r?.observaciones ?? '');
  }

  @override
  void dispose() {
    _anamnesisCtrl.dispose();
    _exploracionFisicaCtrl.dispose();
    _diagnosticoCtrl.dispose();
    _tratamientoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Fecha del registro',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (seleccionada != null) {
      setState(() => _fecha = seleccionada);
    }
  }

  String? _valorONulo(TextEditingController ctrl) {
    final texto = ctrl.text.trim();
    return texto.isNotEmpty ? texto : null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final notifier = ref.read(
      registrosClinicosProvider(widget.paciente.id).notifier,
    );

    final bool exito;

    if (_esEdicion) {
      exito = await notifier.actualizar(
        id: widget.registro!.id,
        fecha: _fecha,
        anamnesis: _valorONulo(_anamnesisCtrl),
        exploracionFisica: _valorONulo(_exploracionFisicaCtrl),
        diagnostico: _valorONulo(_diagnosticoCtrl),
        tratamiento: _valorONulo(_tratamientoCtrl),
        observaciones: _valorONulo(_observacionesCtrl),
      );
    } else {
      exito = await notifier.crear(
        idCita: _idCitaSeleccionada,
        fecha: _fecha,
        anamnesis: _valorONulo(_anamnesisCtrl),
        exploracionFisica: _valorONulo(_exploracionFisicaCtrl),
        diagnostico: _valorONulo(_diagnosticoCtrl),
        tratamiento: _valorONulo(_tratamientoCtrl),
        observaciones: _valorONulo(_observacionesCtrl),
      );
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    if (exito) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? 'Registro actualizado correctamente'
                : 'Registro creado correctamente',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error =
          ref.read(registrosClinicosProvider(widget.paciente.id)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al guardar registro'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final estadoCitas = ref.watch(citasProvider);
    final citasVinculables = estadoCitas.citas.where((c) =>
        c.idPaciente == widget.paciente.id &&
        (c.estado == 'programada' || c.estado == 'completada')).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_esEdicion ? 'Editar Registro' : 'Nuevo Registro'),
            Text(
              widget.paciente.nombreCompleto,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cita vinculada ────────────────────────────────────────────
              if (!_esEdicion && citasVinculables.isNotEmpty) ...[
                Text(
                  'Cita asociada',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _idCitaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Vincular a una cita (opcional)',
                    prefixIcon: Icon(Icons.event_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin cita asociada'),
                    ),
                    ...citasVinculables.map((c) {
                      final fecha =
                          DateFormat('dd/MM/yyyy HH:mm').format(c.fechaHora.toLocal());
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(fecha, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _idCitaSeleccionada = valor;
                      // Autocompletar fecha con la de la cita seleccionada
                      if (valor != null) {
                        final cita = citasVinculables
                            .firstWhere((c) => c.id == valor);
                        _fecha = cita.fechaHora.toLocal();
                      }
                    });
                  },
                ),
                const SizedBox(height: 28),
              ],

              // ── Fecha ─────────────────────────────────────────────────────
              Text(
                'Fecha',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _seleccionarFecha,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha del registro',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.edit_calendar_outlined),
                  ),
                  child: Text(
                    formatoFecha.format(_fecha),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Consulta ──────────────────────────────────────────────────
              Text(
                'Consulta',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _anamnesisCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Anamnesis / Motivo de consulta',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _exploracionFisicaCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Exploración física',
                  prefixIcon: Icon(Icons.search_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 28),

              // ── Diagnóstico y tratamiento ─────────────────────────────────
              Text(
                'Diagnóstico y tratamiento',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _diagnosticoCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Diagnóstico',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _tratamientoCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Tratamiento / Indicaciones',
                  prefixIcon: Icon(Icons.medication_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 28),

              // ── Observaciones ─────────────────────────────────────────────
              Text(
                'Observaciones',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _observacionesCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observaciones adicionales',
                  prefixIcon: Icon(Icons.comment_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 36),

              FilledButton(
                onPressed: _guardando ? null : _guardar,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _esEdicion ? 'Guardar cambios' : 'Guardar registro',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
