-- Queries de Verificação de Integridade Pós-Recuperação (verificacao.sql)
-- Trabalho de Banco de Dados II: "Implementação de Estratégias de Segurança e Recuperação"
-- Foco: Auditoria e validação de consistência dos dados restaurados

-- =====================================================================
-- 1. CHECAGEM DE TABELAS EXISTENTES
-- =====================================================================
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- =====================================================================
-- 2. CHECAGEM DA QUANTIDADE DE REGISTROS (DADOS ORIGINAIS RESTAURADOS)
-- =====================================================================
SELECT 'categorias' AS tabela, COUNT(*) AS total_registros FROM categorias
UNION ALL
SELECT 'produtos', COUNT(*) FROM produtos
UNION ALL
SELECT 'usuarios', COUNT(*) FROM usuarios
UNION ALL
SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL
SELECT 'itens_pedido', COUNT(*) FROM itens_pedido
UNION ALL
SELECT 'logs_auditoria', COUNT(*) FROM logs_auditoria;

-- =====================================================================
-- 3. VERIFICAÇÃO SE OS ÍNDICES E CHAVES ESTRANGEIRAS ESTÃO ATIVOS
-- =====================================================================
-- Verifica se as chaves estrangeiras estão presentes no schema
SELECT 
    tc.table_name AS tabela_origem, 
    kcu.column_name AS coluna_fk, 
    ccu.table_name AS tabela_destino,
    ccu.column_name AS coluna_pk
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
ORDER BY tabela_origem;

-- =====================================================================
-- 4. VERIFICAÇÃO DO TRIGGER DE AUDITORIA
-- =====================================================================
-- Garante que o trigger de logs de produtos voltou ativo e configurado
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement
FROM 
    information_schema.triggers
WHERE 
    event_object_table = 'produtos';

-- =====================================================================
-- 5. VERIFICAÇÃO DAS ROLES E USUÁRIOS (INTEGRIDADE DO CONTROLE DE ACESSO)
-- =====================================================================
SELECT 
    rolname AS nome_papel, 
    rolsuper AS eh_superusuario, 
    rolinherit AS herda_permissoes, 
    rolcanlogin AS pode_logar
FROM 
    pg_roles 
WHERE 
    rolname IN (
        'role_admin', 'role_funcionario', 'role_visitante', 
        'admin_user', 'funcionario_user', 'visitante_user'
    )
ORDER BY pode_logar DESC, nome_papel;
