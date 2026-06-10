from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


# ─── Request ──────────────────────────────────────────────────────────────────

class SesionAudiometriaCreate(BaseModel):
    id_registro: str
    od_250hz:  float = Field(..., ge=-10, le=120)
    od_500hz:  float = Field(..., ge=-10, le=120)
    od_1000hz: float = Field(..., ge=-10, le=120)
    od_2000hz: float = Field(..., ge=-10, le=120)
    od_4000hz: float = Field(..., ge=-10, le=120)
    od_8000hz: float = Field(..., ge=-10, le=120)
    oi_250hz:  float = Field(..., ge=-10, le=120)
    oi_500hz:  float = Field(..., ge=-10, le=120)
    oi_1000hz: float = Field(..., ge=-10, le=120)
    oi_2000hz: float = Field(..., ge=-10, le=120)
    oi_4000hz: float = Field(..., ge=-10, le=120)
    oi_8000hz: float = Field(..., ge=-10, le=120)
    observaciones: Optional[str] = None


# ─── Response: análisis IA ────────────────────────────────────────────────────

class AnalisisAudiometriaResponse(BaseModel):
    id: str
    id_sesion: str
    prediccion_od: str
    prediccion_oi: str
    grado_od: str
    grado_oi: str
    confianza_od: float
    confianza_oi: float
    probabilidades_od: dict
    probabilidades_oi: dict
    recomendacion: Optional[str] = None
    version_modelo: Optional[str] = None
    analizado_en: Optional[datetime] = None


# ─── Response: sesión completa ────────────────────────────────────────────────

class SesionAudiometriaResponse(BaseModel):
    id: str
    id_registro: Optional[str] = None
    id_paciente: str
    id_doctor: str
    od_250hz:  float
    od_500hz:  float
    od_1000hz: float
    od_2000hz: float
    od_4000hz: float
    od_8000hz: float
    oi_250hz:  float
    oi_500hz:  float
    oi_1000hz: float
    oi_2000hz: float
    oi_4000hz: float
    oi_8000hz: float
    observaciones: Optional[str] = None
    realizado_en: Optional[datetime] = None
    analisis: Optional[AnalisisAudiometriaResponse] = None
