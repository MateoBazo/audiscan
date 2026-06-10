"""
Clasificador de audiometría — Random Forest sobre umbrales auditivos.

Clases de tipo:  normal | conductiva | sensorioneural | mixta
Clases de grado: normal | leve | moderado | severo | profundo

Si los modelos no existen, opera en modo mock con una advertencia en los logs.
"""

import logging
from pathlib import Path
from typing import Optional

import numpy as np

logger = logging.getLogger(__name__)

TIPOS = ["normal", "conductiva", "sensorioneural", "mixta"]
GRADOS = ["normal", "leve", "moderado", "severo", "profundo"]

RUTA_MODELO_TIPO = Path(__file__).parent / "models" / "audiometry_tipo.pkl"
RUTA_MODELO_GRADO = Path(__file__).parent / "models" / "audiometry_grado.pkl"

_RECOMENDACIONES: dict[tuple[str, str], str] = {
    ("normal", "normal"):           "Audición dentro de límites normales. Se recomienda revisión anual.",
    ("conductiva", "leve"):         "Hipoacusia conductiva leve. Evaluar causa (otitis, tapón de cerumen). Posible tratamiento médico.",
    ("conductiva", "moderado"):     "Hipoacusia conductiva moderada. Requiere evaluación médica. Considerar amplificación.",
    ("conductiva", "severo"):       "Hipoacusia conductiva severa. Derivar a evaluación quirúrgica otológica.",
    ("conductiva", "profundo"):     "Hipoacusia conductiva profunda. Evaluación quirúrgica urgente.",
    ("sensorioneural", "leve"):     "Hipoacusia sensorioneural leve. Monitoreo periódico. Evaluar exposición a ruido.",
    ("sensorioneural", "moderado"): "Hipoacusia sensorioneural moderada. Indicación de audífonos. Evaluar etiología.",
    ("sensorioneural", "severo"):   "Hipoacusia sensorioneural severa. Audífonos de alta potencia o candidato a implante coclear.",
    ("sensorioneural", "profundo"): "Hipoacusia sensorioneural profunda. Candidato a implante coclear. Derivación urgente.",
    ("mixta", "leve"):              "Hipoacusia mixta leve. Tratamiento médico del componente conductivo + seguimiento auditivo.",
    ("mixta", "moderado"):          "Hipoacusia mixta moderada. Tratamiento combinado médico-quirúrgico + amplificación.",
    ("mixta", "severo"):            "Hipoacusia mixta severa. Evaluación especializada urgente. Rehabilitación auditiva.",
    ("mixta", "profundo"):          "Hipoacusia mixta profunda. Candidato a implante. Evaluación multidisciplinaria urgente.",
}


