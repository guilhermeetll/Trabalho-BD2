-- Script SQL de Segurança (security.sql)
-- Trabalho de Banco de Dados II: "Implementação de Estratégias de Segurança e Recuperação"
-- Contexto: Loja Virtual

-- ==========================================
-- 1. CRIAÇÃO DE PAPÉIS (ROLES)
-- ==========================================
DROP ROLE IF EXISTS role_admin;
DROP ROLE IF EXISTS role_funcionario;
DROP ROLE IF EXISTS role_visitante;

CREATE ROLE role_admin;
CREATE ROLE role_funcionario;
CREATE ROLE role_visitante;

-- ==========================================
-- 2. ATRIBUIÇÃO DE PERMISSÕES AOS PAPÉIS (GRANT)
-- ==========================================

-- --- PAPEL: ADMINISTRADOR (Acesso Total) ---
GRANT CONNECT ON DATABASE lojavirtual TO role_admin;
GRANT USAGE ON SCHEMA public TO role_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO role_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO role_admin;
-- Garantir privilégios em tabelas futuras criadas pelo administrador
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO role_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO role_admin;

-- --- PAPEL: FUNCIONÁRIO (SELECT e INSERT nas tabelas operacionais, sem DELETE) ---
GRANT CONNECT ON DATABASE lojavirtual TO role_funcionario;
GRANT USAGE ON SCHEMA public TO role_funcionario;
-- Conceder apenas SELECT e INSERT nas tabelas de negócio operacionais
GRANT SELECT, INSERT ON produtos, pedidos, itens_pedido, categorias TO role_funcionario;
-- Permitir também consultar logs e usuários para rotinas administrativas
GRANT SELECT ON logs_auditoria, usuarios TO role_funcionario;
-- Conceder permissão de uso nas sequências para permitir inserções (geração automática de IDs)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_funcionario;

-- --- PAPEL: VISITANTE (Apenas leitura de produtos e categorias) ---
GRANT CONNECT ON DATABASE lojavirtual TO role_visitante;
GRANT USAGE ON SCHEMA public TO role_visitante;
-- Conceder privilégio de leitura (SELECT) estritamente no catálogo de produtos e categorias
GRANT SELECT ON produtos, categorias TO role_visitante;

-- ==========================================
-- 3. CRIAÇÃO DE USUÁRIOS (USERS com LOGIN)
-- ==========================================
DROP USER IF EXISTS admin_user;
DROP USER IF EXISTS funcionario_user;
DROP USER IF EXISTS visitante_user;

CREATE USER admin_user WITH PASSWORD 'admin_password_secure_2026';
CREATE USER funcionario_user WITH PASSWORD 'funcionario_password_secure_2026';
CREATE USER visitante_user WITH PASSWORD 'visitante_password_secure_2026';

-- ==========================================
-- 4. ASSOCIAÇÃO DE USUÁRIOS AOS SEUS RESPECTIVOS PAPÉIS
-- ==========================================
GRANT role_admin TO admin_user;
GRANT role_funcionario TO funcionario_user;
GRANT role_visitante TO visitante_user;

-- Habilitar herança de privilégios explicitamente para os usuários
ALTER ROLE admin_user INHERIT;
ALTER ROLE funcionario_user INHERIT;
ALTER ROLE visitante_user INHERIT;

-- ==========================================
-- 5. DEMONSTRAÇÃO DO COMANDO REVOKE (Endurecimento de Segurança)
-- ==========================================

-- Prática Recomendada de Endurecimento (Hardening):
-- Por padrão, o PostgreSQL permite que a role especial 'public' crie objetos no schema public.
-- Revogamos esse direito de criação para todos os usuários comuns, garantindo que apenas superusuários
-- ou a role admin possam criar/alterar tabelas no banco de dados.
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Simulação de Revogação de Acesso Temporário:
-- Concede permissão de SELECT na tabela 'usuarios' ao visitante, simulando liberação temporária.
GRANT SELECT ON usuarios TO role_visitante;
-- Revoga o privilégio concedido anteriormente para demonstrar o comando REVOKE.
REVOKE SELECT ON usuarios FROM role_visitante;
