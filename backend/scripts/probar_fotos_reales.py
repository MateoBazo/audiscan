#!/usr/bin/env python3
"""
Prueba el modelo entrenado con fotos reales de otoscopio.

Uso:
    python scripts/probar_fotos_reales.py --directorio ./mis_fotos

Estructura esperada del directorio (opcional, para calcular accuracy):
    mis_fotos/
        normal/         foto1.jpg, foto2.jpg ...
        otitis_aguda/   foto1.jpg ...
        otitis_cronica/ foto1.jpg ...
        cerumen/        foto1.jpg ...

Si las fotos están todas en la raíz sin subcarpetas, también funciona —
simplemente no calcula accuracy.
"""

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# Agrega el directorio raíz del backend al path para importar el clasificador
sys.path.insert(0, str(Path(__file__).parent.parent))

CLASES = ["normal", "otitis_cronica", "otitis_aguda", "cerumen"]
TAMANO_ENTRADA = (224, 224)
RUTA_MODELO = Path(__file__).parent.parent / "ai" / "models" / "tympanic_v1.keras"
EXTENSIONES = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".webp"}

COLORES = {
    "normal": "\033[92m",       # verde
    "otitis_aguda": "\033[91m", # rojo
    "otitis_cronica": "\033[93m", # amarillo
    "cerumen": "\033[94m",      # azul
    "RESET": "\033[0m",
    "BOLD": "\033[1m",
    "ROJO": "\033[91m",
    "VERDE": "\033[92m",
}


def cargar_clasificador():
    from ai.tympanic_classifier import ClasificadorTimpanico
    if not RUTA_MODELO.exists():
        print(f"ERROR: No se encontró el modelo en {RUTA_MODELO}")
        sys.exit(1)
    print(f"Cargando modelo con TTA desde {RUTA_MODELO}...")
    clasificador = ClasificadorTimpanico()
    print("Modelo cargado.\n")
    return clasificador


def predecir(clasificador, ruta_imagen: Path) -> dict:
    imagen_bytes = ruta_imagen.read_bytes()
    return clasificador.predecir(imagen_bytes)


def imprimir_resultado(nombre: str, resultado: dict, clase_real: str | None) -> bool:
    pred = resultado["prediccion"]
    conf = resultado["confianza"]
    correcto = clase_real is None or pred == clase_real

    color = COLORES.get(pred, "")
    marca = "✓" if correcto else "✗"
    color_marca = COLORES["VERDE"] if correcto else COLORES["ROJO"]

    print(f"  {nombre}")
    if clase_real:
        print(f"    Real:      {clase_real}")
    print(f"    {color_marca}{marca}{COLORES['RESET']} Predicción: {color}{COLORES['BOLD']}{pred}{COLORES['RESET']} ({conf * 100:.1f}%)")

    # Barra de probabilidades
    for clase, prob in sorted(resultado["probabilidades"].items(), key=lambda x: -x[1]):
        barra = "█" * int(prob * 20)
        c = COLORES.get(clase, "")
        print(f"      {c}{clase:<18}{COLORES['RESET']} {barra:<20} {prob * 100:5.1f}%")
    print()

    return correcto


def probar_directorio(modelo, directorio: Path) -> None:
    # Detectar si tiene subcarpetas por clase o fotos sueltas
    subcarpetas = [d for d in directorio.iterdir() if d.is_dir() and d.name in CLASES]
    tiene_etiquetas = len(subcarpetas) > 0

    resultados = []  # (nombre, correcto, confianza)

    if tiene_etiquetas:
        print(f"{COLORES['BOLD']}─── Fotos organizadas por clase ───{COLORES['RESET']}\n")
        for clase_real in CLASES:
            carpeta = directorio / clase_real
            if not carpeta.exists():
                continue
            imagenes = sorted(
                f for f in carpeta.iterdir() if f.suffix.lower() in EXTENSIONES
            )
            if not imagenes:
                continue
            print(f"  [{clase_real.upper()}]")
            for img_path in imagenes:
                resultado = predecir(modelo, img_path)
                correcto = imprimir_resultado(img_path.name, resultado, clase_real)
                resultados.append((img_path.name, correcto, resultado["confianza"]))
    else:
        print(f"{COLORES['BOLD']}─── Fotos sin etiqueta (sin subcarpetas) ───{COLORES['RESET']}\n")
        imagenes = sorted(
            f for f in directorio.iterdir() if f.suffix.lower() in EXTENSIONES
        )
        for img_path in imagenes:
            resultado = predecir(modelo, img_path)
            imprimir_resultado(img_path.name, resultado, None)
            resultados.append((img_path.name, True, resultado["confianza"]))

    # Resumen
    if tiene_etiquetas and resultados:
        correctos = sum(1 for _, c, _ in resultados if c)
        total = len(resultados)
        confianza_prom = sum(conf for _, _, conf in resultados) / total
        color_acc = COLORES["VERDE"] if correctos / total >= 0.75 else COLORES["ROJO"]

        print(f"{COLORES['BOLD']}─── Resumen ───{COLORES['RESET']}")
        print(f"  Accuracy en fotos reales: {color_acc}{correctos}/{total} ({correctos/total*100:.0f}%){COLORES['RESET']}")
        print(f"  Confianza promedio:       {confianza_prom*100:.1f}%")

        if correctos / total < 0.75:
            print(
                f"\n  {COLORES['ROJO']}[DOMAIN GAP DETECTADO]{COLORES['RESET']} "
                "El modelo no generaliza bien a fotos reales.\n"
                "  Opciones: conseguir más fotos reales y hacer fine-tuning,\n"
                "  o buscar un dataset más cercano al dominio real."
            )
        else:
            print(
                f"\n  {COLORES['VERDE']}[BUENA GENERALIZACIÓN]{COLORES['RESET']} "
                "El modelo funciona bien en fotos reales."
            )


if __name__ == "__main__":
    analizador = argparse.ArgumentParser(
        description="Prueba el modelo timpánico con fotos reales de otoscopio"
    )
    analizador.add_argument(
        "--directorio",
        type=Path,
        required=True,
        help=(
            "Carpeta con las fotos. Puede tener subcarpetas por clase "
            "(normal/, otitis_aguda/, otitis_cronica/, cerumen/) "
            "o fotos sueltas sin etiqueta."
        ),
    )
    args = analizador.parse_args()

    if not args.directorio.exists():
        print(f"ERROR: El directorio '{args.directorio}' no existe.")
        sys.exit(1)

    clasificador = cargar_clasificador()
    probar_directorio(clasificador, args.directorio)