class ClasificadorAudiograma:
    """Singleton que carga los modelos una sola vez al arrancar el servidor."""

    _instancia: Optional["ClasificadorAudiograma"] = None
    _modelo_tipo = None
    _modelo_grado = None
    _modo_mock: bool = False

    def __new__(cls) -> "ClasificadorAudiograma":
        if cls._instancia is None:
            cls._instancia = super().__new__(cls)
            cls._instancia._inicializar()
        return cls._instancia

    # ─── Inicialización ───────────────────────────────────────────────────────

    def _inicializar(self) -> None:
        faltan = [
            str(r) for r in (RUTA_MODELO_TIPO, RUTA_MODELO_GRADO) if not r.exists()
        ]
        if faltan:
            logger.warning(
                "Modelos de audiometría no encontrados: %s — modo mock activo. "
                "Ejecuta backend/scripts/entrenar_audiometria.py para generarlos.",
                faltan,
            )
            self._modo_mock = True
            return

        try:
            import joblib
            self._modelo_tipo = joblib.load(RUTA_MODELO_TIPO)
            self._modelo_grado = joblib.load(RUTA_MODELO_GRADO)
            logger.info("Modelos de audiometría cargados correctamente.")
        except Exception as exc:
            logger.error("Error al cargar modelos de audiometría (%s) — modo mock activo.", exc)
            self._modo_mock = True

    # ─── API pública ──────────────────────────────────────────────────────────

    @property
    def es_mock(self) -> bool:
        return self._modo_mock

    def predecir(
        self,
        umbrales_od: list[float],
        umbrales_oi: list[float],
    ) -> dict:
        """
        Clasifica tipo y grado de hipoacusia para ambos oídos.

        Args:
            umbrales_od: [250, 500, 1000, 2000, 4000, 8000 Hz] dB HL — oído derecho
            umbrales_oi: [250, 500, 1000, 2000, 4000, 8000 Hz] dB HL — oído izquierdo

        Retorna dict con prediccion_od/oi, grado_od/oi, confianza_od/oi,
        probabilidades_od/oi, recomendacion, modo_mock.
        """
        if self._modo_mock:
            return self._respuesta_mock()

        od = self._predecir_oido(umbrales_od)
        oi = self._predecir_oido(umbrales_oi)

        return {
            "prediccion_od": od["tipo"],
            "prediccion_oi": oi["tipo"],
            "grado_od": od["grado"],
            "grado_oi": oi["grado"],
            "confianza_od": od["confianza"],
            "confianza_oi": oi["confianza"],
            "probabilidades_od": od["probabilidades"],
            "probabilidades_oi": oi["probabilidades"],
            "recomendacion": self._generar_recomendacion(
                od["tipo"], od["grado"], oi["tipo"], oi["grado"]
            ),
            "modo_mock": False,
        }

    # ─── Internos ─────────────────────────────────────────────────────────────

    def _predecir_oido(self, umbrales: list[float]) -> dict:
        X = np.array(umbrales, dtype=float).reshape(1, -1)

        prob_tipo = self._modelo_tipo.predict_proba(X)[0]
        clases_tipo = self._modelo_tipo.classes_
        idx_tipo = int(np.argmax(prob_tipo))

        prob_grado = self._modelo_grado.predict_proba(X)[0]
        clases_grado = self._modelo_grado.classes_
        idx_grado = int(np.argmax(prob_grado))

        confianza = round(
            (float(prob_tipo[idx_tipo]) + float(prob_grado[idx_grado])) / 2, 4
        )

        return {
            "tipo": clases_tipo[idx_tipo],
            "grado": clases_grado[idx_grado],
            "confianza": confianza,
            "probabilidades": {
                "tipo": {
                    c: round(float(p), 4)
                    for c, p in zip(clases_tipo, prob_tipo)
                },
                "grado": {
                    c: round(float(p), 4)
                    for c, p in zip(clases_grado, prob_grado)
                },
            },
        }

    @staticmethod
    def _generar_recomendacion(
        tipo_od: str, grado_od: str, tipo_oi: str, grado_oi: str
    ) -> str:
        if tipo_od == "normal" and tipo_oi == "normal":
            return _RECOMENDACIONES[("normal", "normal")]

        partes = []
        for lado, tipo, grado in (("OD", tipo_od, grado_od), ("OI", tipo_oi, grado_oi)):
            if tipo == "normal":
                partes.append(f"{lado}: audición normal.")
            else:
                texto = _RECOMENDACIONES.get(
                    (tipo, grado),
                    f"Hipoacusia {tipo} {grado}. Evaluación médica especializada recomendada.",
                )
                partes.append(f"{lado}: {texto}")

        return " | ".join(partes)

    @staticmethod
    def _respuesta_mock() -> dict:
        return {
            "prediccion_od": "sensorioneural",
            "prediccion_oi": "normal",
            "grado_od": "leve",
            "grado_oi": "normal",
            "confianza_od": 0.87,
            "confianza_oi": 0.93,
            "probabilidades_od": {
                "tipo": {
                    "normal": 0.05,
                    "conductiva": 0.06,
                    "sensorioneural": 0.87,
                    "mixta": 0.02,
                },
                "grado": {
                    "normal": 0.04,
                    "leve": 0.83,
                    "moderado": 0.09,
                    "severo": 0.03,
                    "profundo": 0.01,
                },
            },
            "probabilidades_oi": {
                "tipo": {
                    "normal": 0.93,
                    "conductiva": 0.04,
                    "sensorioneural": 0.02,
                    "mixta": 0.01,
                },
                "grado": {
                    "normal": 0.93,
                    "leve": 0.04,
                    "moderado": 0.02,
                    "severo": 0.01,
                    "profundo": 0.00,
                },
            },
            "recomendacion": (
                "OD: Hipoacusia sensorioneural leve. Monitoreo periódico. "
                "Evaluar exposición a ruido. | OI: audición normal."
            ),
            "modo_mock": True,
        }


# Instancia global — se importa desde los endpoints
clasificador_audiograma = ClasificadorAudiograma()
