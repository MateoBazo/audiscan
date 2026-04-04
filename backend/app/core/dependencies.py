from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.supabase_client import get_supabase_admin, get_supabase_anon
from app.schemas.auth import UserProfile

bearer_scheme = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> UserProfile:
    """
    Dependencia reutilizable para endpoints protegidos.
    Delega la verificación del JWT directamente a Supabase Auth —
    no se necesita el JWT Secret local.
    """
    token = credentials.credentials

    # 1. Verificar el token preguntándole a Supabase directamente
    anon_client = get_supabase_anon()
    try:
        auth_response = anon_client.auth.get_user(token)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if auth_response.user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = auth_response.user.id

    # 2. Obtener el perfil completo desde la tabla `users`
    admin_client = get_supabase_admin()
    db_response = (
        admin_client.table("users")
        .select("id, email, full_name, role, license_number")
        .eq("id", user_id)
        .maybe_single()
        .execute()
    )

    if db_response.data is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no encontrado en el sistema",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return UserProfile(**db_response.data)
