# Stage 1: Build com Node.js
FROM node:18-alpine AS build-deps

WORKDIR /usr/src/app

# Copiar arquivos de dependências
COPY package*.json ./

# Instalar dependências
# Usar npm install ao invés de npm ci pois não há package-lock.json
RUN npm install

# Copiar arquivos de configuração e código fonte
COPY .env* ./
COPY vite.config.js ./
COPY index.html ./
COPY src/ ./src/
COPY public/ ./public/

# Build da aplicação
RUN npm run build

# Stage 2: Servir com Nginx
FROM nginx:alpine

# Instalar dependências necessárias
RUN apk add --no-cache jq openssl curl

# Instalar dockerize para aguardar serviços
ENV DOCKERIZE_VERSION=v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-alpine-linux-amd64-${DOCKERIZE_VERSION}.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-${DOCKERIZE_VERSION}.tar.gz \
    && rm dockerize-alpine-linux-amd64-${DOCKERIZE_VERSION}.tar.gz

# Variável de ambiente para o diretório público
ENV PUBLIC_HTML=/var/www/public/

# Copiar configurações do Nginx
COPY .docker/nginx /etc/nginx/

# Copiar arquivos buildados do stage anterior
COPY --from=build-deps /usr/src/app/build ${PUBLIC_HTML}

# Expor porta 80
EXPOSE 80

# Copiar e configurar script de variáveis de ambiente
COPY .docker/add-env-vars.sh /docker-entrypoint.d/01-add-env-vars.sh
RUN chmod +x /docker-entrypoint.d/01-add-env-vars.sh

# Comando padrão do Nginx (já inclui o entrypoint que executa scripts em /docker-entrypoint.d/)
CMD ["nginx", "-g", "daemon off;"]