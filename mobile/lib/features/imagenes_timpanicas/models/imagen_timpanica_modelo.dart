class AnalisisIAModelo {
  final String id;
  final String idImagen;
  final String prediccion;
  final double confianza;
  final Map<String, double> probabilidades;
  final String? rutaGradCam;
  final String? versionModelo;
  final DateTime? analizadoEn;

  const AnalisisIAModelo({
    required this.id,
    required this.idImagen,
    required this.prediccion,
    required this.confianza,
    required this.probabilidades,
    this.rutaGradCam,
    this.versionModelo,
    this.analizadoEn,
  });

  factory AnalisisIAModelo.fromJson(Map<String, dynamic> json) {
    final probsRaw = json['probabilidades'] as Map<String, dynamic>;
    return AnalisisIAModelo(
      id: json['id'] as String,
      idImagen: json['id_imagen'] as String,
      prediccion: json['prediccion'] as String,
      confianza: (json['confianza'] as num).toDouble(),
      probabilidades: probsRaw.map(
        (clave, valor) => MapEntry(clave, (valor as num).toDouble()),
      ),
      rutaGradCam: json['ruta_grad_cam'] as String?,
      versionModelo: json['version_modelo'] as String?,
      analizadoEn: json['analizado_en'] != null
          ? DateTime.parse(json['analizado_en'] as String)
          : null,
    );
  }

  bool get esMock => versionModelo == 'mock';

  String get etiqueta {
    switch (prediccion) {
      case 'normal':
        return 'Normal';
      case 'otitis_aguda':
        return 'Otitis Media Aguda';
      case 'otitis_cronica':
        return 'Otitis Media Crónica';
      case 'cerumen':
        return 'Tapón de Cerumen';
      default:
        return prediccion;
    }
  }
}

class ImagenTimpanicaModelo {
  final String id;
  final String idRegistro;
  final String idDoctor;
  final String rutaImagen;
  final String? oido;
  final DateTime? capturadoEn;
  final AnalisisIAModelo? analisis;

  const ImagenTimpanicaModelo({
    required this.id,
    required this.idRegistro,
    required this.idDoctor,
    required this.rutaImagen,
    this.oido,
    this.capturadoEn,
    this.analisis,
  });

  factory ImagenTimpanicaModelo.fromJson(Map<String, dynamic> json) {
    return ImagenTimpanicaModelo(
      id: json['id'] as String,
      idRegistro: json['id_registro'] as String,
      idDoctor: json['id_doctor'] as String,
      rutaImagen: json['ruta_imagen'] as String,
      oido: json['oido'] as String?,
      capturadoEn: json['capturado_en'] != null
          ? DateTime.parse(json['capturado_en'] as String)
          : null,
      analisis: json['analisis'] != null
          ? AnalisisIAModelo.fromJson(
              json['analisis'] as Map<String, dynamic>)
          : null,
    );
  }

  String get etiquetaOido {
    switch (oido) {
      case 'derecho':
        return 'Oído derecho';
      case 'izquierdo':
        return 'Oído izquierdo';
      default:
        return 'Oído no especificado';
    }
  }
}
