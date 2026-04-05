import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/registro_clinico_modelo.dart';
import '../../../core/api/api_client.dart';

class RegistrosClinicosRepositorio {
  final Dio _dio;

  RegistrosClinicosRepositorio(this._dio);

  Future<List<RegistroClinicoModelo>> obtenerPorPaciente(
      String idPaciente) async {
    final respuesta =
        await _dio.get('/registros-clinicos/paciente/$idPaciente');
    return (respuesta.data as List)
        .map((json) =>
            RegistroClinicoModelo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<RegistroClinicoModelo> crear({
    required String idPaciente,
    String? idCita,
    DateTime? fecha,
    String? anamnesis,
    String? exploracionFisica,
    String? diagnostico,
    String? tratamiento,
    String? observaciones,
  }) async {
    final datos = <String, dynamic>{
      'id_paciente': idPaciente,
      if (idCita != null) 'id_cita': idCita,
      if (fecha != null)
        'fecha':
            '${fecha.year.toString().padLeft(4, '0')}-'
            '${fecha.month.toString().padLeft(2, '0')}-'
            '${fecha.day.toString().padLeft(2, '0')}',
      if (anamnesis != null) 'anamnesis': anamnesis,
      if (exploracionFisica != null) 'exploracion_fisica': exploracionFisica,
      if (diagnostico != null) 'diagnostico': diagnostico,
      if (tratamiento != null) 'tratamiento': tratamiento,
      if (observaciones != null) 'observaciones': observaciones,
    };
    final respuesta = await _dio.post('/registros-clinicos/', data: datos);
    return RegistroClinicoModelo.fromJson(
        respuesta.data as Map<String, dynamic>);
  }

  Future<RegistroClinicoModelo> actualizar({
    required String id,
    DateTime? fecha,
    String? anamnesis,
    String? exploracionFisica,
    String? diagnostico,
    String? tratamiento,
    String? observaciones,
  }) async {
    final datos = <String, dynamic>{
      if (fecha != null)
        'fecha':
            '${fecha.year.toString().padLeft(4, '0')}-'
            '${fecha.month.toString().padLeft(2, '0')}-'
            '${fecha.day.toString().padLeft(2, '0')}',
      if (anamnesis != null) 'anamnesis': anamnesis,
      if (exploracionFisica != null) 'exploracion_fisica': exploracionFisica,
      if (diagnostico != null) 'diagnostico': diagnostico,
      if (tratamiento != null) 'tratamiento': tratamiento,
      if (observaciones != null) 'observaciones': observaciones,
    };
    final respuesta =
        await _dio.put('/registros-clinicos/$id', data: datos);
    return RegistroClinicoModelo.fromJson(
        respuesta.data as Map<String, dynamic>);
  }

  Future<void> eliminar(String id) async {
    await _dio.delete('/registros-clinicos/$id');
  }
}

final registrosClinicosRepositorioProvider =
    Provider<RegistrosClinicosRepositorio>(
  (ref) => RegistrosClinicosRepositorio(ref.read(dioProvider)),
);
