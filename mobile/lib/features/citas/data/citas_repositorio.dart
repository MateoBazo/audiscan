import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cita_modelo.dart';
import '../../../core/api/api_client.dart';

class CitasRepositorio {
  final Dio _dio;

  CitasRepositorio(this._dio);

  Future<List<CitaModelo>> obtenerCitas({String? estado}) async {
    final parametros = <String, dynamic>{
      if (estado != null) 'estado': estado,
    };
    final respuesta = await _dio.get('/citas/', queryParameters: parametros);
    return (respuesta.data as List)
        .map((json) => CitaModelo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CitaModelo> crearCita({
    required String idPaciente,
    required DateTime fechaHora,
    int duracionMinutos = 30,
    String? motivo,
    String? notas,
  }) async {
    final datos = <String, dynamic>{
      'id_paciente': idPaciente,
      'fecha_hora': fechaHora.toIso8601String(),
      'duracion_minutos': duracionMinutos,
      if (motivo != null) 'motivo': motivo,
      if (notas != null) 'notas': notas,
    };
    final respuesta = await _dio.post('/citas/', data: datos);
    return CitaModelo.fromJson(respuesta.data as Map<String, dynamic>);
  }

  Future<CitaModelo> actualizarCita({
    required String id,
    String? idPaciente,
    DateTime? fechaHora,
    int? duracionMinutos,
    String? motivo,
    String? notas,
  }) async {
    final datos = <String, dynamic>{
      if (idPaciente != null) 'id_paciente': idPaciente,
      if (fechaHora != null) 'fecha_hora': fechaHora.toIso8601String(),
      if (duracionMinutos != null) 'duracion_minutos': duracionMinutos,
      if (motivo != null) 'motivo': motivo,
      if (notas != null) 'notas': notas,
    };
    final respuesta = await _dio.put('/citas/$id', data: datos);
    return CitaModelo.fromJson(respuesta.data as Map<String, dynamic>);
  }

  Future<CitaModelo> cambiarEstado({
    required String id,
    required String estado,
  }) async {
    final respuesta = await _dio.patch(
      '/citas/$id/estado',
      data: {'estado': estado},
    );
    return CitaModelo.fromJson(respuesta.data as Map<String, dynamic>);
  }

  Future<void> eliminarCita(String id) async {
    await _dio.delete('/citas/$id');
  }
}

final citasRepositorioProvider = Provider<CitasRepositorio>(
  (ref) => CitasRepositorio(ref.read(dioProvider)),
);
