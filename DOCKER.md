# 🐳 Guia de Uso do Docker - WhaTicket

Este guia explica como executar o WhaTicket usando Docker Compose, permitindo rodar frontend, backend e banco de dados MySQL simultaneamente em um único repositório.

## 📋 Pré-requisitos

- Docker instalado
- Docker Compose instalado

## 🚀 Início Rápido

### 1. Configurar Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:

```bash
# MySQL
MYSQL_ENGINE=mariadb
MYSQL_VERSION=11
MYSQL_ROOT_PASSWORD=strongpassword          # ⚠️ ALTERE ESTA SENHA!
MYSQL_DATABASE=whaticket
MYSQL_PORT=3306
TZ=America/Fortaleza

# Backend
BACKEND_PORT=8080
BACKEND_URL=http://localhost
PROXY_PORT=8080
JWT_SECRET=3123123213123                    # ⚠️ ALTERE ESTE VALOR!
JWT_REFRESH_SECRET=75756756756              # ⚠️ ALTERE ESTE VALOR!

# Frontend
FRONTEND_PORT=3000
FRONTEND_SSL_PORT=3001
FRONTEND_URL=http://localhost:3000
```

### 2. Construir e Iniciar os Containers

```bash
# Construir e iniciar todos os serviços
docker-compose up -d --build
```

### 3. Executar Migrações e Seeds do Banco de Dados

Na primeira execução, é necessário popular o banco de dados:

```bash
# Executar migrations e seeds
docker-compose exec backend npx sequelize db:seed:all
```

### 4. Acessar a Aplicação

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **MySQL**: localhost:3306

### 5. Criar Usuário Inicial

Acesse http://localhost:3000/signup e crie seu primeiro usuário.

## 📁 Estrutura dos Dockerfiles

O projeto possui Dockerfiles em diferentes locais:

- **`backend/Dockerfile`**: Dockerfile específico para o backend
- **`frontend/Dockerfile`**: Dockerfile específico para o frontend  
- **`Dockerfile`** (raiz): Dockerfile multi-stage alternativo (não usado pelo docker-compose)

O `docker-compose.yaml` usa os Dockerfiles individuais (`backend/Dockerfile` e `frontend/Dockerfile`), que são mais eficientes para desenvolvimento e permitem builds paralelos.

## 📁 Estrutura dos Serviços

O `docker-compose.yaml` configura três serviços principais:

### 🗄️ MySQL
- **Imagem**: MariaDB 10.6 (ou MySQL conforme configurado)
- **Porta**: 3306 (configurável via `MYSQL_PORT`)
- **Volume**: `.docker/data/` (persistência dos dados)

### ⚙️ Backend
- **Porta**: 8080 (configurável via `BACKEND_PORT`)
- **Dependências**: Aguarda MySQL estar pronto
- **Volumes**:
  - `./backend/public/` - Arquivos públicos
  - `./backend/.wwebjs_auth/` - Autenticação WhatsApp Web.js

### 🎨 Frontend
- **Porta HTTP**: 3000 (configurável via `FRONTEND_PORT`)
- **Porta HTTPS**: 3001 (configurável via `FRONTEND_SSL_PORT`)
- **Dependências**: Aguarda Backend estar pronto
- **Volumes**:
  - `./ssl/certs/` - Certificados SSL (opcional)
  - `./ssl/www/` - Arquivos para Let's Encrypt (opcional)

## 🔧 Comandos Úteis

### Ver logs dos serviços
```bash
# Todos os serviços
docker-compose logs -f

# Apenas backend
docker-compose logs -f backend

# Apenas frontend
docker-compose logs -f frontend

# Apenas MySQL
docker-compose logs -f mysql
```

### Parar os serviços
```bash
docker-compose down
```

### Parar e remover volumes (⚠️ apaga dados do banco)
```bash
docker-compose down -v
```

### Reconstruir um serviço específico
```bash
# Reconstruir apenas o backend
docker-compose up -d --build backend

# Reconstruir apenas o frontend
docker-compose up -d --build frontend
```

### Executar comandos dentro dos containers
```bash
# Executar comando no backend
docker-compose exec backend <comando>

# Exemplo: executar migrations
docker-compose exec backend npx sequelize db:migrate

# Executar comando no MySQL
docker-compose exec mysql mysql -u root -p
```

### Ver status dos containers
```bash
docker-compose ps
```

## 🔒 Configuração SSL (Produção)

Para usar SSL em produção:

1. Gere os certificados usando Certbot:
```bash
# Backend
certbot certonly --cert-name backend --webroot --webroot-path ./ssl/www/ -d api.mydomain.com

# Frontend
certbot certonly --cert-name frontend --webroot --webroot-path ./ssl/www/ -d myapp.mydomain.com
```

2. Coloque os certificados na estrutura:
```
ssl/
├── certs/
│   ├── backend/
│   │   ├── fullchain.pem
│   │   └── privkey.pem
│   └── frontend/
│       ├── fullchain.pem
│       └── privkey.pem
└── www/
```

3. Configure as variáveis no `.env`:
```bash
BACKEND_URL=https://api.mydomain.com
FRONTEND_URL=https://myapp.mydomain.com
PROXY_PORT=443
FRONTEND_PORT=80
FRONTEND_SSL_PORT=443
BACKEND_SERVER_NAME=api.mydomain.com
FRONTEND_SERVER_NAME=myapp.mydomain.com
```

## 🐛 Solução de Problemas

### Backend não conecta ao MySQL
- Verifique se o MySQL está rodando: `docker-compose ps`
- Verifique os logs: `docker-compose logs mysql`
- Confirme que as variáveis `DB_HOST`, `DB_USER`, `DB_PASS` e `DB_NAME` estão corretas

### Frontend não conecta ao Backend
- Verifique se o backend está rodando: `docker-compose ps`
- Verifique a variável `REACT_APP_BACKEND_URL` no frontend
- Confirme que ambos estão na mesma rede Docker (`whaticket`)

### Erro de permissões
- No Windows, certifique-se de que o Docker Desktop está rodando
- No Linux, você pode precisar usar `sudo` ou adicionar seu usuário ao grupo docker

### Limpar tudo e começar do zero
```bash
# Parar e remover containers, volumes e imagens
docker-compose down -v
docker system prune -a
```

## 📝 Notas Importantes

1. **Senhas**: Sempre altere as senhas padrão (`MYSQL_ROOT_PASSWORD`, `JWT_SECRET`, `JWT_REFRESH_SECRET`) em produção!

2. **Primeira Execução**: Na primeira vez, execute `docker-compose exec backend npx sequelize db:seed:all` para popular o banco.

3. **Persistência**: Os dados do MySQL são salvos em `.docker/data/`. Não delete esta pasta se quiser manter os dados.

4. **WhatsApp Web.js**: Os dados de autenticação do WhatsApp são salvos em `./backend/.wwebjs_auth/`. Mantenha este diretório para não precisar escanear o QR code novamente.

5. **Desenvolvimento**: Para desenvolvimento, você pode montar volumes com o código fonte para hot-reload, mas isso não está configurado por padrão.

## 🔄 Atualização

Para atualizar o projeto:

```bash
# Parar os containers
docker-compose down

# Atualizar o código
git pull

# Reconstruir e iniciar
docker-compose up -d --build

# Executar novas migrations se houver
docker-compose exec backend npx sequelize db:migrate
```

## 📚 Recursos Adicionais

- [Documentação Docker Compose](https://docs.docker.com/compose/)
- [Documentação WhaTicket](https://github.com/canove/whaticket)

