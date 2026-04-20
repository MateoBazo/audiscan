import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/cita_modelo.dart';
import '../providers/citas_provider.dart';
import '../../pacientes/providers/pacientes_provider.dart';
import '../../../core/widgets/boton_guardar.dart';
import '../../../core/widgets/campo_fecha.dart';
import '../../../core/widgets/encabezado_seccion.dart';

const _opcionesDuracion = [15, 30, 45, 60, 90];

class RegistrarCitaPantalla extends ConsumerStatefulWidget {
  final CitaModelo? cita;

  const RegistrarCitaPantalla({super.key, this.cita});

  @override
  ConsumerState<RegistrarCitaPantalla> createState() =>
      _RegistrarCitaPantallaState();
}

class _RegistrarCitaPantallaState extends ConsumerState<RegistrarCitaPantalla> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _motivoCtrl;
  late final TextEditingController _notasCtrl;

  String? _idPacienteSeleccionado;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  int _duracionMinutos = 30;
  bool _guardando = false;

  bool get _esEdicion => widget.cita != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cita;
    _motivoCtrl = TextEditingController(text: c?.motivo ?? '');
    _notasCtrl = TextEditingController(text: c?.notas ?? '');

    if (c != null) {
      _idPacienteSeleccionado = c.idPaciente;
      _fechaSeleccionada = c.fechaHora.toLocal();
      _horaSeleccionada = TimeOfDay.fromDateTime(c.fechaHora.toLocal());
      _duracionMinutos = c.duracionMinutos;
    }
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? ahora,
      firstDate: ahora.subtract(const Duration(days: 365)),
      lastDate: ahora.add(const Duration(days: 365 * 2)),
      helpText: 'Fecha de la cita',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (seleccionada != null) {
      setState(() => _fechaSeleccionada = seleccionada);
    }
  }

  Future<void> _seleccionarHora() async {
    final seleccionada = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Hora de la cita',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (seleccionada != null) {
      setState(() => _horaSeleccionada = seleccionada);
    }
  }

  DateTime _combinarFechaHora() {
    final fecha = _fechaSeleccionada!;
    final hora = _horaSeleccionada!;
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final fechaHora = _combinarFechaHora();
    final motivo =
        _motivoCtrl.text.trim().isNotEmpty ? _motivoCtrl.text.trim() : null;
    final notas =
        _notasCtrl.text.trim().isNotEmpty ? _notasCtrl.text.trim() : null;

    final bool exito;

    if (_esEdicion) {
      exito = await ref.read(citasProvider.notifier).actualizar(
            id: widget.cita!.id,
            idPaciente: _idPacienteSeleccionado,
            fechaHora: fechaHora,
            duracionMinutos: _duracionMinutos,
            motivo: motivo,
            notas: notas,
          );
    } else {
      exito = await ref.read(citasProvider.notifier).crear(
            idPaciente: _idPacienteSeleccionado!,
            fechaHora: fechaHora,
            duracionMinutos: _duracionMinutos,
            motivo: motivo,
            notas: notas,
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
                ? 'Cita actualizada correctamente'
                : 'Cita registrada correctamente',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error = ref.read(citasProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al guardar cita'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pacientes = ref.watch(pacientesProvider).pacientes;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Cita' : 'Nueva Cita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EncabezadoSeccion(titulo: 'Paciente'),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _idPacienteSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar paciente *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                items: pacientes.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text(p.nombreCompleto),
                  );
                }).toList(),
                onChanged: (valor) =>
                    setState(() => _idPacienteSeleccionado = valor),
                validator: (v) =>
                    v == null ? 'Seleccioná un paciente' : null,
              ),

              const SizedBox(height: 28),
              const EncabezadoSeccion(titulo: 'Fecha y hora'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: FormField<DateTime>(
                      validator: (_) => _fechaSeleccionada == null
                          ? 'Seleccioná una fecha'
                          : null,
                      builder: (fieldState) => CampoFecha(
                        fecha: _fechaSeleccionada,
                        etiqueta: 'Fecha *',
                        onTap: _seleccionarFecha,
                        errorText: fieldState.errorText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FormField<TimeOfDay>(
                      validator: (_) => _horaSeleccionada == null
                          ? 'Seleccioná una hora'
                          : null,
                      builder: (fieldState) => InkWell(
                        onTap: _seleccionarHora,
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Hora *',
                            prefixIcon:
                                const Icon(Icons.access_time_outlined),
                            border: const OutlineInputBorder(),
                            errorText: fieldState.errorText,
                          ),
                          child: Text(
                            _horaSeleccionada != null
                                ? _horaSeleccionada!.format(context)
                                : 'Seleccionar',
                            style: _horaSeleccionada != null
                                ? theme.textTheme.bodyLarge
                                : theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _duracionMinutos,
                decoration: const InputDecoration(
                  labelText: 'Duración',
                  prefixIcon: Icon(Icons.timelapse_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _opcionesDuracion.map((min) {
                  return DropdownMenuItem(
                    value: min,
                    child: Text('$min minutos'),
                  );
                }).toList(),
                onChanged: (valor) =>
                    setState(() => _duracionMinutos = valor ?? 30),
              ),

              const SizedBox(height: 28),
              const EncabezadoSeccion(titulo: 'Detalles'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _motivoCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Motivo de consulta',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notasCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 36),

              BotonGuardar(
                guardando: _guardando,
                onPressed: _guardar,
                etiqueta: _esEdicion ? 'Guardar cambios' : 'Registrar cita',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
