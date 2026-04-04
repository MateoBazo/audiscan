import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paciente_modelo.dart';
import '../../../core/api/api_client.dart';

class PacientesRepositorio {
  final Dio _dio;

  PacientesRepositorio(this._dio);

  Future<List<PacienteModelo>> obtenerPacientes() async {
    final respuesta = await _dio.get('/pacientes/');
    return (respuesta.data as List)
        .map((json) => PacienteModelo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PacienteModelo> crearPaciente({
    required String nombreCompleto,
    DateTime? fechaNacimiento,
    Map<String, dynamic>? informacionContacto,
  }) async {
    final datos = <String, dynamic>{
      'nombre_completo': nombreCompleto,
      if (fechaNacimiento != null)
        'fecha_nacimiento':
            '${fechaNacimiento.year.toString().padLeft(4, '0')}-'
            '${fechaNacimiento.month.toString().padLeft(2, '0')}-'
            '${fechaNacimiento.day.toString().padLeft(2, '0')}',
      if (informacionContacto != null && informacionContacto.isNotEmpty)
        'informacion_contacto': informacionContacto,
    };
    final respuesta = await _dio.post('/pacientes/', data: datos);
    return PacienteModelo.fromJson(respuesta.data as Map<String, dynamic>);
  }

  Future<PacienteModelo> actualizarPaciente({
    required String id,
    String? nombreCompleto,
    DateTime? fechaNacimiento,
    Map<String, dynamic>? informacionContacto,
  }) async {
    final datos = <String, dynamic>{
      if (nombreCompleto != null) 'nombre_completo': nombreCompleto,
      if (fechaNacimiento != null)
        'fecha_nacimiento':
            '${fechaNacimiento.year.toString().padLeft(4, '0')}-'
            '${fechaNacimiento.month.toString().padLeft(2, '0')}-'
            '${fechaNacimiento.day.toString().padLeft(2, '0')}',
      if (informacionContacto != null)
        'informacion_contacto': informacionContacto,
    };
    final respuesta = await _dio.put('/pacientes/$id', data: datos);
    return PacienteModelo.fromJson(respuesta.data as Map<String, dynamic>);
  }

  Future<void> eliminarPaciente(String id) async {
    await _dio.delete('/pacientes/$id');
  }
}

final pacientesRepositorioProvider = Provider<PacientesRepositorio>(
  (ref) => PacientesRepositorio(ref.read(dioProvider)),
);
