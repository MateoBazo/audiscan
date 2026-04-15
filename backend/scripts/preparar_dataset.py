#!/usr/bin/env python3
"""
Prepara el dataset de Kaggle 'ucimachinelearning/otoscopic-image-dataset'
para el entrenamiento del clasificador timpánico.

Pasos que realiza:
  1. Lee las imágenes de las 4 clases relevantes (descarta Myringosclerosis)
  2. Mezcla aleatoriamente cada clase
  3. Divide en train (80 %) y val (20 %)
  4. Copia los archivos a la estructura que espera entrenar_timpanico.py

Estructura de entrada esperada (carpeta del zip descomprimido):
    <directorio_origen>/
    ├── Acute Otitis Media (AOM)/
    ├── Cerumen Impaction/
    ├── Chronic Otitis Media (COM)/
    ├── Myringosclerosis/          ← se omite
    └── Normal/

Estructura de salida generada:
    <directorio_destino>/
    ├── train/
    │   ├── normal/
    │   ├── otitis_aguda/
    │   ├── otitis_cronica/
    │   └── cerumen/
    └── val/
        ├── normal/
        ├── otitis_aguda/
        ├── otitis_cronica/
        └── cerumen/

Uso:
    cd backend
    python scripts/preparar_dataset.py --origen ./otoscopic-image-dataset --destino ./dataset
"""

import argparse
import random
import shutil
from pathlib import Path

SEMILLA = 42
PROPORCION_VAL = 0.20

# Mapeo: nombre de carpeta en Kaggle → nombre de clase en AudiScan
MAPEO_CLASES = {
    "Normal": "normal",
    "Acute Otitis Media": "otitis_aguda",
    "Chronic Otitis Media": "otitis_cronica",
    "Cerumen Impaction": "cerumen",
}

EXTENSIONES_VALIDAS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".webp"}


def listar_imagenes(carpeta: Path) -> list[Path]:
    return sorted(
        archivo
        for archivo in carpeta.iterdir()
        if archivo.suffix.lower() in EXTENSIONES_VALIDAS
    )


def copiar_split(
    imagenes: list[Path],
    clase: str,
    directorio_destino: Path,
    split: str,
) -> None:
    carpeta_destino = directorio_destino / split / clase
    carpeta_destino.mkdir(parents=True, exist_ok=True)
    for imagen in imagenes:
        shutil.copy2(imagen, carpeta_destino / imagen.name)


def preparar(directorio_origen: Path, directorio_destino: Path) -> None:
    random.seed(SEMILLA)

    print(f"\nOrigen:  {directorio_origen.resolve()}")
    print(f"Destino: {directorio_destino.resolve()}\n")

    resumen = {}

    for carpeta_kaggle, nombre_clase in MAPEO_CLASES.items():
        carpeta_origen = directorio_origen / carpeta_kaggle

        if not carpeta_origen.exists():
            print(f"  [AVISO] Carpeta no encontrada, se omite: {carpeta_kaggle}")
            continue

        imagenes = listar_imagenes(carpeta_origen)
        random.shuffle(imagenes)

        corte = int(len(imagenes) * (1 - PROPORCION_VAL))
        imagenes_train = imagenes[:corte]
        imagenes_val = imagenes[corte:]

        copiar_split(imagenes_train, nombre_clase, directorio_destino, "train")
        copiar_split(imagenes_val, nombre_clase, directorio_destino, "val")

        resumen[nombre_clase] = {
            "total": len(imagenes),
            "train": len(imagenes_train),
            "val": len(imagenes_val),
        }

        print(
            f"  {nombre_clase:<20} "
            f"total={len(imagenes):>4}  "
            f"train={len(imagenes_train):>4}  "
            f"val={len(imagenes_val):>4}"
        )

    total_imagenes = sum(v["total"] for v in resumen.values())
    total_train = sum(v["train"] for v in resumen.values())
    total_val = sum(v["val"] for v in resumen.values())

    print(f"\n{'─' * 55}")
    print(
        f"  {'TOTAL':<20} "
        f"total={total_imagenes:>4}  "
        f"train={total_train:>4}  "
        f"val={total_val:>4}"
    )
    print(f"\nDataset listo en: {directorio_destino.resolve()}")
    print("\nSiguiente paso:")
    print(
        f"  python scripts/entrenar_timpanico.py "
        f"--directorio_dataset {directorio_destino}\n"
    )


if __name__ == "__main__":
    analizador = argparse.ArgumentParser(
        description="Prepara el dataset de Kaggle para el entrenamiento timpánico"
    )
    analizador.add_argument(
        "--origen",
        type=Path,
        required=True,
        help="Carpeta raíz del dataset descomprimido de Kaggle",
    )
    analizador.add_argument(
        "--destino",
        type=Path,
        default=Path("./dataset"),
        help="Carpeta de salida con estructura train/val (default: ./dataset)",
    )
    args = analizador.parse_args()

    if not args.origen.exists():
        print(f"\nERROR: El directorio de origen '{args.origen}' no existe.")
        raise SystemExit(1)

    preparar(args.origen, args.destino)
