from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status

from ai.audiogram_classifier import clasificador_audiograma
from app.core.dependencies import get_current_user
from app.core.supabase_client import get_supabase_admin
from app.schemas.auth import UserProfile
from app.schemas.audiometria import (
    AnalisisAudiometriaResponse,
    SesionAudiometriaCreate,
    SesionAudiometriaResponse,
)

router = APIRouter(prefix="/audiometria", tags=["Audiometría"])

VERSION_MODELO = "audiometry_v1"


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _verificar_registro(admin, id_registro: str, id_doctor: str) -> dict:
    resp = (
        admin.table("registros_clinicos")
        .select("id, id_paciente")
        .eq("id", id_registro)
        .eq("id_doctor", id_doctor)
        .maybe_single()
        .execute()
    )
    if resp is None or resp.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro clínico no encontrado",
        )
    return resp.data


def _obtener_analisis(admin, id_sesion: str) -> Optional[dict]:
    resp = (
        admin.table("ia_analisis_audiometria")
        .select("*")
        .eq("id_sesion", id_sesion)
        .maybe_single()
        .execute()
    )
    return resp.data if resp else None


def _construir_respuesta(sesion: dict, analisis: Optional[dict]) -> SesionAudiometriaResponse:
    analisis_response = AnalisisAudiometriaResponse(**analisis) if analisis else None
    return SesionAudiometriaResponse(**sesion, analisis=analisis_response)


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.post(
    "/",
    response_model=SesionAudiometriaResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar sesión de audiometría y obtener análisis IA",
)
def crear_sesion(
    datos: SesionAudiometriaCreate,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> SesionAudiometriaResponse:
    admin = get_supabase_admin()

    registro = _verificar_registro(admin, datos.id_registro, usuario_actual.id)

    datos_sesion = {
        "id_registro": datos.id_registro,
        "id_paciente": registro["id_paciente"],
        "id_doctor": usuario_actual.id,
        "od_250hz":  int(datos.od_250hz),
        "od_500hz":  int(datos.od_500hz),
        "od_1000hz": int(datos.od_1000hz),
        "od_2000hz": int(datos.od_2000hz),
        "od_4000hz": int(datos.od_4000hz),
        "od_8000hz": int(datos.od_8000hz),
        "oi_250hz":  int(datos.oi_250hz),
        "oi_500hz":  int(datos.oi_500hz),
        "oi_1000hz": int(datos.oi_1000hz),
        "oi_2000hz": int(datos.oi_2000hz),
        "oi_4000hz": int(datos.oi_4000hz),
        "oi_8000hz": int(datos.oi_8000hz),
        "observaciones": datos.observaciones,
    }

    try:
        resp_sesion = admin.table("sesiones_audiometria").insert(datos_sesion).execute()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al guardar sesión en BD: {exc}",
        )

    sesion_guardada = resp_sesion.data[0]
    id_sesion = sesion_guardada["id"]

    umbrales_od = [
        datos.od_250hz, datos.od_500hz, datos.od_1000hz,
        datos.od_2000hz, datos.od_4000hz, datos.od_8000hz,
    ]
    umbrales_oi = [
        datos.oi_250hz, datos.oi_500hz, datos.oi_1000hz,
        datos.oi_2000hz, datos.oi_4000hz, datos.oi_8000hz,
    ]
    resultado_ia = clasificador_audiograma.predecir(umbrales_od, umbrales_oi)
    version = "mock" if resultado_ia["modo_mock"] else VERSION_MODELO

    datos_analisis = {
        "id_sesion":        id_sesion,
        "prediccion_od":    resultado_ia["prediccion_od"],
        "prediccion_oi":    resultado_ia["prediccion_oi"],
        "grado_od":         resultado_ia["grado_od"],
        "grado_oi":         resultado_ia["grado_oi"],
        "confianza_od":     resultado_ia["confianza_od"],
        "confianza_oi":     resultado_ia["confianza_oi"],
        "probabilidades_od": resultado_ia["probabilidades_od"],
        "probabilidades_oi": resultado_ia["probabilidades_oi"],
        "recomendacion":    resultado_ia["recomendacion"],
        "version_modelo":   version,
    }

    try:
        resp_analisis = (
            admin.table("ia_analisis_audiometria").insert(datos_analisis).execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al guardar análisis IA en BD: {exc}",
        )

    return _construir_respuesta(sesion_guardada, resp_analisis.data[0])


@router.get(
    "/registro/{id_registro}",
    response_model=List[SesionAudiometriaResponse],
    summary="Listar sesiones de audiometría de un registro clínico",
)
def listar_sesiones_registro(
    id_registro: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> List[SesionAudiometriaResponse]:
    admin = get_supabase_admin()

    _verificar_registro(admin, id_registro, usuario_actual.id)

    resp = (
        admin.table("sesiones_audiometria")
        .select("*")
        .eq("id_registro", id_registro)
        .eq("id_doctor", usuario_actual.id)
        .order("realizado_en", desc=True)
        .execute()
    )

    return [
        _construir_respuesta(s, _obtener_analisis(admin, s["id"]))
        for s in resp.data
    ]


@router.get(
    "/paciente/{id_paciente}",
    response_model=List[SesionAudiometriaResponse],
    summary="Listar todas las sesiones de audiometría de un paciente",
)
def listar_sesiones_paciente(
    id_paciente: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> List[SesionAudiometriaResponse]:
    admin = get_supabase_admin()

    resp = (
        admin.table("sesiones_audiometria")
        .select("*")
        .eq("id_paciente", id_paciente)
        .eq("id_doctor", usuario_actual.id)
        .order("realizado_en", desc=True)
        .execute()
    )

    return [
        _construir_respuesta(s, _obtener_analisis(admin, s["id"]))
        for s in resp.data
    ]


@router.get(
    "/{id_sesion}",
    response_model=SesionAudiometriaResponse,
    summary="Obtener sesión de audiometría con su análisis IA",
)
def obtener_sesion(
    id_sesion: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> SesionAudiometriaResponse:
    admin = get_supabase_admin()

    resp = (
        admin.table("sesiones_audiometria")
        .select("*")
        .eq("id", id_sesion)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )

    if resp is None or resp.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sesión de audiometría no encontrada",
        )

    return _construir_respuesta(resp.data, _obtener_analisis(admin, id_sesion))


@router.delete(
    "/{id_sesion}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar sesión de audiometría y su análisis IA",
)
def eliminar_sesion(
    id_sesion: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> None:
    admin = get_supabase_admin()

    resp = (
        admin.table("sesiones_audiometria")
        .select("id")
        .eq("id", id_sesion)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )

    if resp is None or resp.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sesión de audiometría no encontrada",
        )

    try:
        admin.table("sesiones_audiometria").delete().eq("id", id_sesion).execute()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al eliminar sesión: {str(e)}",
        )
