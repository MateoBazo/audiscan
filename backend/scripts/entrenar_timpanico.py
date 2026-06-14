#!/usr/bin/env python3

import argparse
import random
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image

CLASES = ["normal", "otitis_cronica", "otitis_aguda", "cerumen"]
TAMANO_ENTRADA = (224, 224)
RUTA_MODELO_SALIDA = (
    Path(__file__).parent.parent / "ai" / "models" / "tympanic_v1.keras"
)
EXTENSIONES = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".webp"}

# Hiperparámetros
EPOCHS_FASE1 = 30
EPOCHS_FASE2 = 50
BATCH_SIZE = 32
LR_FASE1 = 1e-3
LR_FASE2 = 3e-5
CAPAS_FINE_TUNING = 40
LABEL_SMOOTHING = 0.05
FRECUENCIA_METRICAS = 5  # Imprimir métricas por clase cada N epochs


# ─── Análisis del dataset ─────────────────────────────────────────────────────

def analizar_distribucion(directorio_dataset: Path) -> None:
    print("\n─── Distribución del dataset ───")
    print(f"{'Clase':<22} {'train':>6} {'val':>6} {'total':>6}")
    print("─" * 44)

    conteos_train = []
    for clase in CLASES:
        t = _contar_imagenes(directorio_dataset / "train" / clase)
        v = _contar_imagenes(directorio_dataset / "val" / clase)
        conteos_train.append(t)
        print(f"  {clase:<20} {t:>6} {v:>6} {t + v:>6}")

    print("─" * 44)

    if conteos_train and min(conteos_train) > 0:
        ratio = max(conteos_train) / min(conteos_train)
        if ratio > 1.5:
            print(
                f"\n  [AVISO] Desbalance detectado (ratio {ratio:.1f}x). "
                "Se aplicarán class_weight automáticamente."
            )


def calcular_pesos_clase(directorio_train: Path) -> dict[int, float]:
    from sklearn.utils.class_weight import compute_class_weight

    etiquetas = []
    for idx, clase in enumerate(CLASES):
        count = _contar_imagenes(directorio_train / clase)
        etiquetas.extend([idx] * count)

    pesos = compute_class_weight(
        class_weight="balanced",
        classes=np.arange(len(CLASES)),
        y=np.array(etiquetas),
    )
    pesos_dict = {i: float(p) for i, p in enumerate(pesos)}

    print("\n─── Pesos de clase calculados ───")
    for idx, clase in enumerate(CLASES):
        print(f"  {clase:<22}: {pesos_dict[idx]:.4f}")

    return pesos_dict


def _contar_imagenes(carpeta: Path) -> int:
    if not carpeta.exists():
        return 0
    return sum(1 for f in carpeta.iterdir() if f.suffix.lower() in EXTENSIONES)


# ─── Augmentaciones ───────────────────────────────────────────────────────────

def construir_transformaciones():
    import albumentations as A

    return A.Compose([
        A.HorizontalFlip(p=0.5),
        A.Rotate(limit=15, border_mode=0, p=0.5),
        A.Affine(
            translate_percent={"x": (-0.1, 0.1), "y": (-0.1, 0.1)},
            scale=(0.85, 1.15),
            border_mode=0,
            p=0.5,
        ),
        # Variación de exposición y contraste — simula distintos otoscopios
        A.RandomBrightnessContrast(brightness_limit=0.3, contrast_limit=0.3, p=0.8),
        A.RandomGamma(gamma_limit=(80, 120), p=0.3),
        # Variación de color — simula distinta iluminación y temperatura de luz
        A.HueSaturationValue(
            hue_shift_limit=20, sat_shift_limit=30, val_shift_limit=20, p=0.7
        ),
        # Mejora de contraste local — simula distinto procesamiento de cámara
        A.CLAHE(clip_limit=2.0, tile_grid_size=(8, 8), p=0.4),
        # Ruido y desenfoque — simula calidad variable de imagen
        A.GaussNoise(std_range=(0.01, 0.05), p=0.4),
        A.OneOf([
            A.Blur(blur_limit=3, p=1.0),
            A.GaussianBlur(blur_limit=3, p=1.0),
        ], p=0.3),
        # Escala de grises parcial — reduce dependencia de color específico
        A.ToGray(p=0.15),
    ])


