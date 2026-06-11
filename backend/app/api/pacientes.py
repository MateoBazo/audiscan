from typing import List

from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_current_user, resolver_id_doctor, solo_doctor
from app.core.supabase_client import get_supabase_admin
from app.schemas.auth import UserProfile
from app.schemas.pacientes import (
    ActualizarPacienteRequest,
    CrearCuentaPacienteRequest,
    CrearPacienteRequest,
    PacienteResponse,
)

router = APIRouter(prefix="/pacientes", tags=["Pacientes"])


@router.post(
    "/",
    response_model=PacienteResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar nuevo paciente",
)
def crear_paciente(
    cuerpo: CrearPacienteRequest,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> PacienteResponse:
    admin = get_supabase_admin()
    id_doctor = resolver_id_doctor(usuario_actual)

    datos = {
        "medico_id": id_doctor,
        "nombre_completo": cuerpo.nombre_completo,
        "fecha_nacimiento": (
            cuerpo.fecha_nacimiento.isoformat() if cuerpo.fecha_nacimiento else None
        ),
        "informacion_contacto": cuerpo.informacion_contacto,
    }

    try:
        respuesta = admin.table("pacientes").insert(datos).execute()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al registrar paciente: {str(e)}",
        )

    return PacienteResponse(**respuesta.data[0])


@router.get(
    "/",
    response_model=List[PacienteResponse],
    summary="Listar pacientes del médico autenticado",
)
def listar_pacientes(
    usuario_actual: UserProfile = Depends(get_current_user),
) -> List[PacienteResponse]:
    admin = get_supabase_admin()
    id_doctor = resolver_id_doctor(usuario_actual)

    respuesta = (
        admin.table("pacientes")
        .select("*")
        .eq("medico_id", id_doctor)
        .order("creado_en", desc=True)
        .execute()
    )

    return [PacienteResponse(**paciente) for paciente in respuesta.data]


@router.get(
    "/{paciente_id}",
    response_model=PacienteResponse,
    summary="Obtener paciente por ID",
)
def obtener_paciente(
    paciente_id: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> PacienteResponse:
    admin = get_supabase_admin()
    id_doctor = resolver_id_doctor(usuario_actual)

    respuesta = (
        admin.table("pacientes")
        .select("*")
        .eq("id", paciente_id)
        .eq("medico_id", id_doctor)
        .maybe_single()
        .execute()
    )

    if respuesta is None or respuesta.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paciente no encontrado",
        )

    return PacienteResponse(**respuesta.data)


@router.put(
    "/{paciente_id}",
    response_model=PacienteResponse,
    summary="Actualizar datos de un paciente",
)
def actualizar_paciente(
    paciente_id: str,
    cuerpo: ActualizarPacienteRequest,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> PacienteResponse:
    admin = get_supabase_admin()
    id_doctor = resolver_id_doctor(usuario_actual)

    existente = (
        admin.table("pacientes")
        .select("id")
        .eq("id", paciente_id)
        .eq("medico_id", id_doctor)
        .maybe_single()
        .execute()
    )

    if existente is None or existente.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paciente no encontrado",
        )

    datos_actualizados = cuerpo.model_dump(exclude_none=True)

    if "fecha_nacimiento" in datos_actualizados:
        datos_actualizados["fecha_nacimiento"] = datos_actualizados[
            "fecha_nacimiento"
        ].isoformat()

    if not datos_actualizados:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se enviaron datos para actualizar",
        )

    try:
        respuesta = (
            admin.table("pacientes")
            .update(datos_actualizados)
            .eq("id", paciente_id)
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al actualizar paciente: {str(e)}",
        )

    return PacienteResponse(**respuesta.data[0])


@router.post(
    "/{paciente_id}/crear-cuenta",
    status_code=status.HTTP_201_CREATED,
    summary="Crear cuenta de acceso para un paciente (solo médico)",
)
def crear_cuenta_paciente(
    paciente_id: str,
    cuerpo: CrearCuentaPacienteRequest,
    usuario_actual: UserProfile = Depends(solo_doctor),
):
    admin = get_supabase_admin()

    # Verificar que el paciente pertenece al médico
    resp_paciente = (
        admin.table("pacientes")
        .select("id, nombre_completo, usuario_id")
        .eq("id", paciente_id)
        .eq("medico_id", usuario_actual.id)
        .maybe_single()
        .execute()
    )
    if resp_paciente is None or resp_paciente.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paciente no encontrado",
        )

    paciente = resp_paciente.data

    if paciente.get("usuario_id"):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Este paciente ya tiene una cuenta de acceso",
        )

    # Crear usuario en Supabase Auth
    try:
        auth_resp = admin.auth.admin.create_user({
            "email": cuerpo.email,
            "password": cuerpo.contrasena_temporal,
            "email_confirm": True,
        })
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"No se pudo crear la cuenta: {str(e)}",
        )

    nuevo_usuario_id = auth_resp.user.id

    # Insertar perfil en la tabla users con rol paciente
    try:
        admin.table("users").insert({
            "id": nuevo_usuario_id,
            "email": cuerpo.email,
            "full_name": paciente["nombre_completo"],
            "role": "paciente",
        }).execute()
    except Exception as e:
        # Rollback: eliminar el usuario de Auth
        try:
            admin.auth.admin.delete_user(nuevo_usuario_id)
        except Exception:
            pass
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al guardar perfil: {str(e)}",
        )

    # Vincular usuario al paciente
    try:
        admin.table("pacientes").update({"usuario_id": nuevo_usuario_id}).eq("id", paciente_id).execute()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al vincular cuenta con el paciente: {str(e)}",
        )

    return {
        "mensaje": f"Cuenta creada correctamente para {paciente['nombre_completo']}. El paciente puede iniciar sesión con el email y contraseña proporcionados.",
        "email": cuerpo.email,
    }


@router.delete(
    "/{paciente_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar paciente",
)
def eliminar_paciente(
    paciente_id: str,
    usuario_actual: UserProfile = Depends(get_current_user),
):
    admin = get_supabase_admin()
    id_doctor = resolver_id_doctor(usuario_actual)

    existente = (
        admin.table("pacientes")
        .select("id")
        .eq("id", paciente_id)
        .eq("medico_id", id_doctor)
        .maybe_single()
        .execute()
    )

    if existente is None or existente.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paciente no encontrado",
        )

    try:
        admin.table("pacientes").delete().eq("id", paciente_id).execute()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al eliminar paciente: {str(e)}",
        )
