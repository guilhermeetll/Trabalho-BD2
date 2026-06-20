# Relatório de Estratégias de Recuperação de Desastres — Loja Virtual

**Disciplina**: Banco de Dados II  
**Tema**: Implementação de Estratégias de Segurança e Recuperação (Disaster Recovery)  

---

## 1. Introdução

Em sistemas de comércio eletrônico (e-commerce), a disponibilidade contínua dos dados e a capacidade de se recuperar rapidamente de falhas (sejam elas de infraestrutura ou erros humanos) são vitais para a saúde financeira da empresa. Este relatório apresenta a fundamentação teórica e o roteiro de execução prática para **Backup Lógico, Simulação de Falhas Críticas, Restauração Automatizada e Auditoria de Integridade** utilizando containers Docker e o PostgreSQL 16.

---

## 2. Estratégias de Backup Implementadas

Para garantir a segurança dos dados em múltiplos níveis, desenvolvemos dois scripts de backup automatizados:

### A. Backup Lógico Individual (`backup_logico.sh`)
* **Ferramenta**: `pg_dump`
* **Format**: Customizado Binário Comprimido do Postgres (`-Fc`)
* **Objetivo**: Efetuar o backup completo apenas do banco de dados operacional `lojavirtual`. O formato customizado binário é ideal para restaurações finas e rápidas através do utilitário `pg_restore`.
* **Como Executar**:
  ```bash
  bash backup_logico.sh
  ```

### B. Backup Completo do Cluster (`backup_completo.sh`)
* **Ferramenta**: `pg_dumpall`
* **Formato**: SQL Plain Text compactado via `gzip` (`.sql.gz`)
* **Objetivo**: Fazer a cópia de segurança de todo o servidor (cluster) PostgreSQL. Isso é crucial porque o `pg_dump` individual não salva dados globais como as **Roles de segurança** (`role_admin`, `role_funcionario`) e os **usuários** criados na etapa anterior. O `pg_dumpall` garante a integridade do modelo de controle de acesso (RBAC).
* **Como Executar**:
  ```bash
  bash backup_completo.sh
  ```

---

## 3. Simulação de Desastres (`falhas.sql`)

Para provar a eficiência da nossa estratégia de recuperação, simulamos dois cenários de desastre na base de dados:

### Cenário 1: Erro Humano (Exclusão Acidental)
Simula um operador executando um comando de exclusão em massa sem filtro `WHERE`, ou removendo uma tabela crítica:
```sql
-- Remove todos os produtos cadastrados da loja
DELETE FROM produtos;
```
*Impacto*: Zera a tabela de produtos. Devido à integridade referencial, itens de pedidos relacionados ou logs históricos podem ser afetados.

### Cenário 2: Perda Total de Banco (Corrupção de Dados)
Simula a perda total do banco por invasão, falha de hardware ou deleção maliciosa:
```sql
-- Deleta o banco de dados inteiro da aplicação
DROP DATABASE lojavirtual;
```
*Impacto*: A aplicação perde completamente a comunicação e para de funcionar de forma catastrófica (banco offline).

---

## 4. Estratégia de Restauração Automatizada (`restaurar.sh`)

Criamos o script utilitário inteligente [restaurar.sh](file:///c:/Users/guilherme.travaglia_/Documents/UFES/Trabalho-BD2/restaurar.sh) que identifica dinamicamente o formato do arquivo e aplica o procedimento adequado:

1. **Restauração de Arquivos `.dump`**:
   - Conecta ao banco administrativo `postgres`.
   - Derruba qualquer conexão pendente da aplicação com o banco `lojavirtual` para evitar erros de bloqueio.
   - Executa `DROP DATABASE` seguido de `CREATE DATABASE`.
   - Executa o utilitário `pg_restore` para reconstruir o banco.
2. **Restauração de Arquivos `.sql.gz`**:
   - Descompacta o arquivo em tempo real usando `gunzip`.
   - Injeta o script SQL inteiro diretamente no interpretador do cluster (`psql`), recriando todas as bases, roles, privilégios e dados.

*Como Executar*:
```bash
# Para restaurar banco individual
bash restaurar.sh ./backups/backup_lojavirtual_XXXXXX.dump

# Para restaurar o cluster inteiro (incluindo Roles e senhas de usuários)
bash restaurar.sh ./backups/backup_cluster_XXXXXX.sql.gz
```

---

## 5. Roteiro Passo a Passo de Execução e Teste de Desastre

Siga a sequência abaixo no terminal para demonstrar a recuperação de desastres do zero:

### Passo 1: Gerar os Backups
Gere os backups de segurança antes de simular a falha.
```bash
bash backup_completo.sh
```
*Saída Esperada*:
> `SUCESSO: Backup completo do cluster concluído! Arquivo gerado: ./backups/backup_cluster_20260620_160000.sql.gz`

### Passo 2: Simular o Desastre (Deletar o Banco)
Acesse o banco de dados como administrador e remova a base principal `lojavirtual`:
```bash
docker compose exec db psql -U postgres -d postgres -c "DROP DATABASE lojavirtual;"
```
*Verificação de Falha*:
Tente abrir a página web do frontend ou consultar o backend `/produtos`. A API retornará erro 500 informando que o banco de dados não está disponível (Banco Offline).

### Passo 3: Executar a Restauração
Restaure as informações a partir do último backup do cluster:
```bash
# Substitua o nome do arquivo gerado no Passo 1
bash restaurar.sh ./backups/backup_cluster_20260620_160000.sql.gz
```
*Saída Esperada*:
> `SUCESSO: O banco de dados foi restaurado!`

---

## 6. Verificação de Integridade Pós-Restauração (`verificacao.sql`)

Após a restauração, o script [verificacao.sql](file:///c:/Users/guilherme.travaglia_/Documents/UFES/Trabalho-BD2/verificacao.sql) deve ser executado para auditar o estado do banco.

```bash
docker compose exec db psql -U postgres -d lojavirtual -f /docker-entrypoint-initdb.d/verificacao.sql
```
*(Nota: O arquivo verificacao.sql é mapeado automaticamente para a pasta de inicialização do Docker).*

### Resultados Esperados para Nota Máxima de Validação:

1. **Quantidade de Dados Inalterada**:
   A contagem de registros deve bater exatamente com os dados de semente do script de inserção:
   * 5 categorias, 9 produtos, 5 usuários e 3 pedidos.
2. **Presença das Roles e Permissões**:
   Os papéis `role_admin`, `role_funcionario` e `role_visitante` devem constar como ativos no cluster com suas respectivas restrições herdadas intactas.
3. **Triggers de Auditoria Ativos**:
   O trigger `trg_audit_produtos` deve constar na tabela de produtos, pronto para auditar qualquer nova alteração pós-restauração.
