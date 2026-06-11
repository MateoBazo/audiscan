import io
from datetime import date, datetime
from typing import List, Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    HRFlowable,
    Image,
    KeepTogether,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from app.core.dependencies import get_current_user, solo_doctor
from app.core.supabase_client import get_supabase_admin
from app.schemas.auth import UserProfile

router = APIRouter(
    prefix="/reportes",
    tags=["Reportes"],
    dependencies=[Depends(solo_doctor)],
)

# ─── Paleta ───────────────────────────────────────────────────────────────────

# Color primario de la app (teal médico)
_PRIMARIO       = colors.HexColor("#00897B")
_PRIMARIO_CLARO = colors.HexColor("#E0F2F1")

# Azul clínico — solo para OD en audiometría y clasificación sensorioneural
_AZUL_CLINICO  = colors.HexColor("#1565C0")
_AZUL_CLARO    = colors.HexColor("#E3F2FD")

_ROJO        = colors.HexColor("#C62828")
_VERDE       = colors.HexColor("#2E7D32")
_NARANJA     = colors.HexColor("#E65100")
_MORADO      = colors.HexColor("#4A148C")
_GRIS_FONDO  = colors.HexColor("#F5F5F5")
_GRIS_BORDE  = colors.HexColor("#BDBDBD")
_TEXTO       = colors.HexColor("#212121")
_TEXTO_SUAVE = colors.HexColor("#757575")

_FRECUENCIAS = ["250 Hz", "500 Hz", "1 kHz", "2 kHz", "4 kHz", "8 kHz"]
_CAMPOS_OD   = ["od_250hz", "od_500hz", "od_1000hz", "od_2000hz", "od_4000hz", "od_8000hz"]
_CAMPOS_OI   = ["oi_250hz", "oi_500hz", "oi_1000hz", "oi_2000hz", "oi_4000hz", "oi_8000hz"]

_ETIQUETA_TIPO = {
    "normal": "Normal",
    "conductiva": "Conductiva",
    "sensorioneural": "Sensorioneural",
    "mixta": "Mixta",
}
_ETIQUETA_GRADO = {
    "normal": "Normal",
    "leve": "Leve",
    "moderado": "Moderado",
    "severo": "Severo",
    "profundo": "Profundo",
}
_COLOR_TIPO = {
    "normal": _VERDE,
    "conductiva": _NARANJA,
    "sensorioneural": _AZUL_CLINICO,
    "mixta": _MORADO,
}


# ─── Estilos ──────────────────────────────────────────────────────────────────

def _estilos() -> dict:
    base = getSampleStyleSheet()
    return {
        "titulo_header": ParagraphStyle(
            "titulo_header", parent=base["Normal"],
            fontSize=18, textColor=colors.white, leading=22, spaceAfter=0,
        ),
        "sub_header": ParagraphStyle(
            "sub_header", parent=base["Normal"],
            fontSize=8, textColor=colors.HexColor("#BBDEFB"), leading=11, spaceAfter=2,
        ),
        "sec_titulo": ParagraphStyle(
            "sec_titulo", parent=base["Normal"],
            fontSize=10, textColor=colors.white, leading=14, spaceAfter=0,
        ),
        "label": ParagraphStyle(
            "label", parent=base["Normal"],
            fontSize=7, textColor=_TEXTO_SUAVE, leading=10, spaceAfter=1,
        ),
        "valor": ParagraphStyle(
            "valor", parent=base["Normal"],
            fontSize=9, textColor=_TEXTO, leading=13, spaceAfter=0,
        ),
        "normal": ParagraphStyle(
            "normal_p", parent=base["Normal"],
            fontSize=9, textColor=_TEXTO, leading=13,
        ),
        "small": ParagraphStyle(
            "small_p", parent=base["Normal"],
            fontSize=7, textColor=_TEXTO_SUAVE, leading=10,
        ),
        "disclaimer": ParagraphStyle(
            "disclaimer", parent=base["Normal"],
            fontSize=7, textColor=_TEXTO_SUAVE, leading=10, alignment=1,
        ),
    }


# ─── Helpers de construcción ──────────────────────────────────────────────────

