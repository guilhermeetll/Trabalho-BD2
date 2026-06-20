from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from fastapi import Header, HTTPException
import os
import time

Base = declarative_base()

# Cache de engines do SQLAlchemy por Role do banco de dados
engines_cache = {}

def get_engine_for_role(role: str = "loja_app"):
    """Retorna uma engine do SQLAlchemy configurada com o usuário do Postgres solicitado."""
    if role in engines_cache:
        return engines_cache[role]
        
    db_name = os.getenv("POSTGRES_DB", "lojavirtual")
    
    # Mapeamento dinâmico das credenciais das Roles
    if role == "postgres":
        user = os.getenv("POSTGRES_USER", "postgres")
        password = os.getenv("POSTGRES_PASSWORD", "postgres_super_secure_pass_987")
    elif role == "funcionario_user":
        user = "funcionario_user"
        password = "funcionario_password_secure_2026"
    elif role == "visitante_user":
        user = "visitante_user"
        password = "visitante_password_secure_2026"
    else: # loja_app (padrão)
        user = os.getenv("LOJA_APP_USER", "loja_app")
        password = os.getenv("LOJA_APP_PASSWORD", "loja_app_password123")
        
    url = f"postgresql://{user}:{password}@db:5432/{db_name}"
    
    try:
        new_engine = create_engine(url)
        # Teste rápido de conexão
        with new_engine.connect() as conn:
            pass
        engines_cache[role] = new_engine
        return new_engine
    except Exception as e:
        print(f"Erro ao conectar ao banco com a role '{role}': {str(e)}")
        raise e

def get_db(x_db_role: str = Header("loja_app")):
    """Injeção de dependência do FastAPI para obter conexões dinâmicas baseadas no header HTTP X-DB-Role."""
    try:
        engine = get_engine_for_role(x_db_role)
    except Exception as e:
        raise HTTPException(
            status_code=403,
            detail=f"Erro de autenticação de banco de dados para a Role '{x_db_role}': {str(e)}"
        )
        
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
