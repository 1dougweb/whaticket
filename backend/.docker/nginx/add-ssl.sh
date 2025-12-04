#!/bin/sh
# Script para adicionar configuração SSL ao Nginx do backend

SSL_CERTIFICATE=/etc/nginx/ssl/fullchain.pem
SSL_CERTIFICATE_KEY=/etc/nginx/ssl/privkey.pem
SSL_CONF=/etc/nginx/conf.d/backend-ssl.conf

if [ -f ${SSL_CERTIFICATE} ] && [ -f ${SSL_CERTIFICATE_KEY} ]; then
    echo "SSL certificates found, adding SSL configuration..."
    
    cat > ${SSL_CONF} << EOF
# Configuração SSL para o Backend
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name _;

    ssl_certificate ${SSL_CERTIFICATE};
    ssl_certificate_key ${SSL_CERTIFICATE_KEY};

    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Tamanho máximo de upload
    client_max_body_size 20M;

    # Logs
    access_log /var/log/nginx/backend-ssl-access.log main;
    error_log /var/log/nginx/backend-ssl-error.log warn;

    # Proxy para o Node.js
    location / {
        proxy_pass http://nodejs_backend;
        proxy_http_version 1.1;
        
        # Headers importantes
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # WebSocket support (para Socket.IO)
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # Servir arquivos estáticos diretamente
    location /public/ {
        alias /usr/src/app/public/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF
    
    echo "SSL configuration added successfully"
else
    echo "SSL certificates not found, skipping SSL configuration"
    # Remover arquivo de SSL se existir
    rm -f ${SSL_CONF}
fi

