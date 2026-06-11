import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audiometria/models/audiometria_modelo.dart';
import '../../imagenes_timpanicas/models/imagen_timpanica_modelo.dart';
import '../../registros_clinicos/models/registro_clinico_modelo.dart';
import '../data/paciente_portal_repositorio.dart';

class PacientePortalEstado {
  final List<RegistroClinicoModelo> registros;
  final List<ImagenTimpanicaModelo> imagenes;
  final List<SesionAudiometriaModelo> audiometrias;
  final bool cargando;
  final String? error;

  const PacientePortalEstado({
    this.registros = const [],
    this.imagenes = const [],
    this.audiometrias = const [],
    this.cargando = false,
    this.error,
  });

  PacientePortalEstado copyWith({
    List<RegistroClinicoModelo>? registros,
    List<ImagenTimpanicaModelo>? imagenes,
    List<SesionAudiometriaModelo>? audiometrias,
    bool? cargando,
    String? error,
    bool limpiarError = false,
  }) {
    return PacientePortalEstado(
      registros: registros ?? this.registros,
      imagenes: imagenes ?? this.imagenes,
      audiometrias: audiometrias ?? this.audiometrias,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : error ?? this.error,
    );
  }
}

class PacientePortalNotifier extends StateNotifier<PacientePortalEstado> {
  final PacientePortalRepositorio _repositorio;

  PacientePortalNotifier(this._repositorio) : super(const PacientePortalEstado()) {
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final resultados = await Future.wait([
        _repositorio.obtenerHistorial(),
        _repositorio.obtenerImagenes(),
        _repositorio.obtenerAudiometrias(),
      ]);
      state = state.copyWith(
        registros: resultados[0] as List<RegistroClinicoModelo>,
        imagenes: resultados[1] as List<ImagenTimpanicaModelo>,
        audiometrias: resultados[2] as List<SesionAudiometriaModelo>,
        cargando: false,
      );
    } on DioException catch (e) {
      final datos = e.response?.data;
      final mensaje = (datos is Map && datos.containsKey('detail'))
          ? datos['detail'] as String
          : 'Error al cargar datos. Verificá tu conexión.';
      state = state.copyWith(cargando: false, error: mensaje);
    } catch (_) {
      state = state.copyWith(cargando: false, error: 'Error inesperado al cargar datos.');
    }
  }
}

final pacientePortalProvider =
    StateNotifierProvider<PacientePortalNotifier, PacientePortalEstado>(
  (ref) => PacientePortalNotifier(ref.read(pacientePortalRepositorioProvider)),
);
