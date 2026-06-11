from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, EmailStr


# ─── Request schemas ──────────────────────────────────────────────────────────

class CrearPacienteRequest(BaseModel):
    nombre_completo: str
    fecha_nacimiento: Optional[date] = None
    informacion_contacto: Optional[dict] = None


class ActualizarPacienteRequest(BaseModel):
    nombre_completo: Optional[str] = None
    fecha_nacimiento: Optional[date] = None
    informacion_contacto: Optional[dict] = None


class CrearCuentaPacienteRequest(BaseModel):
    email: EmailStr
    contrasena_temporal: str


# ─── Response schema ──────────────────────────────────────────────────────────

class PacienteResponse(BaseModel):
    id: str
    medico_id: str
    nombre_completo: str
    fecha_nacimiento: Optional[date] = None
    informacion_contacto: Optional[dict] = None
    usuario_id: Optional[str] = None
    creado_en: Optional[datetime] = None
