import re
import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.responses import Response

from ai.tympanic_classifier import clasificador_timpanico
from app.core.dependencies import get_current_user
from app.core.supabase_client import get_supabase_admin
from app.schemas.auth import UserProfile
from app.schemas.imagenes_timpanicas import AnalisisIAResponse, ImagenTimpanicaResponse

router = APIRouter(prefix="/imagenes-timpanicas", tags=["Imágenes Timpánicas"])

BUCKET = "tympanic-images"
EXTENSIONES_PERMITIDAS = {"image/jpeg", "image/png", "image/webp"}
TAMANO_MAXIMO_MB = 10
VERSION_MODELO = "tympanic_v1"


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _verificar_registro(admin, id_registro: str, id_doctor: str) -> None:
    registro = (
        admin.table("registros_clinicos")
        .select("id")
        .eq("id", id_registro)
        .eq("id_doctor", id_doctor)
        .maybe_single()
        .execute()
    )
    if registro is None or registro.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro clínico no encontrado",
        )


def _obtener_analisis(admin, id_imagen: str) -> Optional[dict]:
    resp = (
        admin.table("ia_analisis_timpanico")
        .select("*")
        .eq("id_imagen", id_imagen)
        .maybe_single()
        .execute()
    )
    return resp.data if resp else None


def _construir_respuesta(imagen: dict, analisis: Optional[dict]) -> ImagenTimpanicaResponse:
    analisis_response = AnalisisIAResponse(**analisis) if analisis else None
    return ImagenTimpanicaResponse(**imagen, analisis=analisis_response)


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.post(
    "/",
    response_model=ImagenTimpanicaResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Subir imagen timpánica y obtener análisis IA",
)
def subir_imagen(
    id_registro: str = Form(...),
    archivo: UploadFile = File(...),
    oido: Optional[str] = Form(None),
    usuario_actual: UserProfile = Depends(get_current_user),
) -> ImagenTimpanicaResponse:
    admin = get_supabase_admin()

    _verificar_registro(admin, id_registro, usuario_actual.id)

    if archivo.content_type not in EXTENSIONES_PERMITIDAS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Formato no permitido. Usa: {', '.join(EXTENSIONES_PERMITIDAS)}",
        )

    contenido = archivo.file.read()
    if len(contenido) > TAMANO_MAXIMO_MB * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"La imagen supera el límite de {TAMANO_MAXIMO_MB} MB",
        )

    # Sanitizar nombre de archivo — eliminar caracteres problemáticos para URLs
    extension = archivo.filename.rsplit(".", 1)[-1].lower() if "." in archivo.filename else "jpg"
    nombre_seguro = f"{uuid.uuid4().hex}.{extension}"

    # Subir al bucket de Supabase Storage
    ruta_storage = f"{usuario_actual.id}/{id_registro}/{nombre_seguro}"

    try:
        admin.storage.from_(BUCKET).upload(
            path=ruta_storage,
            file=contenido,
            file_options={"content-type": archivo.content_type, "upsert": "true"},
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al subir imagen al storage: {str(e)}",
        )

    url_publica = admin.storage.from_(BUCKET).get_public_url(ruta_storage)

    # Guardar en tabla imagenes_timpanicas
    datos_imagen = {
        "id_registro": id_registro,
        "id_doctor": usuario_actual.id,
        "ruta_imagen": url_publica,
        "oido": oido,
    }

    try:
        resp_imagen = admin.table("imagenes_timpanicas").insert(datos_imagen).execute()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al guardar imagen en BD: {str(e)}",
        )

    imagen_guardada = resp_imagen.data[0]
    id_imagen = imagen_guardada["id"]

    # Clasificar con IA
    resultado_ia = clasificador_timpanico.predecir(contenido)
    version = "mock" if resultado_ia["modo_mock"] else VERSION_MODELO

    datos_analisis = {
        "id_imagen": id_imagen,
        "prediccion": resultado_ia["prediccion"],
        "confianza": resultado_ia["confianza"],
        "probabilidades": resultado_ia["probabilidades"],
        "version_modelo": version,
    }

    try:
        resp_analisis = (
            admin.table("ia_analisis_timpanico").insert(datos_analisis).execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al guardar análisis IA en BD: {str(e)}",
        )

    return _construir_respuesta(imagen_guardada, resp_analisis.data[0])


