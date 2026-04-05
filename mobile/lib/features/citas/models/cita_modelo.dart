class CitaModelo {
  final String id;
  final String idDoctor;
  final String idPaciente;
  final DateTime fechaHora;
  final int duracionMinutos;
  final String? motivo;
  final String estado;
  final String? notas;
  final DateTime? creadoEn;

  // Campo auxiliar — se llena desde el provider, no viene del JSON
  final String? nombrePaciente;

  const CitaModelo({
    required this.id,
    required this.idDoctor,
    required this.idPaciente,
    required this.fechaHora,
    required this.duracionMinutos,
    this.motivo,
    required this.estado,
    this.notas,
    this.creadoEn,
    this.nombrePaciente,
  });

  factory CitaModelo.fromJson(Map<String, dynamic> json) {
    return CitaModelo(
      id: json['id'] as String,
      idDoctor: json['id_doctor'] as String,
      idPaciente: json['id_paciente'] as String,
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      duracionMinutos: json['duracion_minutos'] as int,
      motivo: json['motivo'] as String?,
      estado: json['estado'] as String,
      notas: json['notas'] as String?,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }

  CitaModelo copyWith({
    String? nombrePaciente,
    String? estado,
  }) {
    return CitaModelo(
      id: id,
      idDoctor: idDoctor,
      idPaciente: idPaciente,
      fechaHora: fechaHora,
      duracionMinutos: duracionMinutos,
      motivo: motivo,
      estado: estado ?? this.estado,
      notas: notas,
      creadoEn: creadoEn,
      nombrePaciente: nombrePaciente ?? this.nombrePaciente,
    );
  }
}
