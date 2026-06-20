-- Script DDL de Criação do Banco de Dados (schema.sql)
-- Trabalho de Banco de Dados II: "Implementação de Estratégias de Segurança e Recuperação"
-- Contexto: Loja Virtual

-- 1. CRIAR ROLE DE APLICAÇÃO COM ACESSO RESTRITO
-- Remove a role se ela já existir para evitar erro de re-inicialização
DROP ROLE IF EXISTS loja_app;
CREATE ROLE loja_app WITH LOGIN PASSWORD 'loja_app_password123';

-- 2. TABELA DE CATEGORIAS
CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) UNIQUE NOT NULL,
    descricao TEXT,
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. TABELA DE PRODUTOS
CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    categoria_id INTEGER,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10,2) NOT NULL,
    estoque INTEGER NOT NULL,
    data_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Restrições de Integridade
    CONSTRAINT fk_categoria FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL,
    CONSTRAINT chk_preco CHECK (preco > 0),       -- Preço sempre maior que zero
    CONSTRAINT chk_estoque CHECK (estoque >= 0)     -- Estoque maior ou igual a zero (pode ser zerado se esgotar)
);

-- 4. TABELA DE USUÁRIOS
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,              -- Armazenamento seguro de hash de senha
    funcao VARCHAR(50) NOT NULL DEFAULT 'cliente',
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Restrições de Integridade e RBAC (Role-Based Access Control)
    CONSTRAINT chk_funcao CHECK (funcao IN ('cliente', 'administrador', 'suporte'))
);

-- 5. TABELA DE PEDIDOS
CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL,
    data_pedido TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL DEFAULT 'pendente',
    total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    
    -- Restrição de Integridade: ON DELETE RESTRICT (Impede a exclusão de usuários com compras ativas, mantendo histórico de auditoria)
    CONSTRAINT fk_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    CONSTRAINT chk_status CHECK (status IN ('pendente', 'pago', 'enviado', 'entregue', 'cancelado')),
    CONSTRAINT chk_total CHECK (total >= 0)
);

-- 6. TABELA DE ITENS DO PEDIDO
CREATE TABLE itens_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id INTEGER NOT NULL,
    produto_id INTEGER NOT NULL,
    quantidade INTEGER NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    
    -- Restrições de Integridade
    CONSTRAINT fk_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    CONSTRAINT fk_produto FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE RESTRICT,
    CONSTRAINT chk_quantidade CHECK (quantidade > 0),             -- Quantidade vendida deve ser maior que zero
    CONSTRAINT chk_preco_unitario CHECK (preco_unitario > 0),     -- Preço unitário da venda deve ser maior que zero
    CONSTRAINT uq_pedido_produto UNIQUE (pedido_id, produto_id)
);

-- 7. TABELA DE LOGS DE AUDITORIA (Tema: Segurança)
CREATE TABLE logs_auditoria (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER,
    evento VARCHAR(100) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE', etc.
    tabela_afetada VARCHAR(50) NOT NULL,
    dados_antigos JSONB,
    dados_novos JSONB,
    detalhes TEXT,
    ip_origem VARCHAR(45),
    data_evento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Restrições de Integridade
    CONSTRAINT fk_usuario_log FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- 8. CRIAÇÃO DE ÍNDICES PARA OTIMIZAÇÃO (Segurança e Performance)
CREATE UNIQUE INDEX idx_usuarios_email ON usuarios(email); -- Unicidade e busca rápida por e-mail no login
CREATE INDEX idx_produtos_categoria ON produtos(categoria_id);
CREATE INDEX idx_pedidos_usuario ON pedidos(usuario_id);
CREATE INDEX idx_itens_pedido_pedido ON itens_pedido(pedido_id);
CREATE INDEX idx_logs_evento ON logs_auditoria(evento);

-- 9. TRIGGER DE AUDITORIA DE ALTERAÇÃO/EXCLUSÃO EM PRODUTOS (JSONB)
CREATE OR REPLACE FUNCTION audit_produtos_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO logs_auditoria (evento, tabela_afetada, dados_antigos, dados_novos)
        VALUES ('UPDATE', 'produtos', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO logs_auditoria (evento, tabela_afetada, dados_antigos, dados_novos)
        VALUES ('DELETE', 'produtos', to_jsonb(OLD), NULL);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_produtos
AFTER UPDATE OR DELETE ON produtos
FOR EACH ROW
EXECUTE FUNCTION audit_produtos_trigger();

-- 10. CONCEDER PRIVILÉGIOS À ROLE RESTRIÇÃO (loja_app)
-- Conceder permissão de conexão
GRANT CONNECT ON DATABASE lojavirtual TO loja_app;

-- Conceder uso do schema public
GRANT USAGE ON SCHEMA public TO loja_app;

-- Conceder privilégios de DML em todas as tabelas públicas
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO loja_app;

-- Conceder privilégios de uso de sequências (necessário para insert com auto-incremento de ID)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO loja_app;

-- Garantir privilégios para tabelas e sequências futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO loja_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO loja_app;
