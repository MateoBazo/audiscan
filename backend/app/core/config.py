from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Supabase
    SUPABASE_URL: str
    SUPABASE_ANON_KEY: str
    SUPABASE_SERVICE_ROLE_KEY: str

    # Base de datos directa
    DATABASE_URL: str

    # JWT — solo para referencia de expiración, la verificación la hace Supabase
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # Entorno
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"


settings = Settings()