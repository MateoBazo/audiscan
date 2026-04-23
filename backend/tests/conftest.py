import os
from unittest.mock import MagicMock, patch

import pytest


# Variables de entorno falsas
os.environ.setdefault("SUPABASE_URL", "https://mock.supabase.co")
os.environ.setdefault("SUPABASE_ANON_KEY", "mock-anon-key")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "mock-service-role-key")
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://mock:mock@localhost/mock")
os.environ.setdefault("ENVIRONMENT", "test")
os.environ.setdefault("DEBUG", "false")


#Mock de Supabase
@pytest.fixture(autouse=True)
def mock_supabase_client():
    cliente_falso = MagicMock()

    # Simulamos la cadena de llamadas que usa el código real:
    # admin.table("x").select("*").eq("id", ...).execute()
    cliente_falso.table.return_value.select.return_value \
        .eq.return_value.maybe_single.return_value \
        .execute.return_value.data = None

    with patch("app.core.supabase_client.create_client", return_value=cliente_falso):
        yield cliente_falso


#Mock de SQLAlchemy
@pytest.fixture(autouse=True)
def mock_sqlalchemy_engine():
    motor_falso = MagicMock()

    with patch(
        "sqlalchemy.ext.asyncio.create_async_engine",
        return_value=motor_falso,
    ):
        yield motor_falso


#Datos 
@pytest.fixture
def datos_registro_valido() -> dict:
    return {
        "email": "doctor@audiscan.bo",
        "password": "Segura123!",
        "full_name": "Dr. Juan Pérez",
        "role": "doctor",
        "license_number": "MP-4521",
    }


@pytest.fixture
def estados_esperados() -> set:
    return {"programada", "completada", "cancelada", "no_asistio"}