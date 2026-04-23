import pytest
from pydantic import ValidationError


# TEST 1 — Auth: Validación de formato de email en RegisterRequest

class TestRegisterEmailInvalido:

    def test_email_sin_arroba_lanza_validation_error(self, datos_registro_valido):
        from app.schemas.auth import RegisterRequest
        datos_registro_valido["email"] = "no-es-un-email"
        with pytest.raises(ValidationError) as exc_info:
            RegisterRequest(**datos_registro_valido)
        campos_con_error = [e["loc"][0] for e in exc_info.value.errors()]
        assert "email" in campos_con_error

    def test_email_sin_dominio_lanza_validation_error(self, datos_registro_valido):
        from app.schemas.auth import RegisterRequest
        datos_registro_valido["email"] = "usuario@"
        with pytest.raises(ValidationError) as exc_info:
            RegisterRequest(**datos_registro_valido)
        campos_con_error = [e["loc"][0] for e in exc_info.value.errors()]
        assert "email" in campos_con_error

    def test_email_valido_no_lanza_error(self, datos_registro_valido):
        from app.schemas.auth import RegisterRequest
        instancia = RegisterRequest(**datos_registro_valido)
        assert instancia.email == "doctor@audiscan.bo"


# TEST 2 — Auth: Validación de rol permitido en RegisterRequest

class TestRegisterRolInvalido:

    def test_rol_desconocido_lanza_validation_error(self, datos_registro_valido):
        from app.schemas.auth import RegisterRequest
        datos_registro_valido["role"] = "admin"
        with pytest.raises(ValidationError) as exc_info:
            RegisterRequest(**datos_registro_valido)
        campos_con_error = [e["loc"][0] for e in exc_info.value.errors()]
        assert "role" in campos_con_error

    def test_rol_vacio_lanza_validation_error(self, datos_registro_valido):
        from app.schemas.auth import RegisterRequest
        datos_registro_valido["role"] = ""
        with pytest.raises(ValidationError) as exc_info:
            RegisterRequest(**datos_registro_valido)
        campos_con_error = [e["loc"][0] for e in exc_info.value.errors()]
        assert "role" in campos_con_error

    @pytest.mark.parametrize("rol_valido", ["doctor", "assistant"])
    def test_roles_validos_son_aceptados(self, datos_registro_valido, rol_valido):
        from app.schemas.auth import RegisterRequest
        datos_registro_valido["role"] = rol_valido
        instancia = RegisterRequest(**datos_registro_valido)
        assert instancia.role == rol_valido



# TEST 3 — Citas: Integridad del conjunto ESTADOS_VALIDOS

class TestEstadosValidosCitas:

    def test_estados_validos_contiene_exactamente_los_estados_esperados(
        self, estados_esperados
    ):
        from app.api.citas import ESTADOS_VALIDOS
        assert ESTADOS_VALIDOS == estados_esperados, (
            f"ESTADOS_VALIDOS no coincide con el contrato esperado.\n"
            f"Actuales  : {sorted(ESTADOS_VALIDOS)}\n"
            f"Esperados : {sorted(estados_esperados)}\n"
            f"Sobrantes : {ESTADOS_VALIDOS - estados_esperados}\n"
            f"Faltantes : {estados_esperados - ESTADOS_VALIDOS}"
        )

    def test_estado_programada_existe(self):
        from app.api.citas import ESTADOS_VALIDOS
        assert "programada" in ESTADOS_VALIDOS

    def test_estado_inexistente_no_esta_en_estados_validos(self):
        from app.api.citas import ESTADOS_VALIDOS

        assert "pendiente" not in ESTADOS_VALIDOS, (
        )