# ─── Modelo ───────────────────────────────────────────────────────────────────

def construir_modelo(num_clases: int):
    import tensorflow as tf
    from tensorflow.keras import Model, layers, regularizers
    from tensorflow.keras.applications import EfficientNetB0

    base = EfficientNetB0(
        weights="imagenet",
        include_top=False,
        input_shape=(*TAMANO_ENTRADA, 3),
    )
    base.trainable = False

    entradas = base.input
    x = base.output
    x = layers.GlobalAveragePooling2D(name="gap")(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.4)(x)
    x = layers.Dense(
        128,
        activation="relu",
        kernel_regularizer=regularizers.l2(1e-4),
    )(x)
    x = layers.Dropout(0.3)(x)
    salidas = layers.Dense(num_clases, activation="softmax")(x)

    return Model(inputs=entradas, outputs=salidas), base


# ─── Generadores de datos ─────────────────────────────────────────────────────

def crear_generadores(directorio_dataset: Path):
    import tensorflow as tf
    from tensorflow.keras.applications.efficientnet import preprocess_input

    transformacion_entrenamiento = construir_transformaciones()

    class GeneradorAugmentado(tf.keras.utils.Sequence):
        def __init__(self, directorio, transformacion, shuffle):
            self.transformacion = transformacion
            self.shuffle = shuffle
            self.rutas: list[str] = []
            self.etiquetas: list[int] = []

            for idx, clase in enumerate(CLASES):
                carpeta = Path(directorio) / clase
                if not carpeta.exists():
                    continue
                for ruta in sorted(carpeta.iterdir()):
                    if ruta.suffix.lower() in EXTENSIONES:
                        self.rutas.append(str(ruta))
                        self.etiquetas.append(idx)

            if self.shuffle:
                self._mezclar()

        def _mezclar(self):
            indices = list(range(len(self.rutas)))
            random.shuffle(indices)
            self.rutas = [self.rutas[i] for i in indices]
            self.etiquetas = [self.etiquetas[i] for i in indices]

        def __len__(self):
            return len(self.rutas) // BATCH_SIZE

        def __getitem__(self, idx):
            inicio = idx * BATCH_SIZE
            fin = inicio + BATCH_SIZE
            X, y = [], []

            for ruta, etiqueta in zip(
                self.rutas[inicio:fin], self.etiquetas[inicio:fin]
            ):
                img = (
                    Image.open(ruta)
                    .convert("RGB")
                    .resize(TAMANO_ENTRADA, Image.LANCZOS)
                )
                img_np = np.array(img, dtype=np.uint8)

                if self.transformacion:
                    img_np = self.transformacion(image=img_np)["image"]

                img_float = preprocess_input(img_np.astype(np.float32))
                X.append(img_float)

                label = np.zeros(len(CLASES), dtype=np.float32)
                label[etiqueta] = 1.0
                y.append(label)

            return np.array(X), np.array(y)

        def on_epoch_end(self):
            if self.shuffle:
                self._mezclar()

    flujo_entrenamiento = GeneradorAugmentado(
        directorio=directorio_dataset / "train",
        transformacion=transformacion_entrenamiento,
        shuffle=True,
    )
    flujo_validacion = GeneradorAugmentado(
        directorio=directorio_dataset / "val",
        transformacion=None,
        shuffle=False,
    )
    return flujo_entrenamiento, flujo_validacion


# ─── Callbacks ────────────────────────────────────────────────────────────────

