from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_current_user
from app.core.supabase_client import get_supabase_admin
from app.schemas.auth import UserProfile
from app.schemas.audiometria import AnalisisAudiometriaResponse, SesionAudiometriaResponse
from app.schemas.imagenes_timpanicas import AnalisisIAResponse, ImagenTimpanicaResponse
from app.schemas.pacientes import PacienteResponse
from app.schemas.registros_clinicos import RegistroClinicoResponse

router = APIRouter(prefix="/mi-portal", tags=["Portal Paciente"])


def _solo_paciente(usuario_actual: UserProfile = Depends(get_current_user)) -> UserProfile:
    if usuario_actual.role != "paciente":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso restringido a pacientes",
        )
    return usuario_actual


def _obtener_paciente_vinculado(admin, usuario_id: str) -> dict:
    resp = (
        admin.table("pacientes")
        .select("*")
        .eq("usuario_id", usuario_id)
        .maybe_single()
        .execute()
    )
    if resp is None or resp.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No se encontró un expediente vinculado a esta cuenta",
        )
    return resp.data


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.get(
    "/perfil",
    response_model=PacienteResponse,
    summary="Ver datos propios del paciente",
)
def mi_perfil(
    usuario_actual: UserProfile = Depends(_solo_paciente),
) -> PacienteResponse:
    admin = get_supabase_admin()
    paciente = _obtener_paciente_vinculado(admin, usuario_actual.id)
    return PacienteResponse(**paciente)


@router.get(
    "/historial",
    response_model=List[RegistroClinicoResponse],
    summary="Ver historial clínico propio",
)
def mi_historial(
    usuario_actual: UserProfile = Depends(_solo_paciente),
) -> List[RegistroClinicoResponse]:
    admin = get_supabase_admin()
    paciente = _obtener_paciente_vinculado(admin, usuario_actual.id)

    resp = (
        admin.table("registros_clinicos")
        .select("*")
        .eq("id_paciente", paciente["id"])
        .order("fecha", desc=True)
        .execute()
    )
    return [RegistroClinicoResponse(**r) for r in resp.data]


@router.get(
    "/imagenes",
    response_model=List[ImagenTimpanicaResponse],
    summary="Ver imágenes timpánicas propias con análisis IA",
)
def mis_imagenes(
    usuario_actual: UserProfile = Depends(_solo_paciente),
) -> List[ImagenTimpanicaResponse]:
    admin = get_supabase_admin()
    paciente = _obtener_paciente_vinculado(admin, usuario_actual.id)

    resp_registros = (
        admin.table("registros_clinicos")
        .select("id")
        .eq("id_paciente", paciente["id"])
        .execute()
    )
    ids_registros = [r["id"] for r in resp_registros.data]
    if not ids_registros:
        return []

    resp = (
        admin.table("imagenes_timpanicas")
        .select("*")
        .in_("id_registro", ids_registros)
        .order("capturado_en", desc=True)
        .execute()
    )

    resultado = []
    for img in resp.data:
        resp_a = (
            admin.table("ia_analisis_timpanico")
            .select("*")
            .eq("id_imagen", img["id"])
            .maybe_single()
            .execute()
        )
        analisis = AnalisisIAResponse(**resp_a.data) if resp_a and resp_a.data else None
        resultado.append(ImagenTimpanicaResponse(**img, analisis=analisis))
    return resultado


@router.get(
    "/audiometrias",
    response_model=List[SesionAudiometriaResponse],
    summary="Ver sesiones de audiometría propias con análisis IA",
)
def mis_audiometrias(
    usuario_actual: UserProfile = Depends(_solo_paciente),
) -> List[SesionAudiometriaResponse]:
    admin = get_supabase_admin()
    paciente = _obtener_paciente_vinculado(admin, usuario_actual.id)

    resp = (
        admin.table("sesiones_audiometria")
        .select("*")
        .eq("id_paciente", paciente["id"])
        .order("realizado_en", desc=True)
        .execute()
    )

    resultado = []
    for ses in resp.data:
        resp_a = (
            admin.table("ia_analisis_audiometria")
            .select("*")
            .eq("id_sesion", ses["id"])
            .maybe_single()
            .execute()
        )
        analisis = AnalisisAudiometriaResponse(**resp_a.data) if resp_a and resp_a.data else None
        resultado.append(SesionAudiometriaResponse(**ses, analisis=analisis))
    return resultado
