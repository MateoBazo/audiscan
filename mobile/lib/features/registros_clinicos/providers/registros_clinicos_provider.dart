import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/registros_clinicos_repositorio.dart';
import '../models/registro_clinico_modelo.dart';

// ─── Estado ───────────────────────────────────────────────────────────────────

class RegistrosClinicosEstado {
  final List<RegistroClinicoModelo> registros;
  final bool cargando;
  final String? error;

  const RegistrosClinicosEstado({
    this.registros = const [],
    this.cargando = false,
    this.error,
  });

  RegistrosClinicosEstado copyWith({
    List<RegistroClinicoModelo>? registros,
    bool? cargando,
    String? error,
    bool limpiarError = false,
  }) {
    return RegistrosClinicosEstado(
      registros: registros ?? this.registros,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : error ?? this.error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class RegistrosClinicosNotifier
    extends StateNotifier<RegistrosClinicosEstado> {
  final RegistrosClinicosRepositorio _repositorio;
  final String _idPaciente;

  RegistrosClinicosNotifier(this._repositorio, this._idPaciente)
      : super(const RegistrosClinicosEstado()) {
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final lista = await _repositorio.obtenerPorPaciente(_idPaciente);
      state = state.copyWith(registros: lista, cargando: false);
    } on DioException catch (e) {
      state = state.copyWith(cargando: false, error: _parsearError(e));
    } catch (_) {
      state = state.copyWith(
          cargando: false, error: 'Error al cargar historial clínico');
    }
  }

  Future<bool> crear({
    String? idCita,
    DateTime? fecha,
    String? anamnesis,
    String? exploracionFisica,
    String? diagnostico,
    String? tratamiento,
    String? observaciones,
  }) async {
    try {
      final nuevo = await _repositorio.crear(
        idPaciente: _idPaciente,
        idCita: idCita,
        fecha: fecha,
        anamnesis: anamnesis,
        exploracionFisica: exploracionFisica,
        diagnostico: diagnostico,
        tratamiento: tratamiento,
        observaciones: observaciones,
      );
      state = state.copyWith(registros: [nuevo, ...state.registros]);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parsearError(e));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error al crear registro clínico');
      return false;
    }
  }

  Future<bool> actualizar({
    required String id,
    DateTime? fecha,
    String? anamnesis,
    String? exploracionFisica,
    String? diagnostico,
    String? tratamiento,
    String? observaciones,
  }) async {
    try {
      final actualizado = await _repositorio.actualizar(
        id: id,
        fecha: fecha,
        anamnesis: anamnesis,
        exploracionFisica: exploracionFisica,
        diagnostico: diagnostico,
        tratamiento: tratamiento,
        observaciones: observaciones,
      );
      state = state.copyWith(
        registros: state.registros
            .map((r) => r.id == id ? actualizado : r)
            .toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parsearError(e));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error al actualizar registro clínico');
      return false;
    }
  }

  Future<bool> eliminar(String id) async {
    try {
      await _repositorio.eliminar(id);
      state = state.copyWith(
        registros: state.registros.where((r) => r.id != id).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parsearError(e));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error al eliminar registro clínico');
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

// ─── Provider family (uno por paciente) ──────────────────────────────────────

final registrosClinicosProvider = StateNotifierProvider.family<
    RegistrosClinicosNotifier, RegistrosClinicosEstado, String>(
  (ref, idPaciente) => RegistrosClinicosNotifier(
    ref.read(registrosClinicosRepositorioProvider),
    idPaciente,
  ),
);
