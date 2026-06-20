#!/bin/bash
# Script de Backup Lógico - Trabalho de Banco de Dados II
# Contexto: Loja Virtual (PostgreSQL via Docker)

# Definir cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0;0m' # No Color

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/backup_lojavirtual_${TIMESTAMP}.sql"
CONTAINER_NAME="db_loja"
DB_USER="postgres"
DB_NAME="lojavirtual"

# Criar a pasta de backups local se não existir
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Criando diretório de backups local em: ${BACKUP_DIR}"
    mkdir -p "$BACKUP_DIR"
fi

echo -e "Iniciando o backup lógico do banco de dados [${DB_NAME}]..."

# Executa o pg_dump no container Docker do Postgres e salva o arquivo no host
# Nota: Usamos o superusuário 'postgres' pois ele possui permissões de leitura completas
# de todas as tabelas, schemas e metadados, o que é ideal para recuperação de desastres.
docker exec -t ${CONTAINER_NAME} pg_dump -U ${DB_USER} -d ${DB_NAME} > "${BACKUP_FILE}"

# Verificar se o comando foi bem-sucedido
if [ $? -eq 0 ] && [ -f "${BACKUP_FILE}" ]; then
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${GREEN}SUCESSO: Backup realizado com sucesso!${NC}"
    echo -e "Arquivo gerado: ${BACKUP_FILE}"
    echo -e "Tamanho do arquivo: $(du -sh ${BACKUP_FILE} | cut -f1)"
    echo -e "${GREEN}===================================================${NC}"
else
    echo -e "${RED}===================================================${NC}"
    echo -e "${RED}ERRO: Falha ao realizar o backup lógico.${NC}"
    echo -e "Certifique-se de que o container '${CONTAINER_NAME}' está rodando."
    echo -e "${RED}===================================================${NC}"
    exit 1
fi
