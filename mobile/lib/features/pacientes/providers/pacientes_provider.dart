import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pacientes_repositorio.dart';
import '../models/paciente_modelo.dart';

// ─── Estado ───────────────────────────────────────────────────────────────────

class PacientesEstado {
  final List<PacienteModelo> pacientes;
  final bool cargando;
  final String? error;

  const PacientesEstado({
    this.pacientes = const [],
    this.cargando = false,
    this.error,
  });

  PacientesEstado copyWith({
    List<PacienteModelo>? pacientes,
    bool? cargando,
    String? error,
    bool limpiarError = false,
  }) {
    return PacientesEstado(
      pacientes: pacientes ?? this.pacientes,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : error ?? this.error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class PacientesNotifier extends StateNotifier<PacientesEstado> {
  final PacientesRepositorio _repositorio;

  PacientesNotifier(this._repositorio) : super(const PacientesEstado()) {
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final lista = await _repositorio.obtenerPacientes();
      state = state.copyWith(pacientes: lista, cargando: false);
    } on DioException catch (e) {
      state = state.copyWith(cargando: false, error: _parsearError(e));
    } catch (_) {
      state = state.copyWith(
        cargando: false,
        error: 'Error al cargar pacientes',
      );
    }
  }

  Future<bool> crear({
    required String nombreCompleto,
    DateTime? fechaNacimiento,
    Map<String, dynamic>? informacionContacto,
  }) async {
    try {
      final nuevo = await _repositorio.crearPaciente(
        nombreCompleto: nombreCompleto,
        fechaNacimiento: fechaNacimiento,
        informacionContacto: informacionContacto,
      );
      state = state.copyWith(pacientes: [nuevo, ...state.pacientes]);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parsearError(e));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error al registrar paciente');
      return false;
    }
  }

  Future<bool> actualizar({
    required String id,
    required String nombreCompleto,
    DateTime? fechaNacimiento,
    Map<String, dynamic>? informacionContacto,
  }) async {
    try {
      final actualizado = await _repositorio.actualizarPaciente(
        id: id,
        nombreCompleto: nombreCompleto,
        fechaNacimiento: fechaNacimiento,
        informacionContacto: informacionContacto,
      );
      state = state.copyWith(
        pacientes: state.pacientes
            .map((p) => p.id == id ? actualizado : p)
            .toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parsearError(e));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error al actualizar paciente');
      return false;
    }
  }

  Future<bool> eliminar(String id) async {
    try {
      await _repositorio.eliminarPaciente(id);
      state = state.copyWith(
        pacientes: state.pacientes.where((p) => p.id != id).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parsearError(e));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error al eliminar paciente');
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

// ─── Provider ─────────────────────────────────────────────────────────────────

final pacientesProvider =
    StateNotifierProvider<PacientesNotifier, PacientesEstado>(
  (ref) => PacientesNotifier(ref.read(pacientesRepositorioProvider)),
);