def _seccion(titulo: str, e: dict) -> Table:
    t = Table([[Paragraph(f"<b>{titulo}</b>", e["sec_titulo"])]], colWidths=["*"])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), _PRIMARIO),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
    ]))
    return t


def _campo_cell(label: str, valor: Optional[str], e: dict) -> list:
    return [
        Paragraph(label.upper(), e["label"]),
        Paragraph(valor if valor else "—", e["valor"]),
    ]


def _tarjeta(contenido: list, ancho: float) -> Table:
    t = Table([[contenido]], colWidths=[ancho])
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("BACKGROUND", (0, 0), (-1, -1), _GRIS_FONDO),
        ("BOX", (0, 0), (-1, -1), 0.5, _GRIS_BORDE),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
    ]))
    return t


def _formatear_fecha(valor) -> str:
    if valor is None:
        return "—"
    if isinstance(valor, datetime):
        return valor.strftime("%d/%m/%Y")
    if isinstance(valor, date):
        return valor.strftime("%d/%m/%Y")
    try:
        return datetime.fromisoformat(str(valor).replace("Z", "+00:00")).strftime("%d/%m/%Y")
    except Exception:
        return str(valor)


def _descargar_imagen(url: str) -> Optional[bytes]:
    try:
        resp = httpx.get(url, timeout=10.0, follow_redirects=True)
        if resp.status_code == 200:
            return resp.content
    except Exception:
        pass
    return None


# ─── Construcción del PDF ─────────────────────────────────────────────────────

