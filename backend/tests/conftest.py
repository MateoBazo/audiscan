import os
import pytest


# Variables de entorno para pruebas
# Se definen ANTES de importar cualquier módulo de la app para que
# pydantic-settings no falle al intentar leer un .env inexistente.

os.environ.setdefault("SUPABASE_URL", "https://test.supabase.co")
os.environ.setdefault("SUPABASE_ANON_KEY", "test-anon-key")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "test-service-role-key")
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://test:test@localhost/test")
os.environ.setdefault("ENVIRONMENT", "test")
os.environ.setdefault("DEBUG", "false")


# Fixtures reutilizables 
@pytest.fixture
def datos_registro_valido() -> dict:
    """
    Fixture: datos mínimos y válidos para crear un RegisterRequest.

    Retorna un diccionario con todos los campos requeridos correctamente
    formateados. Sirve como base para tests que necesitan partir de un
    estado válido y modificar solo el campo bajo prueba.
    """
    return {
        "email": "doctor@audiscan.bo",
        "password": "Segura123!",
        "full_name": "Dr. Juan Pérez",
        "role": "doctor",
        "license_number": "MP-4521",
    }


@pytest.fixture
def estados_esperados() -> set:
    """
    Fixture: conjunto de estados clínicos válidos para una cita.

    Define el contrato de negocio: estos son los únicos estados que
    el sistema debe aceptar para el campo `estado` de una cita médica.
    """
    return {"programada", "completada", "cancelada", "no_asistio"}