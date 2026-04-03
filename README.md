# AudiScan 🩺

**Asistente Clínico con IA para Otorrinolaringología**

Plataforma mobile-first para el médico otorrino. Centraliza la gestión de
consulta (pacientes, citas, historia clínica) y la potencia con módulos de IA
para apoyar la detección y clasificación de patologías auditivas.

> La IA es el asistente. El médico siempre toma la decisión clínica final.

---

## Stack

| Capa | Tecnología |
|------|-----------|
| App móvil | Flutter (Dart) + Riverpod |
| Backend | FastAPI (Python) + SQLAlchemy async |
| Base de datos | PostgreSQL via Supabase |
| Auth | Supabase Auth (JWT) |
| Storage | Supabase Storage |
| ML Imágenes | TensorFlow/Keras — EfficientNetB3 + Grad-CAM |
| ML Tabular | scikit-learn / XGBoost |
| PDF | ReportLab |
| Teleconsulta | WebRTC + flutter_webrtc |
| Contenedores | Docker + Docker Compose |
| Deploy | Railway / Render (backend) + Supabase cloud |

---

## Estructura

```
audiscan/
├── backend/
│   ├── app/          # FastAPI — lógica de negocio
│   ├── ai/           # Modelos y pipelines de IA
│   ├── notebooks/    # Experimentación y entrenamiento
│   └── Dockerfile
├── mobile/           # Flutter app (ios + android)
├── docker-compose.yml
└── README.md
```

---

## Setup rápido

### 1. Clonar y configurar entorno

```bash
git clone https://github.com/TU_USUARIO/audiscan.git
cd audiscan
cp backend/.env.example backend/.env
# Editar backend/.env con tus credenciales de Supabase
```

### 2. Levantar backend con Docker

```bash
docker-compose up --build
# Backend disponible en http://localhost:8000
# Docs en http://localhost:8000/docs
```

### 3. App Flutter

```bash
cd mobile
flutter pub get
flutter run
```

---

## Roadmap

| Fase | Módulo | Estado |
|------|--------|--------|
| 0 | Setup — repo, Docker, Flutter, Supabase | 🔄 En progreso |
| 1 | Auth y roles | ⏳ Pendiente |
| 2 | Gestión de pacientes | ⏳ Pendiente |
| 3 | Agenda y citas | ⏳ Pendiente |
| 4 | Historia clínica digital | ⏳ Pendiente |
| 5 | IA — imagen timpánica (CNN) | ⏳ Pendiente |
| 6 | IA — audiograma (ML tabular) | ⏳ Pendiente |
| 7 | Reportes PDF | ⏳ Pendiente |
| 8 | Teleconsulta WebRTC | ⏳ Pendiente |
| 9 | Screening de riesgo + sugerencias clínicas | ⏳ Pendiente |
| 10 | Polish, pruebas, deploy | ⏳ Pendiente |

---

## Consideraciones de seguridad

- Datos clínicos cifrados en tránsito (HTTPS/WSS) y en reposo
- RLS habilitado en Supabase — un médico no accede a datos de otro
- La IA nunca emite diagnóstico autónomo — todo pasa por validación médica
- Imágenes timpánicas tratadas como datos médicos sensibles

---

*Proyecto de tesis — UNIFRANZ Cochabamba, Bolivia*
