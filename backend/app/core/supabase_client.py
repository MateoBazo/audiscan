from supabase import create_client, Client
from app.core.config import settings


# Cliente con anon key — usado para operaciones de auth (sign_up, sign_in)
def get_supabase_anon() -> Client:
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_ANON_KEY)


# Cliente con service_role key — usado para operaciones DB que necesitan bypass RLS
# NUNCA exponer esta key al cliente
def get_supabase_admin() -> Client:
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
