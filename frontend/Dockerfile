FROM node:18-alpine

WORKDIR /app

# Adicionar dependências para compilar nativamente se necessário
RUN apk add --no-cache python3 make g++

COPY package.json .

# Instalar dependências
RUN npm install --loglevel=error

COPY . .

EXPOSE 3000

# Porta do React dev server
CMD ["npm", "start"]
