import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audiometria/models/audiometria_modelo.dart';
import '../../imagenes_timpanicas/models/imagen_timpanica_modelo.dart';
import '../../registros_clinicos/models/registro_clinico_modelo.dart';
import '../../../core/api/api_client.dart';

class PacientePortalRepositorio {
  final Dio _dio;

  PacientePortalRepositorio(this._dio);

  Future<List<RegistroClinicoModelo>> obtenerHistorial() async {
    final respuesta = await _dio.get('/mi-portal/historial');
    return (respuesta.data as List)
        .map((json) => RegistroClinicoModelo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ImagenTimpanicaModelo>> obtenerImagenes() async {
    final respuesta = await _dio.get('/mi-portal/imagenes');
    return (respuesta.data as List)
        .map((json) => ImagenTimpanicaModelo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<SesionAudiometriaModelo>> obtenerAudiometrias() async {
    final respuesta = await _dio.get('/mi-portal/audiometrias');
    return (respuesta.data as List)
        .map((json) => SesionAudiometriaModelo.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

final pacientePortalRepositorioProvider = Provider<PacientePortalRepositorio>(
  (ref) => PacientePortalRepositorio(ref.read(dioProvider)),
);
