# ============================================
# WhaTicket - Dockerfile Multi-Stage Build
# ============================================
# Este Dockerfile constrói tanto o backend quanto o frontend
# Para uso com docker-compose, os Dockerfiles individuais são preferidos
# Use este Dockerfile apenas se quiser construir tudo em uma única imagem
# ============================================

# ============================================
# Stage 1: Build Backend
# ============================================
FROM node:14 as backend-builder

RUN apt-get update && apt-get install -y wget

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

WORKDIR /usr/src/app/backend

# Copiar e instalar dependências do backend
COPY backend/package*.json ./
RUN npm install

# Copiar código do backend e compilar
COPY backend/ ./
RUN npm run build

# ============================================
# Stage 2: Build Frontend
# ============================================
FROM node:14-alpine as frontend-builder

WORKDIR /usr/src/app/frontend

# Copiar e instalar dependências do frontend
COPY frontend/package*.json ./
RUN npm install

# Copiar código do frontend e compilar
COPY frontend/.env* ./
COPY frontend/src/ ./src/
COPY frontend/public/ ./public/
COPY frontend/index.html ./
COPY frontend/vite.config.js ./
RUN npm run build

# ============================================
# Stage 3: Runtime - Backend
# ============================================
FROM node:14 as backend-runtime

RUN apt-get update && apt-get install -y wget gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV NODE_ENV=production
ENV PORT=3000
ENV CHROME_BIN=google-chrome-stable

WORKDIR /usr/src/app

# Copiar dependências e código compilado do backend
COPY --from=backend-builder /usr/src/app/backend/node_modules ./node_modules
COPY --from=backend-builder /usr/src/app/backend/dist ./dist
COPY --from=backend-builder /usr/src/app/backend/package*.json ./
COPY --from=backend-builder /usr/local/bin/dockerize /usr/local/bin/dockerize

EXPOSE 3000

ENTRYPOINT ["dumb-init", "--"]
CMD dockerize -wait tcp://${DB_HOST}:3306 \
  && npx sequelize db:migrate \
  && node dist/server.js

# ============================================
# Stage 4: Runtime - Frontend (Nginx)
# ============================================
FROM nginx:alpine as frontend-runtime

RUN apk add --no-cache jq openssl

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

ENV PUBLIC_HTML=/var/www/public/

# Copiar configurações do nginx
COPY frontend/.docker/nginx /etc/nginx/

# Copiar build do frontend
COPY --from=frontend-builder /usr/src/app/frontend/build ${PUBLIC_HTML}

# Copiar script de inicialização
COPY frontend/.docker/add-env-vars.sh /docker-entrypoint.d/01-add-env-vars.sh
RUN chmod +x /docker-entrypoint.d/01-add-env-vars.sh

EXPOSE 80 443

# ============================================
# NOTA: Este Dockerfile é uma alternativa
# O docker-compose.yaml usa os Dockerfiles individuais
# que são mais eficientes para desenvolvimento
# ============================================