def crear_callback_metricas(flujo_validacion):
    """Callback que imprime F1, precision y recall por clase cada N epochs."""
    import tensorflow as tf
    from sklearn.metrics import classification_report

    class _CallbackMetricas(tf.keras.callbacks.Callback):
        def on_epoch_end(self, epoch, logs=None):
            if (epoch + 1) % FRECUENCIA_METRICAS != 0:
                return

            y_verdadero, y_predicho = [], []
            for i in range(len(flujo_validacion)):
                X_batch, y_batch = flujo_validacion[i]
                preds = self.model.predict(X_batch, verbose=0)
                y_verdadero.extend(np.argmax(y_batch, axis=1))
                y_predicho.extend(np.argmax(preds, axis=1))

            print(f"\n─── Métricas por clase (epoch {epoch + 1}) ───")
            print(
                classification_report(
                    y_verdadero,
                    y_predicho,
                    target_names=CLASES,
                    zero_division=0,
                )
            )

    return _CallbackMetricas()


# ─── Evaluación final ─────────────────────────────────────────────────────────

def evaluar_final(modelo, flujo_validacion) -> None:
    from sklearn.metrics import classification_report, confusion_matrix

    y_verdadero, y_predicho = [], []
    for i in range(len(flujo_validacion)):
        X_batch, y_batch = flujo_validacion[i]
        preds = modelo.predict(X_batch, verbose=0)
        y_verdadero.extend(np.argmax(y_batch, axis=1))
        y_predicho.extend(np.argmax(preds, axis=1))

    print("\n─── Reporte de clasificación final ───\n")
    print(
        classification_report(
            y_verdadero,
            y_predicho,
            target_names=CLASES,
            zero_division=0,
        )
    )

    cm = confusion_matrix(y_verdadero, y_predicho)
    print("─── Matriz de confusión ───")
    ancho = 24
    print(" " * ancho + "  ".join(f"{c[:8]:>8}" for c in CLASES))
    for i, clase in enumerate(CLASES):
        fila = f"{clase:<{ancho}}" + "  ".join(f"{cm[i, j]:>8}" for j in range(len(CLASES)))
        print(fila)

    # Detectar colapso: si una clase domina >60% de las predicciones
    conteo_pred = Counter(y_predicho)
    clase_dominante = max(conteo_pred, key=conteo_pred.get)
    porcentaje = conteo_pred[clase_dominante] / len(y_predicho) * 100
    if porcentaje > 60:
        print(
            f"\n[AVISO] El modelo predice '{CLASES[clase_dominante]}' en el {porcentaje:.0f}% "
            "de los casos — posible colapso. Revisá class_weight y distribución del dataset."
        )


# ─── Entrenamiento principal ──────────────────────────────────────────────────

