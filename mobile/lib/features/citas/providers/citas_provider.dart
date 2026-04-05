import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/citas_repositorio.dart';
import '../models/cita_modelo.dart';
import '../../pacientes/providers/pacientes_provider.dart';

// ─── Estado ───────────────────────────────────────────────────────────────────

class CitasEstado {
  final List<CitaModelo> citas;
  final bool cargando;
  final String? error;
  final String? filtroEstado; // null = todas

  const CitasEstado({
    this.citas = const [],
    this.cargando = false,
    this.error,
    this.filtroEstado,
  });

  CitasEstado copyWith({
    List<CitaModelo>? citas,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    Object? filtroEstado = _sentinel,
  }) {
    return CitasEstado(
      citas: citas ?? this.citas,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : error ?? this.error,
      filtroEstado: filtroEstado == _sentinel
          ? this.filtroEstado
          : filtroEstado as String?,
    );
  }

  List<CitaModelo> get citasFiltradas {
    if (filtroEstado == null) return citas;
    return citas.where((c) => c.estado == filtroEstado).toList();
  }
}

const _sentinel = Object();

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CitasNotifier extends StateNotifier<CitasEstado> {
  final CitasRepositorio _repositorio;
  final Ref _ref;

  CitasNotifier(this._repositorio, this._ref) : super(const CitasEstado()) {
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final lista = await _repositorio.obtenerCitas();
      final citasConNombre = _agregarNombresPacientes(lista);
      state = state.copyWith(citas: citasConNombre, cargando: false);
    } on DioException catch (e) {
      state = state.copyWith(cargando: false, error: _parsearError(e));
    } catch (_) {
      state = state.copyWith(cargando: false, error: 'Error al cargar citas');
    }
  }

  void aplicarFiltro(String? estado) {
    state = state.copyWith(filtroEstado: estado);
  }

  Future<bool> crear({
    required String idPaciente,
    required DateTime fechaHora,
    int duracionMinutos = 30,
    String? motivo,
    String? notas,
  }) async {
    try {
      final nueva = await _repositorio.crearCita(
        idPaciente: idPaciente,
        fechaHora: fechaHora,
        duracionMinutos: duracionMinutos,
        motivo: motivo,
        notas: notas,
      );
      final conNombre = _agregarNombresPacientes([nueva]);
      state = state.copyWith(citas: [...conNombre, ...state.citas]);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parsearError(e));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error al registrar cita');
      return false;
    }
  }

  Future<bool> actualizar({
    required String id,
    String? idPaciente,
    DateTime? fechaHora,
    int? duracionMinutos,
    String? motivo,
    String? notas,
  }) async {
    try {
      final actualizada = await _repositorio.actualizarCita(
        id: id,
        idPaciente: idPaciente,
        fechaHora: fechaHora,
        duracionMinutos: duracionMinutos,
        motivo: motivo,
        notas: notas,
      );
      final conNombre = _agregarNombresPacientes([actualizada]);
      state = state.copyWith(
        citas: state.citas.map((c) => c.id == id ? conNombre.first : c).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parsearError(e));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error al actualizar cita');
      return false;
    }
  }

  Future<bool> cambiarEstado(String id, String nuevoEstado) async {
    try {
      await _repositorio.cambiarEstado(id: id, estado: nuevoEstado);
      state = state.copyWith(
        citas: state.citas
            .map((c) => c.id == id ? c.copyWith(estado: nuevoEstado) : c)
            .toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parsearError(e));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error al cambiar estado');
      return false;
    }
  }

  Future<bool> eliminar(String id) async {
    try {
      await _repositorio.eliminarCita(id);
      state = state.copyWith(
        citas: state.citas.where((c) => c.id != id).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _parsearError(e));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error al eliminar cita');
      return false;
    }
  }

  // Enriquece la lista de citas con el nombre del paciente del provider existente
  List<CitaModelo> _agregarNombresPacientes(List<CitaModelo> citas) {
    final pacientes = _ref.read(pacientesProvider).pacientes;
    return citas.map((cita) {
      final paciente = pacientes
          .where((p) => p.id == cita.idPaciente)
          .firstOrNull;
      return cita.copyWith(nombrePaciente: paciente?.nombreCompleto);
    }).toList();
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

final citasProvider = StateNotifierProvider<CitasNotifier, CitasEstado>(
  (ref) => CitasNotifier(ref.read(citasRepositorioProvider), ref),
);
