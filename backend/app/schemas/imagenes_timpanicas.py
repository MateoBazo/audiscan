from datetime import datetime
from typing import Optional

from pydantic import BaseModel


# ─── Response: análisis IA ────────────────────────────────────────────────────

class AnalisisIAResponse(BaseModel):
    id: str
    id_imagen: str
    prediccion: str
    confianza: float
    probabilidades: dict           # {"normal": 0.91, "otitis_aguda": 0.03, ...}
    ruta_grad_cam: Optional[str] = None
    version_modelo: Optional[str] = None
    analizado_en: Optional[datetime] = None


# ─── Response: imagen timpánica ───────────────────────────────────────────────

class ImagenTimpanicaResponse(BaseModel):
    id: str
    id_registro: Optional[str] = None
    id_doctor: str
    ruta_imagen: str
    oido: Optional[str] = None     # "derecho" | "izquierdo"
    capturado_en: Optional[datetime] = None
    analisis: Optional[AnalisisIAResponse] = None
