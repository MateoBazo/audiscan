from datetime import datetime
from typing import Optional

from pydantic import BaseModel


# ─── Request schemas ──────────────────────────────────────────────────────────

class CrearCitaRequest(BaseModel):
    id_paciente: str
    fecha_hora: datetime
    duracion_minutos: int = 30
    motivo: Optional[str] = None
    notas: Optional[str] = None


class ActualizarCitaRequest(BaseModel):
    id_paciente: Optional[str] = None
    fecha_hora: Optional[datetime] = None
    duracion_minutos: Optional[int] = None
    motivo: Optional[str] = None
    notas: Optional[str] = None


class CambiarEstadoRequest(BaseModel):
    estado: str  # programada | completada | cancelada | no_asistio


# ─── Response schema ──────────────────────────────────────────────────────────

class CitaResponse(BaseModel):
    id: str
    id_doctor: str
    id_paciente: str
    fecha_hora: datetime
    duracion_minutos: int
    motivo: Optional[str] = None
    estado: str
    notas: Optional[str] = None
    creado_en: Optional[datetime] = None
