import pytest
from pydantic import ValidationError



# TEST 1 — Auth: Validación de formato de email en RegisterRequest

class TestRegisterEmailInvalido:
    """
    Suite de pruebas para la validación del campo `email` en RegisterRequest.

    El schema usa `EmailStr` de pydantic, que rechaza automáticamente
    cualquier string que no cumpla el formato estándar de correo electrónico
    (RFC 5322). Esto protege al sistema de intentos de registro con datos
    malformados antes de llegar a Supabase Auth.
    """

    def test_email_sin_arroba_lanza_validation_error(self, datos_registro_valido):
        """
        Prueba: RegisterRequest debe rechazar un email sin símbolo '@'.

        Precondición : Datos de registro válidos en todos los demás campos.
        Entrada      : email = 'no-es-un-email' (sin '@' ni dominio)
        Esperado     : pydantic.ValidationError con error en el campo 'email'
        Fundamento   : El campo `email: EmailStr` en RegisterRequest valida
                       el formato antes de cualquier llamada a Supabase.
        """
        from app.schemas.auth import RegisterRequest

        datos_registro_valido["email"] = "no-es-un-email"

        with pytest.raises(ValidationError) as exc_info:
            RegisterRequest(**datos_registro_valido)

        errores = exc_info.value.errors()
        campos_con_error = [e["loc"][0] for e in errores]

        assert "email" in campos_con_error, (
            f"Se esperaba error en el campo 'email', "
            f"pero los errores fueron en: {campos_con_error}"
        )

    def test_email_sin_dominio_lanza_validation_error(self, datos_registro_valido):
        """
        Prueba: RegisterRequest debe rechazar un email sin dominio completo.

        Precondición : Datos de registro válidos en todos los demás campos.
        Entrada      : email = 'usuario@' (sin dominio después del '@')
        Esperado     : pydantic.ValidationError con error en el campo 'email'
        Fundamento   : Pydantic valida que exista un dominio válido después
                       del símbolo '@'.
        """
        from app.schemas.auth import RegisterRequest

        datos_registro_valido["email"] = "usuario@"

        with pytest.raises(ValidationError) as exc_info:
            RegisterRequest(**datos_registro_valido)

        errores = exc_info.value.errors()
        campos_con_error = [e["loc"][0] for e in errores]

        assert "email" in campos_con_error

    def test_email_valido_no_lanza_error(self, datos_registro_valido):
        """
        Prueba: RegisterRequest debe aceptar sin error un email correctamente formateado.

        Precondición : Datos de registro válidos en todos los campos.
        Entrada      : email = 'doctor@audiscan.bo' (formato RFC 5322 válido)
        Esperado     : Se crea la instancia de RegisterRequest sin excepciones
        Fundamento   : Caso positivo — confirma que la validación no rechaza
                       emails correctos.
        """
        from app.schemas.auth import RegisterRequest

        instancia = RegisterRequest(**datos_registro_valido)

        assert instancia.email == "doctor@audiscan.bo"


# TEST 2 — Auth: Validación de rol permitido en RegisterRequest

class TestRegisterRolInvalido:
    """
    Suite de pruebas para la validación del campo `role` en RegisterRequest.

    El sistema AudiScan solo permite dos roles: 'doctor' y 'assistant'.
    El schema usa `Literal["doctor", "assistant"]` de pydantic para
    garantizar este contrato en tiempo de validación, sin necesidad de
    consultar la base de datos.
    """

    def test_rol_desconocido_lanza_validation_error(self, datos_registro_valido):
        """
        Prueba: RegisterRequest debe rechazar roles no definidos en el sistema.

        Precondición : Datos de registro válidos en todos los demás campos.
        Entrada      : role = 'admin' (rol no contemplado en el sistema)
        Esperado     : pydantic.ValidationError con error en el campo 'role'
        Fundamento   : El campo `role: Literal["doctor", "assistant"]` solo
                       acepta exactamente esos dos valores. Cualquier otro
                       string es rechazado por Pydantic antes de llegar al
                       endpoint de registro.
        """
        from app.schemas.auth import RegisterRequest

        datos_registro_valido["role"] = "admin"

        with pytest.raises(ValidationError) as exc_info:
            RegisterRequest(**datos_registro_valido)

        errores = exc_info.value.errors()
        campos_con_error = [e["loc"][0] for e in errores]

        assert "role" in campos_con_error, (
            f"Se esperaba error en el campo 'role', "
            f"pero los errores fueron en: {campos_con_error}"
        )

    def test_rol_vacio_lanza_validation_error(self, datos_registro_valido):
        """
        Prueba: RegisterRequest debe rechazar un rol con string vacío.

        Precondición : Datos de registro válidos en todos los demás campos.
        Entrada      : role = '' (string vacío)
        Esperado     : pydantic.ValidationError con error en el campo 'role'
        Fundamento   : Un string vacío no coincide con ninguno de los
                       literales permitidos ('doctor' o 'assistant').
        """
        from app.schemas.auth import RegisterRequest

        datos_registro_valido["role"] = ""

        with pytest.raises(ValidationError) as exc_info:
            RegisterRequest(**datos_registro_valido)

        errores = exc_info.value.errors()
        campos_con_error = [e["loc"][0] for e in errores]

        assert "role" in campos_con_error

    @pytest.mark.parametrize("rol_valido", ["doctor", "assistant"])
    def test_roles_validos_son_aceptados(self, datos_registro_valido, rol_valido):
        """
        Prueba: RegisterRequest debe aceptar exactamente los roles 'doctor' y 'assistant'.

        Precondición : Datos de registro válidos en todos los demás campos.
        Entrada      : role = 'doctor' | role = 'assistant'
        Esperado     : Se crea la instancia de RegisterRequest sin excepciones
        Fundamento   : Caso positivo parametrizado — verifica que ambos
                       roles del sistema son aceptados correctamente.
        """
        from app.schemas.auth import RegisterRequest

        datos_registro_valido["role"] = rol_valido

        instancia = RegisterRequest(**datos_registro_valido)

        assert instancia.role == rol_valido


