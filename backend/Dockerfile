# ============================================
# Stage 1: Build - Compilar o código TypeScript
# ============================================
FROM node:16 AS build-deps

RUN apt-get update && apt-get install -y wget

ENV DOCKERIZE_VERSION=v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

WORKDIR /usr/src/app

# Copiar e instalar dependências
COPY package*.json ./
RUN npm install

# Copiar código e compilar
COPY . .
RUN npm run build

# ============================================
# Stage 2: Runtime - Node.js + Nginx
# ============================================
FROM node:16 AS runtime

# Instalar dependências do sistema
RUN apt-get update \
    && apt-get install -y wget gnupg nginx supervisor \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Instalar dockerize
ENV DOCKERIZE_VERSION=v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Instalar dumb-init
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV NODE_ENV=production
ENV PORT=3000
ENV CHROME_BIN=google-chrome-stable

WORKDIR /usr/src/app

# Copiar código compilado e dependências
COPY --from=build-deps /usr/src/app/dist ./dist
COPY --from=build-deps /usr/src/app/node_modules ./node_modules
COPY --from=build-deps /usr/src/app/package*.json ./
COPY --from=build-deps /usr/local/bin/dockerize /usr/local/bin/dockerize

# Copiar configurações do Nginx
COPY .docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY .docker/nginx/conf.d/ /etc/nginx/conf.d/
COPY .docker/nginx/add-ssl.sh /usr/local/bin/add-ssl.sh
RUN chmod +x /usr/local/bin/add-ssl.sh
COPY .docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Criar diretórios necessários
RUN mkdir -p /var/log/supervisor \
    && mkdir -p /etc/nginx/ssl

# Expor portas
EXPOSE 80 443 3000

# Usar supervisord para gerenciar Node.js e Nginx
ENTRYPOINT ["dumb-init", "--"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
