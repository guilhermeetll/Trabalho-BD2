#!/bin/bash
# Script de Restauração Automatizada - Trabalho de Banco de Dados II
# Foco: Restaurar backups lógicos individuais (.dump) ou completos do cluster (.sql.gz)

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0;0m'

CONTAINER_NAME="db_loja"
DB_USER="postgres"
DB_NAME="lojavirtual"

# Verificar se foi passado o arquivo de backup
if [ -z "$1" ]; then
    echo -e "${RED}ERRO: Você deve fornecer o caminho do arquivo de backup como parâmetro.${NC}"
    echo -e "Uso: ./restaurar.sh <caminho_do_backup>"
    echo -e "Exemplo: ./restaurar.sh ./backups/backup_lojavirtual_20260620_160000.dump"
    echo -e "Exemplo: ./restaurar.sh ./backups/backup_cluster_20260620_160000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"

# Verificar se o arquivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}ERRO: Arquivo de backup não encontrado em: ${BACKUP_FILE}${NC}"
    exit 1
fi

echo "Iniciando processo de restauração usando o arquivo: ${BACKUP_FILE}..."

# Detectar o tipo de backup com base na extensão do arquivo
if [[ "$BACKUP_FILE" == *.dump ]]; then
    echo "Tipo detectado: Backup Lógico de Banco Individual (.dump)"
    echo "Dropando e recriando o banco de dados [${DB_NAME}] para garantir restauração limpa..."
    
    # Dropar conexões ativas no banco antes do drop
    docker exec -t ${CONTAINER_NAME} psql -U ${DB_USER} -d postgres -c \
        "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '${DB_NAME}' AND pid <> pg_backend_pid();"
        
    docker exec -t ${CONTAINER_NAME} psql -U ${DB_USER} -d postgres -c "DROP DATABASE IF EXISTS ${DB_NAME};"
    docker exec -t ${CONTAINER_NAME} psql -U ${DB_USER} -d postgres -c "CREATE DATABASE ${DB_NAME};"
    
    echo "Copiando arquivo de backup para dentro do container..."
    docker cp "${BACKUP_FILE}" "${CONTAINER_NAME}:/tmp/restore_db.dump"
    
    echo "Executando pg_restore no banco [${DB_NAME}]..."
    docker exec -t ${CONTAINER_NAME} pg_restore -U ${DB_USER} -d ${DB_NAME} /tmp/restore_db.dump
    
    echo "Limpando arquivos temporários no container..."
    docker exec -t ${CONTAINER_NAME} rm /tmp/restore_db.dump
    
elif [[ "$BACKUP_FILE" == *.sql.gz ]]; then
    echo "Tipo detectado: Backup Completo do Cluster com Gzip (.sql.gz)"
    echo "Restaurando o cluster inteiro (incluindo Roles, Usuários e Bancos)..."
    
    echo "Copiando arquivo de backup para dentro do container..."
    docker cp "${BACKUP_FILE}" "${CONTAINER_NAME}:/tmp/restore_db.sql.gz"
    
    echo "Executando restauração do cluster..."
    docker exec -t ${CONTAINER_NAME} sh -c "gunzip -c /tmp/restore_db.sql.gz | psql -U ${DB_USER}"
    
    echo "Limpando arquivos temporários no container..."
    docker exec -t ${CONTAINER_NAME} rm /tmp/restore_db.sql.gz
    
else
    echo -e "${RED}ERRO: Formato de backup não suportado. Use arquivos .dump ou .sql.gz${NC}"
    exit 1
fi


if [ $? -eq 0 ]; then
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${GREEN}SUCESSO: O banco de dados foi restaurado!${NC}"
    echo -e "Por favor, execute o script 'verificacao.sql' para validar a integridade.${NC}"
    echo -e "${GREEN}===================================================${NC}"
else
    echo -e "${RED}===================================================${NC}"
    echo -e "${RED}ERRO: Falha durante o processo de restauração.${NC}"
    echo -e "${RED}===================================================${NC}"
    exit 1
fi