@router.get(
    "/registro/{id_registro}",
    response_model=List[ImagenTimpanicaResponse],
    summary="Listar imágenes timpánicas de un registro clínico",
)
def listar_imagenes_registro(
    id_registro: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> List[ImagenTimpanicaResponse]:
    admin = get_supabase_admin()

    _verificar_registro(admin, id_registro, usuario_actual.id)

    resp = (
        admin.table("imagenes_timpanicas")
        .select("*")
        .eq("id_registro", id_registro)
        .eq("id_doctor", usuario_actual.id)
        .order("capturado_en", desc=True)
        .execute()
    )

    return [
        _construir_respuesta(img, _obtener_analisis(admin, img["id"]))
        for img in resp.data
    ]


@router.get(
    "/paciente/{id_paciente}",
    response_model=List[ImagenTimpanicaResponse],
    summary="Listar todas las imágenes timpánicas de un paciente",
)
def listar_imagenes_paciente(
    id_paciente: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> List[ImagenTimpanicaResponse]:
    admin = get_supabase_admin()

    # Obtener registros del paciente que pertenecen al médico
    resp_registros = (
        admin.table("registros_clinicos")
        .select("id")
        .eq("id_paciente", id_paciente)
        .eq("id_doctor", usuario_actual.id)
        .execute()
    )

    ids_registros = [r["id"] for r in resp_registros.data]
    if not ids_registros:
        return []

    resp = (
        admin.table("imagenes_timpanicas")
        .select("*")
        .in_("id_registro", ids_registros)
        .eq("id_doctor", usuario_actual.id)
        .order("capturado_en", desc=True)
        .execute()
    )

    return [
        _construir_respuesta(img, _obtener_analisis(admin, img["id"]))
        for img in resp.data
    ]


@router.get(
    "/{imagen_id}",
    response_model=ImagenTimpanicaResponse,
    summary="Obtener imagen timpánica con su análisis IA",
)
def obtener_imagen(
    imagen_id: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> ImagenTimpanicaResponse:
    admin = get_supabase_admin()

    resp = (
        admin.table("imagenes_timpanicas")
        .select("*")
        .eq("id", imagen_id)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )

    if resp is None or resp.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Imagen no encontrada",
        )

    return _construir_respuesta(resp.data, _obtener_analisis(admin, imagen_id))


@router.get(
    "/{imagen_id}/grad-cam",
    summary="Obtener overlay Grad-CAM de una imagen timpánica",
    response_class=Response,
)
def obtener_grad_cam(
    imagen_id: str,
    usuario_actual: UserProfile = Depends(get_current_user),
) -> Response:
    import httpx

    admin = get_supabase_admin()

    resp = (
        admin.table("imagenes_timpanicas")
        .select("ruta_imagen")
        .eq("id", imagen_id)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )

    if resp is None or resp.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Imagen no encontrada",
        )

    # Extraer ruta relativa desde la URL pública para descargar via Storage API
    url_imagen = resp.data["ruta_imagen"]
    marcador = f"/object/public/{BUCKET}/"
    idx = url_imagen.find(marcador)
    if idx == -1:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="No se pudo determinar la ruta de la imagen en storage",
        )
    ruta_relativa = url_imagen[idx + len(marcador):].rstrip("?")

    try:
        respuesta_storage = admin.storage.from_(BUCKET).download(ruta_relativa)
        contenido = bytes(respuesta_storage)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error al descargar imagen del storage: {str(e)}",
        )

    png_bytes = clasificador_timpanico.generar_grad_cam(contenido)

    return Response(content=png_bytes, media_type="image/png")
