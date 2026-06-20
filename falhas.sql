-- Script de Simulação de Falhas (falhas.sql)
-- Trabalho de Banco de Dados II: "Implementação de Estratégias de Segurança e Recuperação"
-- Foco: Testes de desastres (Erro humano e Perda de Banco)

-- ATENÇÃO: ESTE SCRIPT SIMULA DESASTRES GRAVES. EXECUTE APENAS APÓS CONFIRMAR OS BACKUPS!

-- =====================================================================
-- CENÁRIO 1: EXCLUSÃO ACIDENTAL DE DADOS (ERRO HUMANO)
-- =====================================================================
-- Simulação de um desenvolvedor ou admin executando um delete sem a cláusula WHERE
-- ou dropando uma tabela crítica operacional.

-- Opção A: Excluir todos os produtos (deleta também logs e itens relacionados devido ao CASCADE em itens e triggers)
-- DELETE FROM produtos;

-- Opção B: Exclusão total da tabela de pedidos (Drop Table)
-- DROP TABLE pedidos CASCADE;


-- =====================================================================
-- CENÁRIO 2: FALHA PROPOSITAL/DESTRUIÇÃO TOTAL DO BANCO
-- =====================================================================
-- Simulação de exclusão física ou corrupção lógica total do banco de dados da Loja.
-- Nota: Para dropar 'lojavirtual', é preciso estar conectado a outro banco de dados (ex: 'postgres').

-- Conecte ao banco 'postgres' no psql:
-- \c postgres

-- Comando para deletar o banco de dados inteiro:
-- DROP DATABASE lojavirtual;
