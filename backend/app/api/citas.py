from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.dependencies import get_current_user
from app.core.supabase_client import get_supabase_admin
from app.schemas.auth import UserProfile
from app.schemas.citas import (
    ActualizarCitaRequest,
    CambiarEstadoRequest,
    CitaResponse,
    CrearCitaRequest,
)

ESTADOS_VALIDOS = {"programada", "completada", "cancelada", "no_asistio"}

router = APIRouter(prefix="/citas", tags=["Citas"])


@router.post(
    "/",
    response_model=CitaResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar nueva cita",
)
def crear_cita(
    cuerpo: CrearCitaRequest,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> CitaResponse:
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

    datos = {
        "id_doctor": usuario_actual.id,
        "id_paciente": cuerpo.id_paciente,
        "fecha_hora": cuerpo.fecha_hora.isoformat(),
        "duracion_minutos": cuerpo.duracion_minutos,
        "motivo": cuerpo.motivo,
        "notas": cuerpo.notas,
    }

    try:
        respuesta = admin.table("citas").insert(datos).execute()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al registrar cita: {str(e)}",
        )

    return CitaResponse(**respuesta.data[0])


@router.get(
    "/",
    response_model=List[CitaResponse],
    summary="Listar citas del médico autenticado",
)
def listar_citas(
    estado: Optional[str] = Query(None, description="Filtrar por estado"),
    fecha_desde: Optional[str] = Query(None, description="Filtrar desde fecha (ISO)"),
    fecha_hasta: Optional[str] = Query(None, description="Filtrar hasta fecha (ISO)"),
    usuario_actual: UserProfile = Depends(get_current_user),
) -> List[CitaResponse]:
    admin = get_supabase_admin()

    consulta = (
        admin.table("citas")
        .select("*")
        .eq("id_doctor", usuario_actual.id)
    )

    if estado:
        if estado not in ESTADOS_VALIDOS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Estado inválido. Opciones: {', '.join(ESTADOS_VALIDOS)}",
            )
        consulta = consulta.eq("estado", estado)

    if fecha_desde:
        consulta = consulta.gte("fecha_hora", fecha_desde)

    if fecha_hasta:
        consulta = consulta.lte("fecha_hora", fecha_hasta)

    respuesta = consulta.order("fecha_hora").execute()

    return [CitaResponse(**cita) for cita in respuesta.data]


@router.get(
    "/{cita_id}",
    response_model=CitaResponse,
    summary="Obtener cita por ID",
)
def obtener_cita(
    cita_id: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> CitaResponse:
    admin = get_supabase_admin()

    respuesta = (
        admin.table("citas")
        .select("*")
        .eq("id", cita_id)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )

    if respuesta is None or respuesta.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cita no encontrada",
        )

    return CitaResponse(**respuesta.data)


@router.put(
    "/{cita_id}",
    response_model=CitaResponse,
    summary="Actualizar datos de una cita",
)
def actualizar_cita(
    cita_id: str,
    cuerpo: ActualizarCitaRequest,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> CitaResponse:
    admin = get_supabase_admin()

    existente = (
        admin.table("citas")
        .select("id")
        .eq("id", cita_id)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )

    if existente is None or existente.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cita no encontrada",
        )

    datos_actualizados = cuerpo.model_dump(exclude_none=True)

    if "fecha_hora" in datos_actualizados:
        datos_actualizados["fecha_hora"] = datos_actualizados["fecha_hora"].isoformat()

    if not datos_actualizados:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se enviaron datos para actualizar",
        )

    # Si se cambia el paciente, verificar que pertenece al médico
    if "id_paciente" in datos_actualizados:
        paciente = (
            admin.table("pacientes")
            .select("id")
            .eq("id", datos_actualizados["id_paciente"])
            .eq("medico_id", usuario_actual.id)
            .maybe_single()
            .execute()
        )
        if paciente is None or paciente.data is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Paciente no encontrado",
            )

    try:
        respuesta = (
            admin.table("citas")
            .update(datos_actualizados)
            .eq("id", cita_id)
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al actualizar cita: {str(e)}",
        )

    return CitaResponse(**respuesta.data[0])


@router.patch(
    "/{cita_id}/estado",
    response_model=CitaResponse,
    summary="Cambiar estado de una cita",
)
def cambiar_estado_cita(
    cita_id: str,
    cuerpo: CambiarEstadoRequest,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> CitaResponse:
    admin = get_supabase_admin()

    if cuerpo.estado not in ESTADOS_VALIDOS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Estado inválido. Opciones: {', '.join(ESTADOS_VALIDOS)}",
        )

    existente = (
        admin.table("citas")
        .select("id")
        .eq("id", cita_id)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )

    if existente is None or existente.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cita no encontrada",
        )

    try:
        respuesta = (
            admin.table("citas")
            .update({"estado": cuerpo.estado})
            .eq("id", cita_id)
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al cambiar estado: {str(e)}",
        )

    return CitaResponse(**respuesta.data[0])


@router.delete(
    "/{cita_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar cita",
)
def eliminar_cita(
    cita_id: str,
    usuario_actual: UserProfile = Depends(get_current_user),
):
    admin = get_supabase_admin()

    existente = (
        admin.table("citas")
        .select("id")
        .eq("id", cita_id)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )

    if existente is None or existente.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cita no encontrada",
        )

    try:
        admin.table("citas").delete().eq("id", cita_id).execute()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al eliminar cita: {str(e)}",
        )
