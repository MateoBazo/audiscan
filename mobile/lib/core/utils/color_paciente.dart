import 'package:flutter/material.dart';

// Paleta de colores agradables para avatares
const _paleta = [
  Color(0xFF1E88E5), // azul
  Color(0xFF43A047), // verde
  Color(0xFF8E24AA), // morado
  Color(0xFFE53935), // rojo
  Color(0xFFFF8F00), // ámbar
  Color(0xFF00ACC1), // cyan
  Color(0xFF6D4C41), // marrón
  Color(0xFF3949AB), // índigo
  Color(0xFF00897B), // verde azulado
  Color(0xFFF4511E), // naranja profundo
  Color(0xFF039BE5), // azul claro
  Color(0xFF7CB342), // verde lima
];

/// Devuelve un color consistente basado en el nombre del paciente.
/// El mismo nombre siempre produce el mismo color.
Color colorDePaciente(String nombre) {
  final hash = nombre.codeUnits.fold(0, (prev, code) => prev + code);
  return _paleta[hash % _paleta.length];
}