def _construir_pdf(
    registro: dict,
    paciente: dict,
    medico_nombre: str,
    medico_matricula: Optional[str],
    imagenes: List[dict],
    sesiones: List[dict],
) -> bytes:
    buffer = io.BytesIO()
    ancho_pagina, _ = A4
    margen = 2 * cm
    ancho = ancho_pagina - 2 * margen

    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=margen,
        leftMargin=margen,
        topMargin=margen,
        bottomMargin=margen + 0.5 * cm,
        title="Reporte Clínico - AudiScan",
        author=medico_nombre,
    )

    e = _estilos()
    h = []  # historia (flowables)

    # ── Encabezado ────────────────────────────────────────────────────────────
    fecha_gen = datetime.now().strftime("%d/%m/%Y %H:%M")
    matricula = f"Matrícula: {medico_matricula}" if medico_matricula else ""

    celda_izq = [Paragraph("<b>AudiScan · Reporte Clínico</b>", e["titulo_header"])]
    celda_der = [
        Paragraph(f"Dr./Dra. {medico_nombre}", e["sub_header"]),
        Paragraph(matricula, e["sub_header"]),
        Paragraph(f"Generado: {fecha_gen}", e["sub_header"]),
    ]

    header = Table(
        [[celda_izq, celda_der]],
        colWidths=[ancho * 0.58, ancho * 0.42],
    )
    header.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), _PRIMARIO),
        ("VALIGN", (0, 0), (0, 0), "MIDDLE"),
        ("VALIGN", (0, 0), (1, 0), "MIDDLE"),
        ("ALIGN", (1, 0), (1, 0), "RIGHT"),
        ("TOPPADDING", (0, 0), (-1, -1), 12),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 12),
        ("LEFTPADDING", (0, 0), (0, 0), 14),
        ("RIGHTPADDING", (1, 0), (1, 0), 14),
    ]))
    h.append(header)
    h.append(Spacer(1, 0.5 * cm))

    # ── Datos del paciente ────────────────────────────────────────────────────
    h.append(_seccion("Datos del Paciente", e))
    h.append(Spacer(1, 0.2 * cm))

    contacto = paciente.get("informacion_contacto") or {}
    telefono = contacto.get("telefono") or contacto.get("phone") or None
    email_pac = contacto.get("email") or None
    direccion = contacto.get("direccion") or contacto.get("address") or None

    paciente_fila1 = Table(
        [[
            _campo_cell("Nombre completo", paciente.get("nombre_completo"), e),
            _campo_cell("Fecha de nacimiento", _formatear_fecha(paciente.get("fecha_nacimiento")), e),
        ]],
        colWidths=[ancho * 0.56, ancho * 0.44],
    )
    paciente_fila1.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("BACKGROUND", (0, 0), (-1, -1), _GRIS_FONDO),
        ("BOX", (0, 0), (-1, -1), 0.5, _GRIS_BORDE),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
    ]))
    h.append(paciente_fila1)

    if telefono or email_pac:
        h.append(Spacer(1, 0.08 * cm))
        paciente_fila2 = Table(
            [[
                _campo_cell("Teléfono", telefono, e),
                _campo_cell("Correo electrónico", email_pac, e),
            ]],
            colWidths=[ancho * 0.5, ancho * 0.5],
        )
        paciente_fila2.setStyle(TableStyle([
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("BACKGROUND", (0, 0), (-1, -1), _GRIS_FONDO),
            ("BOX", (0, 0), (-1, -1), 0.5, _GRIS_BORDE),
            ("TOPPADDING", (0, 0), (-1, -1), 8),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ("LEFTPADDING", (0, 0), (-1, -1), 10),
            ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ]))
        h.append(paciente_fila2)

    if direccion:
        h.append(Spacer(1, 0.08 * cm))
        h.append(_tarjeta(_campo_cell("Dirección", direccion, e), ancho))

    h.append(Spacer(1, 0.4 * cm))

    # ── Registro clínico ──────────────────────────────────────────────────────
    h.append(_seccion("Registro Clínico", e))
    h.append(Spacer(1, 0.2 * cm))

    campos_registro = [
        ("Fecha de consulta", _formatear_fecha(registro.get("fecha"))),
        ("Anamnesis", registro.get("anamnesis")),
        ("Exploración física", registro.get("exploracion_fisica")),
        ("Diagnóstico", registro.get("diagnostico")),
        ("Tratamiento", registro.get("tratamiento")),
        ("Observaciones", registro.get("observaciones")),
    ]
    for label, valor in campos_registro:
        if valor:
            h.append(_tarjeta(_campo_cell(label, valor, e), ancho))
            h.append(Spacer(1, 0.08 * cm))

    h.append(Spacer(1, 0.3 * cm))

    # ── Imágenes timpánicas ───────────────────────────────────────────────────
    if imagenes:
        h.append(_seccion("Imágenes Timpánicas", e))
        h.append(Spacer(1, 0.2 * cm))

        for img in imagenes:
            analisis = img.get("analisis")
            oido = img.get("oido") or "—"
            oido_txt = "Oído Derecho (OD)" if oido == "OD" else "Oído Izquierdo (OI)" if oido == "OI" else oido
            fecha_img = _formatear_fecha(img.get("capturado_en"))

            img_bytes = _descargar_imagen(img["ruta_imagen"])
            img_elem = None
            if img_bytes:
                try:
                    img_elem = Image(io.BytesIO(img_bytes), width=4.5 * cm, height=4.5 * cm)
                    img_elem.hAlign = "CENTER"
                except Exception:
                    img_elem = None

            pred = ""
            confianza_txt = "—"
            color_pred = _PRIMARIO
            if analisis:
                pred = analisis.get("prediccion") or ""
                conf = analisis.get("confianza")
                confianza_txt = f"{conf * 100:.1f}%" if conf is not None else "—"
                color_pred = _COLOR_TIPO.get(pred, _PRIMARIO)

            pred_label = _ETIQUETA_TIPO.get(pred, pred.capitalize()) if pred else "—"

            col_info = [
                Paragraph(f"<b>{oido_txt}</b>", e["valor"]),
                Spacer(1, 4),
                Paragraph("PREDICCIÓN IA", e["label"]),
                Paragraph(pred_label, ParagraphStyle(
                    "pred_col", parent=e["valor"],
                    textColor=color_pred, fontSize=10,
                )),
                Spacer(1, 2),
                Paragraph("CONFIANZA", e["label"]),
                Paragraph(confianza_txt, e["valor"]),
                Spacer(1, 2),
                Paragraph("FECHA CAPTURA", e["label"]),
                Paragraph(fecha_img, e["valor"]),
            ]
            col_img = [img_elem if img_elem else Paragraph("(imagen no disponible)", e["small"])]

            fila_img = Table(
                [[col_img, col_info]],
                colWidths=[5 * cm, ancho - 5 * cm],
            )
            fila_img.setStyle(TableStyle([
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("BACKGROUND", (0, 0), (-1, -1), _GRIS_FONDO),
                ("BOX", (0, 0), (-1, -1), 0.5, _GRIS_BORDE),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
            ]))
            h.append(KeepTogether([fila_img]))
            h.append(Spacer(1, 0.2 * cm))

        h.append(Spacer(1, 0.2 * cm))

    # ── Audiometrías ──────────────────────────────────────────────────────────
    if sesiones:
        h.append(_seccion("Audiometrías", e))
        h.append(Spacer(1, 0.2 * cm))

        for ses in sesiones:
            analisis = ses.get("analisis")
            fecha_ses = _formatear_fecha(ses.get("realizado_en"))

            # Tabla de umbrales
            fila_header = [
                Paragraph("<b>Frec.</b>", e["normal"]),
                Paragraph("<b>● OD (dB HL)</b>", ParagraphStyle(
                    "od_h", parent=e["normal"], textColor=_AZUL_CLINICO)),
                Paragraph("<b>× OI (dB HL)</b>", ParagraphStyle(
                    "oi_h", parent=e["normal"], textColor=_ROJO)),
            ]
            filas = [fila_header]
            for i, freq in enumerate(_FRECUENCIAS):
                val_od = ses.get(_CAMPOS_OD[i])
                val_oi = ses.get(_CAMPOS_OI[i])
                filas.append([
                    Paragraph(freq, e["normal"]),
                    Paragraph(
                        str(val_od) if val_od is not None else "—",
                        ParagraphStyle("od_v", parent=e["normal"], textColor=_AZUL_CLINICO),
                    ),
                    Paragraph(
                        str(val_oi) if val_oi is not None else "—",
                        ParagraphStyle("oi_v", parent=e["normal"], textColor=_ROJO),
                    ),
                ])

            ancho_freq = 2.8 * cm
            ancho_oido = (ancho * 0.46 - ancho_freq) / 2
            tabla_umbrales = Table(filas, colWidths=[ancho_freq, ancho_oido, ancho_oido])
            tabla_umbrales.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), _PRIMARIO_CLARO),
                ("GRID", (0, 0), (-1, -1), 0.5, _GRIS_BORDE),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, _GRIS_FONDO]),
            ]))

            # Columna IA
            col_ia = []
            if analisis:
                pred_od = analisis.get("prediccion_od") or ""
                pred_oi = analisis.get("prediccion_oi") or ""
                grado_od = analisis.get("grado_od") or ""
                grado_oi = analisis.get("grado_oi") or ""
                conf_od = analisis.get("confianza_od")
                conf_oi = analisis.get("confianza_oi")
                recomendacion = analisis.get("recomendacion") or ""

                def _linea_oido(pred: str, grado: str, conf, color) -> list:
                    tipo_txt = _ETIQUETA_TIPO.get(pred, pred.capitalize()) if pred else "—"
                    grado_txt = _ETIQUETA_GRADO.get(grado, grado.capitalize()) if grado else "—"
                    conf_txt = f"  ({conf * 100:.0f}%)" if conf is not None else ""
                    return [
                        Paragraph(
                            f"<b>{tipo_txt}</b> · {grado_txt}{conf_txt}",
                            ParagraphStyle("oido_ia", parent=e["normal"], textColor=color),
                        ),
                    ]

                col_ia += [Paragraph("ANÁLISIS IA", e["label"])]
                col_ia += _linea_oido(pred_od, grado_od, conf_od, _COLOR_TIPO.get(pred_od, _PRIMARIO))
                col_ia += [Paragraph("Oído Derecho (OD)", e["small"]), Spacer(1, 3)]
                col_ia += _linea_oido(pred_oi, grado_oi, conf_oi, _COLOR_TIPO.get(pred_oi, _ROJO))
                col_ia += [Paragraph("Oído Izquierdo (OI)", e["small"])]
                if recomendacion:
                    col_ia += [
                        Spacer(1, 6),
                        Paragraph("RECOMENDACIÓN", e["label"]),
                        Paragraph(recomendacion, e["normal"]),
                    ]
            else:
                col_ia = [Paragraph("Sin análisis IA disponible", e["small"])]

            fila_ses = Table(
                [[tabla_umbrales, col_ia]],
                colWidths=[ancho * 0.46, ancho * 0.54],
            )
            fila_ses.setStyle(TableStyle([
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("BACKGROUND", (0, 0), (-1, -1), _GRIS_FONDO),
                ("BOX", (0, 0), (-1, -1), 0.5, _GRIS_BORDE),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
            ]))

            bloque = [
                Paragraph(f"<b>Audiometría — {fecha_ses}</b>", e["valor"]),
                Spacer(1, 0.15 * cm),
                fila_ses,
            ]
            if ses.get("observaciones"):
                bloque += [
                    Spacer(1, 0.08 * cm),
                    _tarjeta(_campo_cell("Observaciones", ses["observaciones"], e), ancho),
                ]

            h.append(KeepTogether(bloque))
            h.append(Spacer(1, 0.3 * cm))

    # ── Footer ────────────────────────────────────────────────────────────────
    h.append(Spacer(1, 0.3 * cm))
    h.append(HRFlowable(width="100%", thickness=0.5, color=_GRIS_BORDE))
    h.append(Spacer(1, 0.2 * cm))
    h.append(Paragraph(
        "Este reporte es generado por AudiScan como herramienta de apoyo clínico. "
        "Los resultados de la IA son orientativos y no constituyen un diagnóstico autónomo. "
        "El médico especialista es responsable de validar toda la información clínica aquí presentada.",
        e["disclaimer"],
    ))

    doc.build(h)
    return buffer.getvalue()


