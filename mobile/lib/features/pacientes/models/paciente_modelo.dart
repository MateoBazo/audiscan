class PacienteModelo {
  final String id;
  final String medicoId;
  final String nombreCompleto;
  final DateTime? fechaNacimiento;
  final Map<String, dynamic>? informacionContacto;
  final DateTime? creadoEn;

  const PacienteModelo({
    required this.id,
    required this.medicoId,
    required this.nombreCompleto,
    this.fechaNacimiento,
    this.informacionContacto,
    this.creadoEn,
  });

  factory PacienteModelo.fromJson(Map<String, dynamic> json) {
    return PacienteModelo(
      id: json['id'] as String,
      medicoId: json['medico_id'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'] as String)
          : null,
      informacionContacto: json['informacion_contacto'] != null
          ? Map<String, dynamic>.from(json['informacion_contacto'] as Map)
          : null,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }

  // Calcula la edad a partir de la fecha de nacimiento
  int? get edad {
    if (fechaNacimiento == null) return null;
    final hoy = DateTime.now();
    int anios = hoy.year - fechaNacimiento!.year;
    if (hoy.month < fechaNacimiento!.month ||
        (hoy.month == fechaNacimiento!.month &&
            hoy.day < fechaNacimiento!.day)) {
      anios--;
    }
    return anios;
  }

  String get iniciales {
    final partes = nombreCompleto.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombreCompleto.isNotEmpty
        ? nombreCompleto[0].toUpperCase()
        : '?';
  }

  String? get telefono => informacionContacto?['telefono'] as String?;
  String? get emailContacto => informacionContacto?['email'] as String?;
  String? get direccion => informacionContacto?['direccion'] as String?;
}
