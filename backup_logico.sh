#!/bin/bash
# Script de Backup Lógico Individual - Trabalho de Banco de Dados II
# Foco: Backup apenas da base 'lojavirtual' em formato customizado comprimido (.dump)

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0;0m'

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/backup_lojavirtual_${TIMESTAMP}.dump"
CONTAINER_NAME="db_loja"
DB_USER="postgres"
DB_NAME="lojavirtual"

# Garantir diretório de backups
mkdir -p "$BACKUP_DIR"

echo "Iniciando backup lógico da base [${DB_NAME}] em formato comprimido (-Fc)..."

# 1. Executa pg_dump dentro do container salvando em arquivo temporário (evita corrupção por redirection no Windows)
docker exec -t ${CONTAINER_NAME} pg_dump -U ${DB_USER} -d ${DB_NAME} -F c -f /tmp/backup.dump

# 2. Copia o arquivo binário do container para o host de forma íntegra
docker cp "${CONTAINER_NAME}:/tmp/backup.dump" "${BACKUP_FILE}"

# 3. Limpa o arquivo temporário no container
docker exec -t ${CONTAINER_NAME} rm /tmp/backup.dump

if [ $? -eq 0 ] && [ -f "${BACKUP_FILE}" ]; then
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${GREEN}SUCESSO: Backup lógico individual concluído!${NC}"
    echo -e "Arquivo gerado: ${BACKUP_FILE}"
    echo -e "Tamanho: $(du -sh ${BACKUP_FILE} | cut -f1)"
    echo -e "${GREEN}===================================================${NC}"
else
    echo -e "${RED}===================================================${NC}"
    echo -e "${RED}ERRO: Falha ao gerar o backup lógico com pg_dump.${NC}"
    echo -e "${RED}===================================================${NC}"
    exit 1
fi
