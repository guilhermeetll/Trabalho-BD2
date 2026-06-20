# Roteiro de Testes de Segurança de Banco de Dados — Loja Virtual

Este roteiro descreve a execução dos testes práticos para validação das diretrizes de controle de acesso (Roles e Privilégios) implementadas no PostgreSQL, demonstrando a correta aplicação de restrições de segurança do projeto.

---

## 1. Como Conectar com Cada Usuário via Docker

Para fins de demonstração, os testes a seguir utilizam o utilitário `psql` rodando de dentro do container Docker `db_loja`. O comando base para abrir a linha de comando interativa do Postgres com um usuário específico é:

```bash
docker compose exec db psql -U <USUARIO> -d lojavirtual
```

Substitua `<USUARIO>` por `admin_user`, `funcionario_user` ou `visitante_user`.

---

## 2. Casos de Teste Operacionais

### CASO 1: Tentativa de Acesso Autorizado (Funcionário)
* **Objetivo**: Demonstrar que o `funcionario_user` possui permissões de escrita (`INSERT`) em tabelas operacionais.
* **Ação**: Inserir um novo produto no catálogo.

1. **Conexão**:
   ```bash
   docker compose exec db psql -U funcionario_user -d lojavirtual
   ```

2. **Comando SQL**:
   ```sql
   INSERT INTO produtos (categoria_id, nome, descricao, preco, estoque) 
   VALUES (1, 'Teclado Mecânico RGB', 'Teclado Mecânico Gamer Switch Blue.', 299.90, 30);
   ```

3. **Resultado Esperado**:
   ```text
   INSERT 0 1
   ```
   *O registro é inserido com sucesso porque a `role_funcionario` herdada pelo usuário possui privilégios de `INSERT` na tabela `produtos`.*

---

### CASO 2: Tentativa de Acesso Negado por Leitura Indevida (Visitante)
* **Objetivo**: Demonstrar que o `visitante_user` não possui permissão para ler tabelas confidenciais de clientes (`usuarios`) ou vendas (`pedidos`).
* **Ação**: Executar um `SELECT` na tabela de `usuarios`.

1. **Conexão**:
   ```bash
   docker compose exec db psql -U visitante_user -d lojavirtual
   ```

2. **Comando SQL**:
   ```sql
   SELECT * FROM usuarios;
   ```

3. **Resultado Esperado / Retorno do Banco**:
   ```text
   ERROR:  permission denied for table usuarios
   ```
   *O PostgreSQL bloqueia a execução e retorna o erro de permissão negada, pois a `role_visitante` não possui o privilégio `SELECT` sobre a tabela de usuários.*

---

### CASO 3: Restrição de Operações Indevidas (Funcionário)
* **Objetivo**: Garantir que o `funcionario_user` não pode excluir registros do catálogo (`DELETE`), mitigando riscos de perda de dados.
* **Ação**: Tentar remover um produto cadastrado.

1. **Conexão**:
   ```bash
   docker compose exec db psql -U funcionario_user -d lojavirtual
   ```

2. **Comando SQL**:
   ```sql
   DELETE FROM produtos WHERE id = 1;
   ```

3. **Resultado Esperado / Retorno do Banco**:
   ```text
   ERROR:  permission denied for table produtos
   ```
   *Embora o funcionário consiga consultar (`SELECT`) e cadastrar (`INSERT`) produtos, o privilégio de exclusão (`DELETE`) não foi concedido a ele no script de segurança. O banco nega a operação automaticamente.*

---

### CASO 4: Acesso Total e Operações DDL (Administrador)
* **Objetivo**: Demonstrar que o `admin_user` possui permissão irrestrita nas tabelas para auditoria e manutenção de dados.
* **Ação**: Excluir um produto e realizar consultas completas.

1. **Conexão**:
   ```bash
   docker compose exec db psql -U admin_user -d lojavirtual
   ```

2. **Comandos SQL (Sequência)**:
   ```sql
   -- 1. Excluir o produto inserido no caso 1
   DELETE FROM produtos WHERE nome = 'Teclado Mecânico RGB';
   
   -- 2. Consultar os logs de auditoria gerados pelas triggers
   SELECT id, evento, tabela_afetada, data_evento FROM logs_auditoria ORDER BY data_evento DESC LIMIT 3;
   ```

3. **Resultado Esperado**:
   ```text
   DELETE 1
   
    id | evento | tabela_afetada |        data_evento         
   ----+--------+----------------+----------------------------
     8 | DELETE | produtos       | 2026-06-20 16:15:00.123456
     7 | UPDATE | produtos       | 2026-06-20 16:10:00.654321
   ```
   *O administrador consegue excluir registros livremente. A trigger de auditoria funciona perfeitamente por trás, gravando o evento de DELETE do produto.*

---

## 3. Resumo da Matriz de Controle de Acesso (RBAC)

Para compor seu relatório escrito, a tabela abaixo resume a política de permissões estabelecida no script `security.sql`:

| Tabela | visitante_user (Visitante) | funcionario_user (Funcionário) | admin_user (Administrador) |
| :--- | :---: | :---: | :---: |
| **`produtos`** | `SELECT` | `SELECT` / `INSERT` | `ALL PRIVILEGES` |
| **`categorias`** | `SELECT` | `SELECT` / `INSERT` | `ALL PRIVILEGES` |
| **`pedidos`** | Nenhum | `SELECT` / `INSERT` | `ALL PRIVILEGES` |
| **`itens_pedido`**| Nenhum | `SELECT` / `INSERT` | `ALL PRIVILEGES` |
| **`usuarios`** | Nenhum | `SELECT` | `ALL PRIVILEGES` |
| **`logs_auditoria`**| Nenhum | `SELECT` | `ALL PRIVILEGES` |
