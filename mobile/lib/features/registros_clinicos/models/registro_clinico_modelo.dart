class RegistroClinicoModelo {
  final String id;
  final String idPaciente;
  final String? idCita;
  final String idDoctor;
  final DateTime fecha;
  final String? anamnesis;
  final String? exploracionFisica;
  final String? diagnostico;
  final String? tratamiento;
  final String? observaciones;
  final DateTime? creadoEn;

  const RegistroClinicoModelo({
    required this.id,
    required this.idPaciente,
    this.idCita,
    required this.idDoctor,
    required this.fecha,
    this.anamnesis,
    this.exploracionFisica,
    this.diagnostico,
    this.tratamiento,
    this.observaciones,
    this.creadoEn,
  });

  factory RegistroClinicoModelo.fromJson(Map<String, dynamic> json) {
    return RegistroClinicoModelo(
      id: json['id'] as String,
      idPaciente: json['id_paciente'] as String,
      idCita: json['id_cita'] as String?,
      idDoctor: json['id_doctor'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      anamnesis: json['anamnesis'] as String?,
      exploracionFisica: json['exploracion_fisica'] as String?,
      diagnostico: json['diagnostico'] as String?,
      tratamiento: json['tratamiento'] as String?,
      observaciones: json['observaciones'] as String?,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }
}
