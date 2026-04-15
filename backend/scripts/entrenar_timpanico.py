#!/usr/bin/env python3
"""
Script de entrenamiento del clasificador timpánico.
Arquitectura: EfficientNetB3 + Transfer Learning + Fine-tuning

Estructura esperada del dataset:
    dataset/
    ├── train/
    │   ├── normal/
    │   ├── otitis_cronica/
    │   ├── otitis_aguda/
    │   └── cerumen/
    └── val/
        ├── normal/
        ├── otitis_cronica/
        ├── otitis_aguda/
        └── cerumen/

Uso:
    cd backend
    python scripts/entrenar_timpanico.py --directorio_dataset ./dataset
"""

import argparse
from pathlib import Path

CLASES = ["normal", "otitis_cronica", "otitis_aguda", "cerumen"]
TAMANO_ENTRADA = (224, 224)
RUTA_MODELO_SALIDA = (
    Path(__file__).parent.parent / "ai" / "models" / "tympanic_v1.keras"
)

# ─── Hiperparámetros ──────────────────────────────────────────────────────────
EPOCHS_FASE1 = 10       # Base congelada — entrena solo el head
EPOCHS_FASE2 = 20       # Fine-tuning de las últimas capas
BATCH_SIZE = 32
LR_FASE1 = 1e-3
LR_FASE2 = 1e-5
CAPAS_FINE_TUNING = 30  # Últimas N capas de EfficientNetB3 a descongelar


def construir_modelo(num_clases: int):
    import tensorflow as tf
    from tensorflow.keras import Model, layers
    from tensorflow.keras.applications import EfficientNetB3

    base = EfficientNetB3(
        weights="imagenet",
        include_top=False,
        input_shape=(*TAMANO_ENTRADA, 3),
    )
    base.trainable = False  # Fase 1: base completamente congelada

    entradas = base.input
    x = base.output
    x = layers.GlobalAveragePooling2D(name="gap")(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.3)(x)
    x = layers.Dense(256, activation="relu")(x)
    x = layers.Dropout(0.2)(x)
    salidas = layers.Dense(num_clases, activation="softmax")(x)

    return Model(inputs=entradas, outputs=salidas), base


def crear_generadores(directorio_dataset: Path):
    from tensorflow.keras.applications.efficientnet import preprocess_input
    from tensorflow.keras.preprocessing.image import ImageDataGenerator

    gen_entrenamiento = ImageDataGenerator(
        preprocessing_function=preprocess_input,
        rotation_range=20,
        width_shift_range=0.1,
        height_shift_range=0.1,
        horizontal_flip=True,
        zoom_range=0.15,
        brightness_range=[0.8, 1.2],
    )
    gen_validacion = ImageDataGenerator(
        preprocessing_function=preprocess_input
    )

    flujo_entrenamiento = gen_entrenamiento.flow_from_directory(
        directorio_dataset / "train",
        target_size=TAMANO_ENTRADA,
        batch_size=BATCH_SIZE,
        class_mode="categorical",
        classes=CLASES,
        shuffle=True,
    )
    flujo_validacion = gen_validacion.flow_from_directory(
        directorio_dataset / "val",
        target_size=TAMANO_ENTRADA,
        batch_size=BATCH_SIZE,
        class_mode="categorical",
        classes=CLASES,
        shuffle=False,
    )
    return flujo_entrenamiento, flujo_validacion


def entrenar(directorio_dataset: Path) -> None:
    import tensorflow as tf

    gpus = tf.config.list_physical_devices("GPU")
    print(f"\nTensorFlow {tf.__version__} — GPU disponible: {bool(gpus)}")
    print(f"Dataset:          {directorio_dataset.resolve()}")
    print(f"Modelo de salida: {RUTA_MODELO_SALIDA.resolve()}\n")

    RUTA_MODELO_SALIDA.parent.mkdir(parents=True, exist_ok=True)

    flujo_entrenamiento, flujo_validacion = crear_generadores(directorio_dataset)
    modelo, base = construir_modelo(num_clases=len(CLASES))
    modelo.summary()

    # ── Fase 1: base congelada — solo entrena el head ─────────────────────────
    print("\n─── Fase 1: entrenando head (base congelada) ───\n")
    modelo.compile(
        optimizer=tf.keras.optimizers.Adam(LR_FASE1),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )
    modelo.fit(
        flujo_entrenamiento,
        validation_data=flujo_validacion,
        epochs=EPOCHS_FASE1,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                monitor="val_loss", patience=3, restore_best_weights=True
            ),
            tf.keras.callbacks.ReduceLROnPlateau(
                monitor="val_loss", factor=0.5, patience=2, verbose=1
            ),
        ],
    )

    # ── Fase 2: fine-tuning de las últimas capas ──────────────────────────────
    print(f"\n─── Fase 2: fine-tuning últimas {CAPAS_FINE_TUNING} capas ───\n")
    base.trainable = True
    for capa in base.layers[:-CAPAS_FINE_TUNING]:
        capa.trainable = False

    modelo.compile(
        optimizer=tf.keras.optimizers.Adam(LR_FASE2),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )
    modelo.fit(
        flujo_entrenamiento,
        validation_data=flujo_validacion,
        epochs=EPOCHS_FASE2,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                monitor="val_loss", patience=5, restore_best_weights=True
            ),
            tf.keras.callbacks.ModelCheckpoint(
                str(RUTA_MODELO_SALIDA),
                monitor="val_accuracy",
                save_best_only=True,
                verbose=1,
            ),
            tf.keras.callbacks.ReduceLROnPlateau(
                monitor="val_loss", factor=0.3, patience=3, verbose=1
            ),
        ],
    )

    # ── Evaluación final ──────────────────────────────────────────────────────
    print("\n─── Evaluación final en conjunto de validación ───\n")
    perdida, precision = modelo.evaluate(flujo_validacion, verbose=1)
    print(f"\nLoss: {perdida:.4f} | Accuracy: {precision:.4f}")
    print(f"\nModelo guardado en: {RUTA_MODELO_SALIDA.resolve()}")


if __name__ == "__main__":
    analizador = argparse.ArgumentParser(
        description="Entrenar clasificador timpánico con EfficientNetB3"
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
