import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../models/paciente_modelo.dart';
import '../providers/pacientes_provider.dart';
import '../../../core/widgets/boton_guardar.dart';
import '../../../core/widgets/campo_fecha.dart';
import '../../../core/widgets/encabezado_seccion.dart';
import '../../../core/widgets/mapa_miniatura.dart';
import '../../../core/widgets/selector_mapa_pantalla.dart';

class RegistrarPacientePantalla extends ConsumerStatefulWidget {
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
  double? _latitud;
  double? _longitud;
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
    _latitud = p?.latitud;
    _longitud = p?.longitud;
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

  Future<void> _seleccionarUbicacion() async {
    final puntoInicial = _latitud != null && _longitud != null
        ? LatLng(_latitud!, _longitud!)
        : null;

    final resultado = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => SelectorMapaPantalla(puntoInicial: puntoInicial),
      ),
    );

    if (resultado != null) {
      setState(() {
        _latitud = resultado.latitude;
        _longitud = resultado.longitude;
      });
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
    if (_latitud != null && _longitud != null) {
      informacionContacto['latitud'] = _latitud;
      informacionContacto['longitud'] = _longitud;
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
              const EncabezadoSeccion(titulo: 'Datos personales'),
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

              CampoFecha(
                fecha: _fechaNacimiento,
                etiqueta: 'Fecha de nacimiento',
                iconoPrefijo: Icons.cake_outlined,
                iconoSufijo: Icons.calendar_today_outlined,
                textoPorDefecto: 'Seleccionar fecha',
                onTap: _seleccionarFecha,
              ),

              const SizedBox(height: 28),
              const EncabezadoSeccion(titulo: 'Información de contacto'),
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
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _seleccionarUbicacion,
                icon: const Icon(Icons.map_outlined),
                label: Text(
                  _latitud != null ? 'Cambiar ubicación en mapa' : 'Ubicar en mapa',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              if (_latitud != null && _longitud != null) ...[
                const SizedBox(height: 12),
                MapaMiniatura(latitud: _latitud!, longitud: _longitud!),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _latitud = null;
                      _longitud = null;
                    }),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Quitar ubicación'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 36),

              BotonGuardar(
                guardando: _guardando,
                onPressed: _guardar,
                etiqueta: _esEdicion ? 'Guardar cambios' : 'Registrar paciente',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