# TEST 3 — Citas: Integridad del conjunto ESTADOS_VALIDOS

class TestEstadosValidosCitas:
    """
    Suite de pruebas para la constante ESTADOS_VALIDOS del módulo de citas.

    ESTADOS_VALIDOS es la fuente de verdad que determina qué transiciones
    de estado son permitidas en el ciclo de vida de una cita médica.
    Cambios no controlados en este conjunto pueden romper filtros, validaciones
    y lógica de negocio en toda la aplicación.

    Estados del ciclo de vida de una cita en AudiScan:
        programada → completada | cancelada | no_asistio
    """

    def test_estados_validos_contiene_exactamente_los_estados_esperados(
        self, estados_esperados
    ):
        """
        Prueba: ESTADOS_VALIDOS debe contener exactamente los 4 estados clínicos definidos.

        Precondición : El módulo app.api.citas está importado correctamente.
        Entrada      : Conjunto esperado = {'programada', 'completada', 'cancelada', 'no_asistio'}
        Esperado     : ESTADOS_VALIDOS == estados_esperados (igualdad exacta de conjuntos)
        Fundamento   : Esta prueba actúa como contrato: si alguien agrega o
                       elimina un estado sin actualizar esta prueba, el test
                       fallará inmediatamente, alertando del cambio no
                       coordinado en la lógica de negocio.
        """
        from app.api.citas import ESTADOS_VALIDOS

        assert ESTADOS_VALIDOS == estados_esperados, (
            f"ESTADOS_VALIDOS no coincide con el contrato esperado.\n"
            f"  Actuales  : {sorted(ESTADOS_VALIDOS)}\n"
            f"  Esperados : {sorted(estados_esperados)}\n"
            f"  Sobrantes : {ESTADOS_VALIDOS - estados_esperados}\n"
            f"  Faltantes : {estados_esperados - ESTADOS_VALIDOS}"
        )

    def test_estado_programada_existe(self):
        """
        Prueba: El estado inicial 'programada' debe estar en ESTADOS_VALIDOS.

        Precondición : El módulo app.api.citas está importado correctamente.
        Entrada      : Verificar presencia del string 'programada'
        Esperado     : 'programada' in ESTADOS_VALIDOS
        Fundamento   : Toda cita nueva se crea con estado 'programada'.
                       Si este estado no existe, ninguna cita puede ser
                       creada ni filtrada correctamente.
        """
        from app.api.citas import ESTADOS_VALIDOS

        assert "programada" in ESTADOS_VALIDOS

    def test_estado_inexistente_no_esta_en_estados_validos(self):
        """
        Prueba: ESTADOS_VALIDOS no debe contener estados inventados o no definidos.

        Precondición : El módulo app.api.citas está importado correctamente.
        Entrada      : Verificar ausencia del string 'pendiente' (estado no definido)
        Esperado     : 'pendiente' not in ESTADOS_VALIDOS
        Fundamento   : Evita que estados no documentados sean silenciosamente
                       aceptados. 'pendiente' es un nombre intuitivo que
                       alguien podría usar por error en lugar de 'programada'.
        """
        from app.api.citas import ESTADOS_VALIDOS

        assert "pendiente" not in ESTADOS_VALIDOS, (
            "El estado 'pendiente' no debería existir. "
            "El estado inicial correcto es 'programada'."
        )