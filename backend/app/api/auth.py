from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_current_user
from app.core.supabase_client import get_supabase_admin, get_supabase_anon
from app.schemas.auth import AuthResponse, LoginRequest, RegisterRequest, UserProfile

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar nuevo usuario (médico o asistente)",
)
def register(body: RegisterRequest) -> AuthResponse:
    """
    Crea un usuario en Supabase Auth y luego inserta su perfil
    en la tabla `users` con su rol asignado.

    Si algo falla después de crear el usuario en Auth,
    se elimina para evitar usuarios huérfanos.
    """
    anon_client = get_supabase_anon()
    admin_client = get_supabase_admin()

    # 1. Crear usuario en Supabase Auth
    try:
        auth_response = anon_client.auth.sign_up(
            {"email": body.email, "password": body.password}
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al crear cuenta: {str(e)}",
        )

    if auth_response.user is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se pudo crear el usuario. Verificá que el email no esté registrado.",
        )

    auth_user = auth_response.user
    access_token = auth_response.session.access_token if auth_response.session else None

    # 2. Insertar perfil en la tabla `users`
    try:
        db_response = (
            admin_client.table("users")
            .insert(
                {
                    "id": auth_user.id,
                    "email": body.email,
                    "full_name": body.full_name,
                    "role": body.role,
                    "license_number": body.license_number,
                }
            )
            .execute()
        )
    except Exception as e:
        # Rollback: eliminar el usuario de Auth para no dejar un registro huérfano
        try:
            admin_client.auth.admin.delete_user(auth_user.id)
        except Exception:
            pass
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al guardar perfil de usuario: {str(e)}",
        )

    user_data = db_response.data[0]

    if access_token is None:
        raise HTTPException(
            status_code=status.HTTP_201_CREATED,
            detail="Cuenta creada. Revisá tu email para confirmar tu cuenta antes de iniciar sesión.",
        )

    return AuthResponse(
        access_token=access_token,
        user=UserProfile(**user_data),
    )


@router.post(
    "/login",
    response_model=AuthResponse,
    summary="Iniciar sesión",
)
def login(body: LoginRequest) -> AuthResponse:
    """
    Autentica con Supabase Auth usando email y password.
    Retorna el JWT de acceso junto con el perfil completo del usuario
    (incluyendo su rol: doctor o asistente).
    """
    anon_client = get_supabase_anon()
    admin_client = get_supabase_admin()

    # 1. Autenticar con Supabase Auth
    try:
        auth_response = anon_client.auth.sign_in_with_password(
            {"email": body.email, "password": body.password}
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o contraseña incorrectos",
        )

    if auth_response.user is None or auth_response.session is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales inválidas",
        )

    # 2. Obtener perfil completo desde la tabla `users`
    user_id = auth_response.user.id
    db_response = (
        admin_client.table("users")
        .select("id, email, full_name, role, license_number")
        .eq("id", user_id)
        .maybe_single()
        .execute()
    )

    if db_response.data is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Perfil de usuario no encontrado. Contactá al administrador.",
        )

    return AuthResponse(
        access_token=auth_response.session.access_token,
        user=UserProfile(**db_response.data),
    )


@router.get(
    "/me",
    response_model=UserProfile,
    summary="Obtener perfil del usuario autenticado",
)
def me(current_user: UserProfile = Depends(get_current_user)) -> UserProfile:
    """
    Retorna el perfil completo del usuario a partir del JWT en el header.
    Usado por la app Flutter para restaurar la sesión al arrancar.
    """
    return current_user