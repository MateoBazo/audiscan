class AnalisisAudiometriaModelo {
  final String id;
  final String idSesion;
  final String prediccionOd;
  final String prediccionOi;
  final String gradoOd;
  final String gradoOi;
  final double confianzaOd;
  final double confianzaOi;
  final Map<String, dynamic> probabilidadesOd;
  final Map<String, dynamic> probabilidadesOi;
  final String? recomendacion;
  final String? versionModelo;
  final DateTime? analizadoEn;

  const AnalisisAudiometriaModelo({
    required this.id,
    required this.idSesion,
    required this.prediccionOd,
    required this.prediccionOi,
    required this.gradoOd,
    required this.gradoOi,
    required this.confianzaOd,
    required this.confianzaOi,
    required this.probabilidadesOd,
    required this.probabilidadesOi,
    this.recomendacion,
    this.versionModelo,
    this.analizadoEn,
  });

  factory AnalisisAudiometriaModelo.fromJson(Map<String, dynamic> json) {
    return AnalisisAudiometriaModelo(
      id: json['id'] as String,
      idSesion: json['id_sesion'] as String,
      prediccionOd: json['prediccion_od'] as String,
      prediccionOi: json['prediccion_oi'] as String,
      gradoOd: json['grado_od'] as String,
      gradoOi: json['grado_oi'] as String,
      confianzaOd: (json['confianza_od'] as num).toDouble(),
      confianzaOi: (json['confianza_oi'] as num).toDouble(),
      probabilidadesOd: json['probabilidades_od'] as Map<String, dynamic>,
      probabilidadesOi: json['probabilidades_oi'] as Map<String, dynamic>,
      recomendacion: json['recomendacion'] as String?,
      versionModelo: json['version_modelo'] as String?,
      analizadoEn: json['analizado_en'] != null
          ? DateTime.parse(json['analizado_en'] as String)
          : null,
    );
  }

  bool get esMock => versionModelo == 'mock';

  String etiquetaTipo(String tipo) {
    switch (tipo) {
      case 'normal':
        return 'Normal';
      case 'conductiva':
        return 'Conductiva';
      case 'sensorioneural':
        return 'Sensorioneural';
      case 'mixta':
        return 'Mixta';
      default:
        return tipo;
    }
  }

  String etiquetaGrado(String grado) {
    switch (grado) {
      case 'normal':
        return 'Normal';
      case 'leve':
        return 'Leve';
      case 'moderado':
        return 'Moderada';
      case 'severo':
        return 'Severa';
      case 'profundo':
        return 'Profunda';
      default:
        return grado;
    }
  }
}

class SesionAudiometriaModelo {
  final String id;
  final String idRegistro;
  final String idPaciente;
  final String idDoctor;
  final double odHz250;
  final double odHz500;
  final double odHz1000;
  final double odHz2000;
  final double odHz4000;
  final double odHz8000;
  final double oiHz250;
  final double oiHz500;
  final double oiHz1000;
  final double oiHz2000;
  final double oiHz4000;
  final double oiHz8000;
  final String? observaciones;
  final DateTime? realizadoEn;
  final AnalisisAudiometriaModelo? analisis;

  const SesionAudiometriaModelo({
    required this.id,
    required this.idRegistro,
    required this.idPaciente,
    required this.idDoctor,
    required this.odHz250,
    required this.odHz500,
    required this.odHz1000,
    required this.odHz2000,
    required this.odHz4000,
    required this.odHz8000,
    required this.oiHz250,
    required this.oiHz500,
    required this.oiHz1000,
    required this.oiHz2000,
    required this.oiHz4000,
    required this.oiHz8000,
    this.observaciones,
    this.realizadoEn,
    this.analisis,
  });

  factory SesionAudiometriaModelo.fromJson(Map<String, dynamic> json) {
    return SesionAudiometriaModelo(
      id: json['id'] as String,
      idRegistro: json['id_registro'] as String,
      idPaciente: json['id_paciente'] as String,
      idDoctor: json['id_doctor'] as String,
      odHz250: (json['od_250hz'] as num).toDouble(),
      odHz500: (json['od_500hz'] as num).toDouble(),
      odHz1000: (json['od_1000hz'] as num).toDouble(),
      odHz2000: (json['od_2000hz'] as num).toDouble(),
      odHz4000: (json['od_4000hz'] as num).toDouble(),
      odHz8000: (json['od_8000hz'] as num).toDouble(),
      oiHz250: (json['oi_250hz'] as num).toDouble(),
      oiHz500: (json['oi_500hz'] as num).toDouble(),
      oiHz1000: (json['oi_1000hz'] as num).toDouble(),
      oiHz2000: (json['oi_2000hz'] as num).toDouble(),
      oiHz4000: (json['oi_4000hz'] as num).toDouble(),
      oiHz8000: (json['oi_8000hz'] as num).toDouble(),
      observaciones: json['observaciones'] as String?,
      realizadoEn: json['realizado_en'] != null
          ? DateTime.parse(json['realizado_en'] as String)
          : null,
      analisis: json['analisis'] != null
          ? AnalisisAudiometriaModelo.fromJson(
              json['analisis'] as Map<String, dynamic>)
          : null,
    );
  }

  List<double> get umbralOd =>
      [odHz250, odHz500, odHz1000, odHz2000, odHz4000, odHz8000];

  List<double> get umbralOi =>
      [oiHz250, oiHz500, oiHz1000, oiHz2000, oiHz4000, oiHz8000];
}
