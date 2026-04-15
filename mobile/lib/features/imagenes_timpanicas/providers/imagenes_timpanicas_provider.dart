import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/imagenes_timpanicas_repositorio.dart';
import '../models/imagen_timpanica_modelo.dart';

// ─── Estado ───────────────────────────────────────────────────────────────────

class ImagenesTimpanicasEstado {
  final List<ImagenTimpanicaModelo> imagenes;
  final bool cargando;
  final bool subiendo;
  final String? error;

  const ImagenesTimpanicasEstado({
    this.imagenes = const [],
    this.cargando = false,
    this.subiendo = false,
    this.error,
  });

  ImagenesTimpanicasEstado copyWith({
    List<ImagenTimpanicaModelo>? imagenes,
    bool? cargando,
    bool? subiendo,
    String? error,
    bool limpiarError = false,
  }) {
    return ImagenesTimpanicasEstado(
      imagenes: imagenes ?? this.imagenes,
      cargando: cargando ?? this.cargando,
      subiendo: subiendo ?? this.subiendo,
      error: limpiarError ? null : error ?? this.error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ImagenesTimpanicasNotifier
    extends StateNotifier<ImagenesTimpanicasEstado> {
  final ImagenesTimpanicasRepositorio _repositorio;
  final String _idRegistro;

  ImagenesTimpanicasNotifier(this._repositorio, this._idRegistro)
      : super(const ImagenesTimpanicasEstado()) {
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final lista = await _repositorio.obtenerPorRegistro(_idRegistro);
      state = state.copyWith(imagenes: lista, cargando: false);
    } on DioException catch (e) {
      state = state.copyWith(cargando: false, error: _parsearError(e));
    } catch (_) {
      state = state.copyWith(
          cargando: false, error: 'Error al cargar imágenes timpánicas');
    }
  }

  Future<ImagenTimpanicaModelo?> subir({
    required File archivo,
    required String oido,
  }) async {
    state = state.copyWith(subiendo: true, limpiarError: true);
    try {
      final nueva = await _repositorio.subir(
        idRegistro: _idRegistro,
        archivo: archivo,
        oido: oido,
      );
      state = state.copyWith(
        imagenes: [nueva, ...state.imagenes],
        subiendo: false,
      );
      return nueva;
    } on DioException catch (e) {
      state = state.copyWith(subiendo: false, error: _parsearError(e));
      return null;
    } catch (_) {
      state = state.copyWith(
          subiendo: false, error: 'Error al subir imagen timpánica');
      return null;
    }
  }

  String _parsearError(DioException e) {
    final datos = e.response?.data;
    if (datos is Map && datos.containsKey('detail')) {
      return datos['detail'] as String;
    }
    return 'Error de conexión. Verificá tu red.';
  }
}

// ─── Provider family (uno por registro clínico) ───────────────────────────────

final imagenesTimpanicasProvider = StateNotifierProvider.family<
    ImagenesTimpanicasNotifier, ImagenesTimpanicasEstado, String>(
  (ref, idRegistro) => ImagenesTimpanicasNotifier(
    ref.read(imagenesTimpanicasRepositorioProvider),
    idRegistro,
  ),
);
