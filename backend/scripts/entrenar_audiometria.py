#!/usr/bin/env python3
"""
Genera datos sintéticos y entrena los clasificadores de audiometría.

Produce dos modelos Random Forest guardados con joblib:
  - audiometry_tipo.pkl  → tipo de hipoacusia (normal, conductiva, sensorioneural, mixta)
  - audiometry_grado.pkl → grado de hipoacusia (normal, leve, moderado, severo, profundo)

Cada modelo recibe 6 umbrales auditivos en dB HL para una sola oreja:
  [250 Hz, 500 Hz, 1000 Hz, 2000 Hz, 4000 Hz, 8000 Hz]

Uso:
    cd backend
    source venv/bin/activate
    python scripts/entrenar_audiometria.py
"""

import numpy as np
import joblib
from pathlib import Path
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

RUTA_MODELOS = Path(__file__).parent.parent / "ai" / "models"
MUESTRAS_POR_CLASE = 2500
SEED = 42

TIPOS = ["normal", "conductiva", "sensorioneural", "mixta"]
GRADOS = ["normal", "leve", "moderado", "severo", "profundo"]

rng = np.random.default_rng(SEED)


def _clip(arr: np.ndarray) -> np.ndarray:
    return np.clip(arr, -10, 120).astype(float)


# ─── Generadores sintéticos ───────────────────────────────────────────────────

def generar_tipo(tipo: str, n: int) -> np.ndarray:
    """
    Genera n audiogramas sintéticos con el patrón clínico del tipo indicado.

    Patrones estándar:
      normal        → todos los umbrales ≤ 25 dB
      conductiva    → graves afectados, agudos relativamente normales (patrón plano/ascendente)
      sensorioneural → agudos afectados progresivamente (patrón descendente, muesca en 4kHz)
      mixta         → elevado en todo el rango con pendiente hacia agudos
    """
    muestras = []
    for _ in range(n):
        if tipo == "normal":
            u = rng.uniform(0, 25, 6)

        elif tipo == "conductiva":
            base = rng.uniform(28, 72)
            delta = np.array([7, 5, 2, 0, -3, -6], dtype=float)
            u = base + delta + rng.normal(0, 6, 6)

        elif tipo == "sensorioneural":
            base_grave = rng.uniform(5, 35)
            caida = rng.uniform(15, 55)
            proporcion = np.array([0.0, 0.05, 0.20, 0.45, 0.78, 1.0])
            u = base_grave + caida * proporcion + rng.normal(0, 6, 6)

        elif tipo == "mixta":
            base = rng.uniform(35, 68)
            caida = rng.uniform(10, 30)
            proporcion = np.array([0.10, 0.10, 0.20, 0.40, 0.72, 1.0])
            u = base + caida * proporcion + rng.normal(0, 7, 6)

        muestras.append(_clip(u))
    return np.array(muestras)


def generar_grado(grado: str, n: int) -> np.ndarray:
    """
    Genera n audiogramas cuyo PTA (media de 500–4000 Hz) cae en el rango del grado.

    Grados según clasificación BIAP/OMS:
      normal   ≤ 25 dB
      leve     26–40 dB
      moderado 41–60 dB
      severo   61–80 dB
      profundo > 80 dB
    """
    rangos = {
        "normal":   (0,  25),
        "leve":     (26, 40),
        "moderado": (41, 60),
        "severo":   (61, 80),
        "profundo": (81, 110),
    }
    pta_min, pta_max = rangos[grado]
    muestras = []
    for _ in range(n):
        pta = rng.uniform(pta_min, pta_max)
        variacion = rng.normal(0, 8, 6)
        u = pta + variacion
        muestras.append(_clip(u))
    return np.array(muestras)


# ─── Entrenamiento ────────────────────────────────────────────────────────────

def entrenar_modelo(
    X: np.ndarray,
    y: np.ndarray,
    nombre_clases: list[str],
    titulo: str,
) -> RandomForestClassifier:
    X_entrenamiento, X_prueba, y_entrenamiento, y_prueba = train_test_split(
        X, y, test_size=0.20, random_state=SEED, stratify=y
    )
    modelo = RandomForestClassifier(
        n_estimators=300,
        max_depth=14,
        min_samples_leaf=3,
        class_weight="balanced",
        random_state=SEED,
        n_jobs=-1,
    )
    modelo.fit(X_entrenamiento, y_entrenamiento)

    print(f"\n─── {titulo} ───")
    print(classification_report(
        y_prueba,
        modelo.predict(X_prueba),
        target_names=sorted(set(nombre_clases)),
    ))
    return modelo


def main() -> None:
    RUTA_MODELOS.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("  Entrenamiento de clasificadores de audiometría")
    print("=" * 60)

    # ── Tipo ──────────────────────────────────────────────────────────────────
    print(f"\nGenerando {MUESTRAS_POR_CLASE * len(TIPOS)} muestras para TIPO...")
    X_tipo = np.vstack([generar_tipo(t, MUESTRAS_POR_CLASE) for t in TIPOS])
    y_tipo = np.repeat(TIPOS, MUESTRAS_POR_CLASE)

    modelo_tipo = entrenar_modelo(X_tipo, y_tipo, TIPOS, "Clasificador TIPO")
    ruta_tipo = RUTA_MODELOS / "audiometry_tipo.pkl"
    joblib.dump(modelo_tipo, ruta_tipo)
    print(f"Guardado en: {ruta_tipo.resolve()}")

    # ── Grado ─────────────────────────────────────────────────────────────────
    print(f"\nGenerando {MUESTRAS_POR_CLASE * len(GRADOS)} muestras para GRADO...")
    X_grado = np.vstack([generar_grado(g, MUESTRAS_POR_CLASE) for g in GRADOS])
    y_grado = np.repeat(GRADOS, MUESTRAS_POR_CLASE)

    modelo_grado = entrenar_modelo(X_grado, y_grado, GRADOS, "Clasificador GRADO")
    ruta_grado = RUTA_MODELOS / "audiometry_grado.pkl"
    joblib.dump(modelo_grado, ruta_grado)
    print(f"Guardado en: {ruta_grado.resolve()}")

    print("\n✓ Entrenamiento completo. Modelos listos para usar.\n")


if __name__ == "__main__":
    main()