def entrenar(directorio_dataset: Path) -> None:
    import tensorflow as tf

    gpus = tf.config.list_physical_devices("GPU")
    print(f"\nTensorFlow {tf.__version__} — GPU disponible: {bool(gpus)}")
    print(f"Dataset:          {directorio_dataset.resolve()}")
    print(f"Modelo de salida: {RUTA_MODELO_SALIDA.resolve()}")

    RUTA_MODELO_SALIDA.parent.mkdir(parents=True, exist_ok=True)

    analizar_distribucion(directorio_dataset)
    pesos_clase = calcular_pesos_clase(directorio_dataset / "train")

    flujo_entrenamiento, flujo_validacion = crear_generadores(directorio_dataset)
    modelo, base = construir_modelo(num_clases=len(CLASES))

    print(f"\nImágenes entrenamiento: {len(flujo_entrenamiento) * BATCH_SIZE}")
    print(f"Imágenes validación:    {len(flujo_validacion) * BATCH_SIZE}\n")

    callback_metricas = crear_callback_metricas(flujo_validacion)

    # ── Fase 1: base congelada — solo entrena el head ─────────────────────────
    print("\n─── Fase 1: entrenando head (base congelada) ───\n")
    modelo.compile(
        optimizer=tf.keras.optimizers.Adam(LR_FASE1),
        loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=LABEL_SMOOTHING),
        metrics=["accuracy"],
    )
    modelo.fit(
        flujo_entrenamiento,
        validation_data=flujo_validacion,
        epochs=EPOCHS_FASE1,
        class_weight=pesos_clase,
        callbacks=[
            callback_metricas,
            tf.keras.callbacks.EarlyStopping(
                monitor="val_accuracy",
                patience=8,
                restore_best_weights=True,
                min_delta=0.005,
            ),
            tf.keras.callbacks.ModelCheckpoint(
                str(RUTA_MODELO_SALIDA).replace(".keras", "_fase1.keras"),
                monitor="val_accuracy",
                save_best_only=True,
                verbose=1,
            ),
            tf.keras.callbacks.ReduceLROnPlateau(
                monitor="val_loss", factor=0.5, patience=4, verbose=1, min_lr=1e-6
            ),
        ],
    )

    print("\n─── Evaluación tras Fase 1 ───")
    perdida_f1, precision_f1 = modelo.evaluate(flujo_validacion, verbose=0)
    print(f"Loss: {perdida_f1:.4f} | Accuracy: {precision_f1:.4f}")
    if precision_f1 < 0.40:
        print("\n[AVISO] Accuracy < 40% tras Fase 1 — el head no convergió.")

    # ── Fase 2: fine-tuning de las últimas capas ──────────────────────────────
    print(f"\n─── Fase 2: fine-tuning últimas {CAPAS_FINE_TUNING} capas ───\n")
    base.trainable = True
    for capa in base.layers[:-CAPAS_FINE_TUNING]:
        capa.trainable = False

    modelo.compile(
        optimizer=tf.keras.optimizers.Adam(LR_FASE2),
        loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=LABEL_SMOOTHING),
        metrics=["accuracy"],
    )
    modelo.fit(
        flujo_entrenamiento,
        validation_data=flujo_validacion,
        epochs=EPOCHS_FASE2,
        class_weight=pesos_clase,
        callbacks=[
            callback_metricas,
            tf.keras.callbacks.EarlyStopping(
                monitor="val_accuracy",
                patience=12,
                restore_best_weights=True,
                min_delta=0.003,
            ),
            tf.keras.callbacks.ModelCheckpoint(
                str(RUTA_MODELO_SALIDA),
                monitor="val_accuracy",
                save_best_only=True,
                verbose=1,
            ),
            tf.keras.callbacks.ReduceLROnPlateau(
                monitor="val_loss", factor=0.3, patience=5, verbose=1, min_lr=1e-7
            ),
        ],
    )

    # ── Evaluación final ──────────────────────────────────────────────────────
    print("\n─── Evaluación final en conjunto de validación ───\n")
    perdida, precision = modelo.evaluate(flujo_validacion, verbose=1)
    print(f"\nLoss: {perdida:.4f} | Accuracy: {precision:.4f}")

    evaluar_final(modelo, flujo_validacion)

    if precision >= 0.99:
        print(
            "\n[AVISO] Accuracy >= 99% — posible sobreajuste al estilo visual del dataset."
        )

    print(f"\nModelo guardado en: {RUTA_MODELO_SALIDA.resolve()}")


if __name__ == "__main__":
    analizador = argparse.ArgumentParser(
        description="Entrenar clasificador timpánico con EfficientNetB0 + albumentaciones"
    )
    analizador.add_argument(
        "--directorio_dataset",
        type=Path,
        default=Path("./dataset"),
        help="Directorio del dataset (subcarpetas train/ y val/)",
    )
    args = analizador.parse_args()

    if not args.directorio_dataset.exists():
        print(f"ERROR: El directorio '{args.directorio_dataset}' no existe.")
        raise SystemExit(1)

    entrenar(args.directorio_dataset)
