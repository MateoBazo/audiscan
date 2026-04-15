import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/imagen_timpanica_modelo.dart';
import '../../../core/api/api_client.dart';

class ImagenesTimpanicasRepositorio {
  final Dio _dio;

  ImagenesTimpanicasRepositorio(this._dio);

  Future<ImagenTimpanicaModelo> subir({
    required String idRegistro,
    required File archivo,
    required String oido,
  }) async {
    final formData = FormData.fromMap({
      'id_registro': idRegistro,
      'oido': oido,
      'archivo': await MultipartFile.fromFile(
        archivo.path,
        filename: archivo.path.split('/').last,
      ),
    });

    final respuesta = await _dio.post(
      '/imagenes-timpanicas/',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    return ImagenTimpanicaModelo.fromJson(
        respuesta.data as Map<String, dynamic>);
  }

  Future<List<ImagenTimpanicaModelo>> obtenerPorRegistro(
      String idRegistro) async {
    final respuesta = await _dio
        .get('/imagenes-timpanicas/registro/$idRegistro');
    return (respuesta.data as List)
        .map((json) =>
            ImagenTimpanicaModelo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ImagenTimpanicaModelo> obtenerPorId(String idImagen) async {
    final respuesta =
        await _dio.get('/imagenes-timpanicas/$idImagen');
    return ImagenTimpanicaModelo.fromJson(
        respuesta.data as Map<String, dynamic>);
  }
}

final imagenesTimpanicasRepositorioProvider =
    Provider<ImagenesTimpanicasRepositorio>(
  (ref) => ImagenesTimpanicasRepositorio(ref.read(dioProvider)),
);
