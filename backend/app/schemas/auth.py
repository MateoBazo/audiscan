from pydantic import BaseModel, EmailStr
from typing import Literal, Optional


# ─── Request schemas ──────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    role: Literal["doctor", "assistant"]
    license_number: Optional[str] = None  # Requerido para doctor, opcional para asistente


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# ─── Response schemas ─────────────────────────────────────────────────────────

class UserProfile(BaseModel):
    id: str
    email: str
    full_name: str
    role: Literal["doctor", "assistant"]
    license_number: Optional[str] = None


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserProfile
