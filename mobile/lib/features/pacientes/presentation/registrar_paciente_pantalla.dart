import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/paciente_modelo.dart';
import '../providers/pacientes_provider.dart';

class RegistrarPacientePantalla extends ConsumerStatefulWidget {
  // Si paciente viene con datos, el formulario actúa en modo edición
  final PacienteModelo? paciente;

  const RegistrarPacientePantalla({super.key, this.paciente});

  @override
  ConsumerState<RegistrarPacientePantalla> createState() =>
      _RegistrarPacientePantallaState();
}

class _RegistrarPacientePantallaState
    extends ConsumerState<RegistrarPacientePantalla> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _emailContactoCtrl;
  late final TextEditingController _direccionCtrl;

  DateTime? _fechaNacimiento;
  bool _guardando = false;

  bool get _esEdicion => widget.paciente != null;

  @override
  void initState() {
    super.initState();
    final p = widget.paciente;
    _nombreCtrl = TextEditingController(text: p?.nombreCompleto ?? '');
    _telefonoCtrl = TextEditingController(text: p?.telefono ?? '');
    _emailContactoCtrl = TextEditingController(text: p?.emailContacto ?? '');
    _direccionCtrl = TextEditingController(text: p?.direccion ?? '');
    _fechaNacimiento = p?.fechaNacimiento;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailContactoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(1980),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (seleccionada != null) {
      setState(() => _fechaNacimiento = seleccionada);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final informacionContacto = <String, dynamic>{};
    if (_telefonoCtrl.text.trim().isNotEmpty) {
      informacionContacto['telefono'] = _telefonoCtrl.text.trim();
    }
    if (_emailContactoCtrl.text.trim().isNotEmpty) {
      informacionContacto['email'] = _emailContactoCtrl.text.trim();
    }
    if (_direccionCtrl.text.trim().isNotEmpty) {
      informacionContacto['direccion'] = _direccionCtrl.text.trim();
    }

    final bool exito;

    if (_esEdicion) {
      exito = await ref.read(pacientesProvider.notifier).actualizar(
            id: widget.paciente!.id,
            nombreCompleto: _nombreCtrl.text.trim(),
            fechaNacimiento: _fechaNacimiento,
            informacionContacto: informacionContacto,
          );
    } else {
      exito = await ref.read(pacientesProvider.notifier).crear(
            nombreCompleto: _nombreCtrl.text.trim(),
            fechaNacimiento: _fechaNacimiento,
            informacionContacto:
                informacionContacto.isNotEmpty ? informacionContacto : null,
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
                ? 'Paciente actualizado correctamente'
                : 'Paciente registrado correctamente',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error = ref.read(pacientesProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al guardar paciente'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Paciente' : 'Nuevo Paciente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Datos personales ──────────────────────────────────────────
              Text(
                'Datos personales',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (v.trim().length < 3) return 'Ingresá el nombre completo';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _seleccionarFecha,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    prefixIcon: Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _fechaNacimiento != null
                        ? DateFormat('dd/MM/yyyy').format(_fechaNacimiento!)
                        : 'Seleccionar fecha',
                    style: _fechaNacimiento != null
                        ? theme.textTheme.bodyLarge
                        : theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Información de contacto ───────────────────────────────────
              Text(
                'Información de contacto',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailContactoCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty && !v.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _direccionCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
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
                        _esEdicion ? 'Guardar cambios' : 'Registrar paciente',
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
