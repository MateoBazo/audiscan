from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings

app = FastAPI(
    title="AudiScan API",
    version="0.1.0",
    description="Backend clínico para AudiScan — asistente IA en otorrinolaringología",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["Sistema"])
async def health_check():
    """Endpoint de verificación — confirma que el backend está vivo."""
    return {"status": "ok", "service": "audiscan-api", "version": "0.1.0"}
