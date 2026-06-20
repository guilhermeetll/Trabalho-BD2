from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List
from .database import get_db
from . import schemas, crud

app = FastAPI(
    title="E-Commerce Security API - Trabalho BD II",
    description="Backend estruturado com SQLAlchemy conectando via Role restrita (loja_app) e logs por Trigger.",
    version="2.0.0"
)

# Configurar CORS para permitir chamadas do frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {
        "status": "Backend rodando!",
        "seguranca": "Conectado via Role loja_app",
        "endpoints_disponiveis": [
            {"path": "/db-status", "method": "GET", "descricao": "Verifica tabelas e usuário de conexão ativo"},
            {"path": "/produtos", "method": "GET/POST", "descricao": "Catálogo de produtos"},
            {"path": "/pedidos", "method": "GET/POST", "descricao": "Criação e visualização de pedidos"},
            {"path": "/logs", "method": "GET", "descricao": "Logs de auditoria e segurança de banco (Trigger)"}
        ]
    }

@app.get("/db-status")
def db_status(db: Session = Depends(get_db)):
    """Verifica e exibe informações de conexão e privilégios para comprovar o uso da Role restricted."""
    try:
        # Obter o usuário atual da sessão
        user_info = db.execute(text("SELECT current_user, session_user;")).fetchone()
        version_info = db.execute(text("SELECT version();")).fetchone()
        
        # Obter tabelas visíveis
        tables_query = db.execute(text("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)).fetchall()
        tables = [row[0] for row in tables_query]
        
        return {
            "status_conexao": "OK",
            "usuario_banco_atual": user_info[0] if user_info else "desconhecido",
            "usuario_sessao": user_info[1] if user_info else "desconhecido",
            "postgres_version": version_info[0] if version_info else "desconhecido",
            "tabelas_acessiveis": tables
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro de permissão ou conexão com banco de dados: {str(e)}"
        )

# --- CRUD DE PRODUTOS ---
@app.get("/produtos", response_model=List[schemas.ProdutoResponse])
def read_produtos(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_produtos(db, skip=skip, limit=limit)

@app.post("/produtos", response_model=schemas.ProdutoResponse, status_code=status.HTTP_201_CREATED)
def create_produto(produto: schemas.ProdutoCreate, db: Session = Depends(get_db)):
    return crud.create_produto(db=db, produto=produto)

@app.get("/produtos/{produto_id}", response_model=schemas.ProdutoResponse)
def read_produto(produto_id: int, db: Session = Depends(get_db)):
    db_produto = crud.get_produto(db, produto_id=produto_id)
    if db_produto is None:
        raise HTTPException(status_code=404, detail="Produto não encontrado")
    return db_produto

@app.put("/produtos/{produto_id}", response_model=schemas.ProdutoResponse)
def update_produto(produto_id: int, produto: schemas.ProdutoUpdate, db: Session = Depends(get_db)):
    db_produto = crud.update_produto(db, produto_id=produto_id, produto=produto)
    if db_produto is None:
        raise HTTPException(status_code=404, detail="Produto não encontrado")
    return db_produto

@app.delete("/produtos/{produto_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_produto(produto_id: int, db: Session = Depends(get_db)):
    db_produto = crud.delete_produto(db, produto_id=produto_id)
    if db_produto is None:
        raise HTTPException(status_code=404, detail="Produto não encontrado")
    return None

# --- CRUD DE PEDIDOS ---
@app.get("/pedidos", response_model=List[schemas.PedidoResponse])
def read_pedidos(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_pedidos(db, skip=skip, limit=limit)

@app.post("/pedidos", response_model=schemas.PedidoResponse, status_code=status.HTTP_201_CREATED)
def create_pedido(pedido: schemas.PedidoCreate, db: Session = Depends(get_db)):
    return crud.create_pedido(db=db, pedido_data=pedido)

@app.get("/pedidos/{pedido_id}", response_model=schemas.PedidoResponse)
def read_pedido(pedido_id: int, db: Session = Depends(get_db)):
    db_pedido = crud.get_pedido(db, pedido_id=pedido_id)
    if db_pedido is None:
        raise HTTPException(status_code=404, detail="Pedido não encontrado")
    return db_pedido

# --- LOGS DE AUDITORIA DE SEGURANÇA ---
@app.get("/logs", response_model=List[schemas.LogAuditoriaResponse])
def read_logs(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_logs_auditoria(db, skip=skip, limit=limit)
