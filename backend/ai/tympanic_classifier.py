"""
Clasificador de imágenes timpánicas — EfficientNetB0 + Grad-CAM + TTA.

Clases soportadas:
    normal, otitis_cronica, otitis_aguda, cerumen

Test-Time Augmentation (TTA): promedia predicciones sobre varias versiones
augmentadas de la imagen para reducir el efecto del domain gap entre el
dataset de entrenamiento (Kaggle) y fotos reales de otoscopio.

Si el archivo del modelo no existe, opera en modo mock y devuelve
una respuesta simulada con una advertencia en los logs.
"""

import io
import logging
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

CLASES = ["normal", "otitis_cronica", "otitis_aguda", "cerumen"]
RUTA_MODELO = Path(__file__).parent / "models" / "tympanic_v1.keras"
TAMANO_ENTRADA = (224, 224)
CAPA_GRAD_CAM = "top_conv"

# Número de versiones augmentadas a promediar en TTA (incluye el original).
# Más versiones = más robustez pero más lento. 8 es un buen balance.
VERSIONES_TTA = 8


class ClasificadorTimpanico:
    """Singleton que carga el modelo una sola vez al arrancar el servidor."""

    _instancia: Optional["ClasificadorTimpanico"] = None
    _modelo = None
    _modelo_grad_cam = None
    _modo_mock: bool = False

    def __new__(cls) -> "ClasificadorTimpanico":
        if cls._instancia is None:
            cls._instancia = super().__new__(cls)
            cls._instancia._inicializar()
        return cls._instancia

    # ─── Inicialización ───────────────────────────────────────────────────────

    def _inicializar(self) -> None:
        if not RUTA_MODELO.exists():
            logger.warning(
                "Modelo no encontrado en %s — modo mock activo. "
                "Coloca tympanic_v1.keras en esa ruta para usar el clasificador real.",
                RUTA_MODELO,
            )
            self._modo_mock = True
            return

        try:
            import tensorflow as tf

            self._modelo = tf.keras.models.load_model(str(RUTA_MODELO))
            self._modelo_grad_cam = tf.keras.Model(
                inputs=self._modelo.inputs,
                outputs=[
                    self._modelo.get_layer(CAPA_GRAD_CAM).output,
                    self._modelo.output,
                ],
            )
            logger.info("Modelo timpánico cargado desde %s", RUTA_MODELO)
        except Exception as exc:
            logger.error(
                "Error al cargar el modelo (%s) — modo mock activo.", exc
            )
            self._modo_mock = True

    # ─── API pública ──────────────────────────────────────────────────────────

    @property
    def es_mock(self) -> bool:
        return self._modo_mock

    def predecir(self, imagen_bytes: bytes) -> dict:
        """
        Clasifica una imagen timpánica usando TTA (Test-Time Augmentation).

        Promedia predicciones sobre varias versiones augmentadas de la imagen
        para reducir el efecto del domain gap con fotos reales de otoscopio.

        Retorna:
            {
                prediccion: str,
                confianza: float,
                probabilidades: {clase: float},
                modo_mock: bool
            }
        """
        if self._modo_mock:
            return self._respuesta_mock()

        import numpy as np

        versiones = self._generar_versiones_tta(imagen_bytes)
        entrada = np.stack(versiones, axis=0)  # (VERSIONES_TTA, 224, 224, 3)

        probabilidades_por_version = self._modelo.predict(entrada, verbose=0)
        probabilidades_promedio = probabilidades_por_version.mean(axis=0)

        idx_prediccion = int(np.argmax(probabilidades_promedio))

        return {
            "prediccion": CLASES[idx_prediccion],
            "confianza": float(probabilidades_promedio[idx_prediccion]),
            "probabilidades": {
                clase: float(prob)
                for clase, prob in zip(CLASES, probabilidades_promedio)
            },
            "modo_mock": False,
        }

    def generar_grad_cam(
        self,
        imagen_bytes: bytes,
        idx_clase: Optional[int] = None,
    ) -> bytes:
        """
        Genera un overlay Grad-CAM sobre la imagen original.

        Usa la imagen sin augmentar para que el mapa de calor corresponda
        exactamente a la imagen mostrada al usuario.
        """
        if self._modo_mock:
            return imagen_bytes

        import cv2
        import numpy as np
        import tensorflow as tf
        from PIL import Image

        # Grad-CAM siempre sobre la imagen original sin augmentar
        entrada = self._preprocesar(imagen_bytes)

        with tf.GradientTape() as cinta:
            salidas_conv, predicciones = self._modelo_grad_cam(entrada)
            if idx_clase is None:
                idx_clase = int(tf.argmax(predicciones[0]))
            puntuacion_clase = predicciones[:, idx_clase]

        gradientes = cinta.gradient(puntuacion_clase, salidas_conv)
        pesos = tf.reduce_mean(gradientes, axis=(0, 1, 2))
        mapa_cam = tf.reduce_sum(salidas_conv[0] * pesos, axis=-1)
        mapa_cam = tf.nn.relu(mapa_cam).numpy()

        imagen_pil = Image.open(io.BytesIO(imagen_bytes)).convert("RGB")
        ancho_orig, alto_orig = imagen_pil.size

        mapa_cam = cv2.resize(mapa_cam, (ancho_orig, alto_orig))
        mapa_cam = (mapa_cam - mapa_cam.min()) / (
            mapa_cam.max() - mapa_cam.min() + 1e-8
        )
        mapa_calor = cv2.applyColorMap(
            np.uint8(255 * mapa_cam), cv2.COLORMAP_JET
        )
        mapa_calor = cv2.cvtColor(mapa_calor, cv2.COLOR_BGR2RGB)

        imagen_np = np.array(imagen_pil)
        superposicion = cv2.addWeighted(imagen_np, 0.6, mapa_calor, 0.4, 0)

        buffer = io.BytesIO()
        Image.fromarray(superposicion).save(buffer, format="PNG")
        return buffer.getvalue()

    # ─── TTA interno ─────────────────────────────────────────────────────────

    def _generar_versiones_tta(self, imagen_bytes: bytes) -> list:
        """
        Genera VERSIONES_TTA versiones augmentadas de la imagen.

        Augmentaciones aplicadas:
          - Original sin cambios
          - Flip horizontal
          - Rotaciones leves (-15°, +15°)
          - Variaciones de brillo/contraste
          - Combinaciones de flip + rotación
        """
        import numpy as np
        from PIL import Image, ImageEnhance, ImageOps

        imagen_pil = Image.open(io.BytesIO(imagen_bytes)).convert("RGB")
        imagen_pil = imagen_pil.resize(TAMANO_ENTRADA, Image.LANCZOS)

        def _a_arreglo(img: Image.Image) -> np.ndarray:
            from tensorflow.keras.applications.efficientnet import preprocess_input
            return preprocess_input(np.array(img, dtype=np.float32))

        versiones = []

        # 1. Original
        versiones.append(_a_arreglo(imagen_pil))

        # 2. Flip horizontal
        versiones.append(_a_arreglo(ImageOps.mirror(imagen_pil)))

        # 3. Rotación +15°
        versiones.append(_a_arreglo(imagen_pil.rotate(15, resample=Image.BILINEAR)))

        # 4. Rotación -15°
        versiones.append(_a_arreglo(imagen_pil.rotate(-15, resample=Image.BILINEAR)))

        # 5. Brillo aumentado (simula otoscopio con más luz)
        versiones.append(_a_arreglo(ImageEnhance.Brightness(imagen_pil).enhance(1.3)))

        # 6. Brillo reducido (simula otoscopio con menos luz)
        versiones.append(_a_arreglo(ImageEnhance.Brightness(imagen_pil).enhance(0.7)))

        # 7. Contraste aumentado
        versiones.append(_a_arreglo(ImageEnhance.Contrast(imagen_pil).enhance(1.3)))

        # 8. Flip horizontal + rotación +10°
        flipped = ImageOps.mirror(imagen_pil)
        versiones.append(_a_arreglo(flipped.rotate(10, resample=Image.BILINEAR)))

        return versiones[:VERSIONES_TTA]

    # ─── Preprocesamiento ─────────────────────────────────────────────────────

    def _preprocesar(self, imagen_bytes: bytes):
        import numpy as np
        from PIL import Image
        from tensorflow.keras.applications.efficientnet import preprocess_input

        imagen_pil = Image.open(io.BytesIO(imagen_bytes)).convert("RGB")
        imagen_pil = imagen_pil.resize(TAMANO_ENTRADA, Image.LANCZOS)
        arreglo = np.array(imagen_pil, dtype=np.float32)
        arreglo = preprocess_input(arreglo)
        return np.expand_dims(arreglo, axis=0)  # (1, 224, 224, 3)

    @staticmethod
    def _respuesta_mock() -> dict:
        return {
            "prediccion": "normal",
            "confianza": 0.91,
            "probabilidades": {
                "normal": 0.91,
                "otitis_cronica": 0.04,
                "otitis_aguda": 0.03,
                "cerumen": 0.02,
            },
            "modo_mock": True,
        }


# Instancia global — se importa desde los endpoints
clasificador_timpanico = ClasificadorTimpanico()
