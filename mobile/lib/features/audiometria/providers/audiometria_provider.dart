import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/audiometria_repositorio.dart';
import '../models/audiometria_modelo.dart';

class AudiometriaEstado {
  final List<SesionAudiometriaModelo> sesiones;
  final bool cargando;
  final bool guardando;
  final String? error;

  const AudiometriaEstado({
    this.sesiones = const [],
    this.cargando = false,
    this.guardando = false,
    this.error,
  });

  AudiometriaEstado copyWith({
    List<SesionAudiometriaModelo>? sesiones,
    bool? cargando,
    bool? guardando,
    String? error,
    bool limpiarError = false,
  }) {
    return AudiometriaEstado(
      sesiones: sesiones ?? this.sesiones,
      cargando: cargando ?? this.cargando,
      guardando: guardando ?? this.guardando,
      error: limpiarError ? null : error ?? this.error,
    );
  }
}

class AudiometriaNotifier extends StateNotifier<AudiometriaEstado> {
  final AudiometriaRepositorio _repositorio;
  final String _idRegistro;

  AudiometriaNotifier(this._repositorio, this._idRegistro)
      : super(const AudiometriaEstado()) {
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final lista = await _repositorio.obtenerPorRegistro(_idRegistro);
      state = state.copyWith(sesiones: lista, cargando: false);
    } on DioException catch (e) {
      state = state.copyWith(cargando: false, error: _parsearError(e));
    } catch (_) {
      state = state.copyWith(
          cargando: false, error: 'Error al cargar sesiones de audiometría');
    }
  }

  Future<SesionAudiometriaModelo?> crear({
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
    state = state.copyWith(guardando: true, limpiarError: true);
    try {
      final nueva = await _repositorio.crear(
        idRegistro: _idRegistro,
        odHz250: odHz250,
        odHz500: odHz500,
        odHz1000: odHz1000,
        odHz2000: odHz2000,
        odHz4000: odHz4000,
        odHz8000: odHz8000,
        oiHz250: oiHz250,
        oiHz500: oiHz500,
        oiHz1000: oiHz1000,
        oiHz2000: oiHz2000,
        oiHz4000: oiHz4000,
        oiHz8000: oiHz8000,
        observaciones: observaciones,
      );
      state = state.copyWith(
        sesiones: [nueva, ...state.sesiones],
        guardando: false,
      );
      return nueva;
    } on DioException catch (e) {
      state = state.copyWith(guardando: false, error: _parsearError(e));
      return null;
    } catch (_) {
      state = state.copyWith(
          guardando: false, error: 'Error al guardar audiometría');
      return null;
    }
  }

  Future<bool> eliminar(String idSesion) async {
    try {
      await _repositorio.eliminar(idSesion);
      state = state.copyWith(
        sesiones: state.sesiones.where((s) => s.id != idSesion).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parsearError(e));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error al eliminar audiometría');
      return false;
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

final audiometriaProvider = StateNotifierProvider.family<AudiometriaNotifier,
    AudiometriaEstado, String>(
  (ref, idRegistro) => AudiometriaNotifier(
    ref.read(audiometriaRepositorioProvider),
    idRegistro,
  ),
);
