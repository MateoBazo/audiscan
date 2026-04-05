from typing import List

from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_current_user
from app.core.supabase_client import get_supabase_admin
from app.schemas.auth import UserProfile
from app.schemas.registros_clinicos import (
    ActualizarRegistroClinicoRequest,
    CrearRegistroClinicoRequest,
    RegistroClinicoResponse,
)

router = APIRouter(prefix="/registros-clinicos", tags=["Registros Clínicos"])


@router.post(
    "/",
    response_model=RegistroClinicoResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Crear registro clínico",
)
def crear_registro(
    cuerpo: CrearRegistroClinicoRequest,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> RegistroClinicoResponse:
    admin = get_supabase_admin()

    # Verificar que el paciente pertenece al médico
    paciente = (
        admin.table("pacientes")
        .select("id")
        .eq("id", cuerpo.id_paciente)
        .eq("medico_id", usuario_actual.id)
        .maybe_single()
        .execute()
    )
    if paciente is None or paciente.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paciente no encontrado",
        )

    # Si se asocia una cita, verificar que pertenece al médico
    if cuerpo.id_cita:
        cita = (
            admin.table("citas")
            .select("id")
            .eq("id", cuerpo.id_cita)
            .eq("id_doctor", usuario_actual.id)
            .maybe_single()
            .execute()
        )
        if cita is None or cita.data is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cita no encontrada",
            )

    datos = {
        "id_paciente": cuerpo.id_paciente,
        "id_cita": cuerpo.id_cita,
        "id_doctor": usuario_actual.id,
        "anamnesis": cuerpo.anamnesis,
        "exploracion_fisica": cuerpo.exploracion_fisica,
        "diagnostico": cuerpo.diagnostico,
        "tratamiento": cuerpo.tratamiento,
        "observaciones": cuerpo.observaciones,
    }

    if cuerpo.fecha:
        datos["fecha"] = cuerpo.fecha.isoformat()

    try:
        respuesta = admin.table("registros_clinicos").insert(datos).execute()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al crear registro clínico: {str(e)}",
        )

    return RegistroClinicoResponse(**respuesta.data[0])


@router.get(
    "/paciente/{id_paciente}",
    response_model=List[RegistroClinicoResponse],
    summary="Obtener historial clínico de un paciente",
)
def listar_registros_paciente(
    id_paciente: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> List[RegistroClinicoResponse]:
    admin = get_supabase_admin()

    # Verificar que el paciente pertenece al médico
    paciente = (
        admin.table("pacientes")
        .select("id")
        .eq("id", id_paciente)
        .eq("medico_id", usuario_actual.id)
        .maybe_single()
        .execute()
    )
    if paciente is None or paciente.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paciente no encontrado",
        )

    respuesta = (
        admin.table("registros_clinicos")
        .select("*")
        .eq("id_paciente", id_paciente)
        .eq("id_doctor", usuario_actual.id)
        .order("fecha", desc=True)
        .execute()
    )

    return [RegistroClinicoResponse(**r) for r in respuesta.data]


@router.get(
    "/{registro_id}",
    response_model=RegistroClinicoResponse,
    summary="Obtener registro clínico por ID",
)
def obtener_registro(
    registro_id: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> RegistroClinicoResponse:
    admin = get_supabase_admin()

    respuesta = (
        admin.table("registros_clinicos")
        .select("*")
        .eq("id", registro_id)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )

    if respuesta is None or respuesta.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro clínico no encontrado",
        )

    return RegistroClinicoResponse(**respuesta.data)


@router.put(
    "/{registro_id}",
    response_model=RegistroClinicoResponse,
    summary="Actualizar registro clínico",
)
def actualizar_registro(
    registro_id: str,
    cuerpo: ActualizarRegistroClinicoRequest,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> RegistroClinicoResponse:
    admin = get_supabase_admin()

    existente = (
        admin.table("registros_clinicos")
        .select("id")
        .eq("id", registro_id)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )

    if existente is None or existente.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro clínico no encontrado",
        )

    datos_actualizados = cuerpo.model_dump(exclude_none=True)

    if "fecha" in datos_actualizados:
        datos_actualizados["fecha"] = datos_actualizados["fecha"].isoformat()

    if not datos_actualizados:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se enviaron datos para actualizar",
        )

    try:
        respuesta = (
            admin.table("registros_clinicos")
            .update(datos_actualizados)
            .eq("id", registro_id)
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al actualizar registro clínico: {str(e)}",
        )

    return RegistroClinicoResponse(**respuesta.data[0])


@router.delete(
    "/{registro_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar registro clínico",
)
def eliminar_registro(
    registro_id: str,
    usuario_actual: UserProfile = Depends(get_current_user),
):
    admin = get_supabase_admin()

    existente = (
        admin.table("registros_clinicos")
        .select("id")
        .eq("id", registro_id)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )

    if existente is None or existente.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro clínico no encontrado",
        )

    try:
        admin.table("registros_clinicos").delete().eq("id", registro_id).execute()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al eliminar registro clínico: {str(e)}",
        )
