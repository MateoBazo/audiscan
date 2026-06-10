import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audiometria_modelo.dart';
import '../../../core/api/api_client.dart';

class AudiometriaRepositorio {
  final Dio _dio;

  AudiometriaRepositorio(this._dio);

  Future<SesionAudiometriaModelo> crear({
    required String idRegistro,
    required double odHz250,
    required double odHz500,
    required double odHz1000,
    required double odHz2000,
    required double odHz4000,
    required double odHz8000,
    required double oiHz250,
    required double oiHz500,
    required double oiHz1000,
    required double oiHz2000,
    required double oiHz4000,
    required double oiHz8000,
    String? observaciones,
  }) async {
    final respuesta = await _dio.post('/audiometria/', data: {
      'id_registro': idRegistro,
      'od_250hz': odHz250,
      'od_500hz': odHz500,
      'od_1000hz': odHz1000,
      'od_2000hz': odHz2000,
      'od_4000hz': odHz4000,
      'od_8000hz': odHz8000,
      'oi_250hz': oiHz250,
      'oi_500hz': oiHz500,
      'oi_1000hz': oiHz1000,
      'oi_2000hz': oiHz2000,
      'oi_4000hz': oiHz4000,
      'oi_8000hz': oiHz8000,
      if (observaciones != null && observaciones.isNotEmpty)
        'observaciones': observaciones,
    });
    return SesionAudiometriaModelo.fromJson(
        respuesta.data as Map<String, dynamic>);
  }

  Future<List<SesionAudiometriaModelo>> obtenerPorRegistro(
      String idRegistro) async {
    final respuesta =
        await _dio.get('/audiometria/registro/$idRegistro');
    return (respuesta.data as List)
        .map((json) =>
            SesionAudiometriaModelo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<SesionAudiometriaModelo> obtenerPorId(String idSesion) async {
    final respuesta = await _dio.get('/audiometria/$idSesion');
    return SesionAudiometriaModelo.fromJson(
        respuesta.data as Map<String, dynamic>);
  }

  Future<void> eliminar(String idSesion) async {
    await _dio.delete('/audiometria/$idSesion');
  }
}

final audiometriaRepositorioProvider = Provider<AudiometriaRepositorio>(
  (ref) => AudiometriaRepositorio(ref.read(dioProvider)),
);
