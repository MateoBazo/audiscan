from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.auth import router as auth_router
from app.api.citas import router as citas_router
from app.api.pacientes import router as pacientes_router
from app.api.registros_clinicos import router as registros_clinicos_router
from app.core.config import settings

app = FastAPI(
    title="AudiScan API",
    description="Backend clínico para otorrinolaringología con módulos de IA",
    version="0.1.0",
    docs_url="/docs" if settings.ENVIRONMENT == "development" else None,
    redoc_url="/redoc" if settings.ENVIRONMENT == "development" else None,
)

# CORS — ajustar origins en producción
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Routers ──────────────────────────────────────────────────────────────────
app.include_router(auth_router, prefix="/api/v1")
app.include_router(pacientes_router, prefix="/api/v1")
app.include_router(citas_router, prefix="/api/v1")
app.include_router(registros_clinicos_router, prefix="/api/v1")


# ─── Health check ─────────────────────────────────────────────────────────────
@app.get("/health", tags=["System"])
def health_check():
    return {"status": "ok", "env": settings.ENVIRONMENT}