# ─── Endpoint ─────────────────────────────────────────────────────────────────

@router.get(
    "/registro/{id_registro}",
    summary="Generar reporte PDF de un registro clínico",
    response_class=StreamingResponse,
)
def generar_reporte(
    id_registro: str,
    usuario_actual: UserProfile = Depends(get_current_user),
):
    admin = get_supabase_admin()

    resp_reg = (
        admin.table("registros_clinicos")
        .select("*")
        .eq("id", id_registro)
        .eq("id_doctor", usuario_actual.id)
        .maybe_single()
        .execute()
    )
    if resp_reg is None or resp_reg.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro clínico no encontrado",
        )
    registro = resp_reg.data

    resp_pac = (
        admin.table("pacientes")
        .select("*")
        .eq("id", registro["id_paciente"])
        .maybe_single()
        .execute()
    )
    paciente = resp_pac.data if resp_pac and resp_pac.data else {}

    # Imágenes con análisis
    resp_imgs = (
        admin.table("imagenes_timpanicas")
        .select("*")
        .eq("id_registro", id_registro)
        .eq("id_doctor", usuario_actual.id)
        .order("capturado_en", desc=True)
        .execute()
    )
    imagenes: List[dict] = []
    for img in (resp_imgs.data or []):
        resp_a = (
            admin.table("ia_analisis_timpanico")
            .select("*")
            .eq("id_imagen", img["id"])
            .maybe_single()
            .execute()
        )
        img["analisis"] = resp_a.data if resp_a else None
        imagenes.append(img)

    # Sesiones con análisis
    resp_ses = (
        admin.table("sesiones_audiometria")
        .select("*")
        .eq("id_registro", id_registro)
        .eq("id_doctor", usuario_actual.id)
        .order("realizado_en", desc=True)
        .execute()
    )
    sesiones: List[dict] = []
    for ses in (resp_ses.data or []):
        resp_a = (
            admin.table("ia_analisis_audiometria")
            .select("*")
            .eq("id_sesion", ses["id"])
            .maybe_single()
            .execute()
        )
        ses["analisis"] = resp_a.data if resp_a else None
        sesiones.append(ses)

    try:
        pdf_bytes = _construir_pdf(
            registro=registro,
            paciente=paciente,
            medico_nombre=usuario_actual.full_name,
            medico_matricula=usuario_actual.license_number,
            imagenes=imagenes,
            sesiones=sesiones,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al generar el PDF: {exc}",
        )

    nombre_archivo = f"reporte_{id_registro[:8]}.pdf"
    return StreamingResponse(
        io.BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{nombre_archivo}"',
            "Content-Length": str(len(pdf_bytes)),
        },
    )
