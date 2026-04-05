from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel


# ─── Request schemas ──────────────────────────────────────────────────────────

class CrearRegistroClinicoRequest(BaseModel):
    id_paciente: str
    id_cita: Optional[str] = None
    fecha: Optional[date] = None
    anamnesis: Optional[str] = None
    exploracion_fisica: Optional[str] = None
    diagnostico: Optional[str] = None
    tratamiento: Optional[str] = None
    observaciones: Optional[str] = None


class ActualizarRegistroClinicoRequest(BaseModel):
    fecha: Optional[date] = None
    anamnesis: Optional[str] = None
    exploracion_fisica: Optional[str] = None
    diagnostico: Optional[str] = None
    tratamiento: Optional[str] = None
    observaciones: Optional[str] = None


# ─── Response schema ──────────────────────────────────────────────────────────

class RegistroClinicoResponse(BaseModel):
    id: str
    id_paciente: str
    id_cita: Optional[str] = None
    id_doctor: str
    fecha: date
    anamnesis: Optional[str] = None
    exploracion_fisica: Optional[str] = None
    diagnostico: Optional[str] = None
    tratamiento: Optional[str] = None
    observaciones: Optional[str] = None
    creado_en: Optional[datetime] = None
