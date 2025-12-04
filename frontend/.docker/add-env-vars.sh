_writeFrontendEnvVars() {
    ENV_JSON="$(jq --compact-output --null-input 'env | with_entries(select(.key | startswith("REACT_APP_")))')"
    ENV_JSON_ESCAPED="$(printf "%s" "${ENV_JSON}" | sed -e 's/[\&/]/\\&/g')"
    sed -i "s/<noscript id=\"env-insertion-point\"><\/noscript>/<script>var ENV=${ENV_JSON_ESCAPED}<\/script>/g" ${PUBLIC_HTML}index.html
}

_writeNginxEnvVars() {
    # O arquivo default.conf já existe no container (copiado durante o build)
    # Apenas modificar o server_name se necessário
    if [ -n "$FRONTEND_SERVER_NAME" ]; then
        sed -i "s/server_name _;/server_name ${FRONTEND_SERVER_NAME};/" /etc/nginx/conf.d/default.conf
    fi
    
    # Adicionar bloco server para backend se BACKEND_SERVER_NAME estiver definido
    if [ -n "$BACKEND_SERVER_NAME" ]; then
        # Verificar se o bloco já não existe
        if ! grep -q "server_name ${BACKEND_SERVER_NAME}" /etc/nginx/conf.d/default.conf; then
            cat >> /etc/nginx/conf.d/default.conf << EOF

server {
    server_name ${BACKEND_SERVER_NAME};
    include sites.d/backend.conf;
    include include.d/letsencrypt.conf;
}
EOF
        fi
    fi
}

_addSslConfig() {
    SSL_CERTIFICATE=/etc/nginx/ssl/${1}/fullchain.pem;
    SSL_CERTIFICATE_KEY=/etc/nginx/ssl/${1}/privkey.pem;
    FILE_CONF=/etc/nginx/sites.d/${1}.conf
    FILE_SSL_CONF=/etc/nginx/conf.d/00-ssl-redirect.conf;

    # Limpar o arquivo de configuração se existir
    if [ -f ${FILE_CONF} ]; then
        > ${FILE_CONF}
    fi

    if [ -f ${SSL_CERTIFICATE} ] && [ -f ${SSL_CERTIFICATE_KEY} ]; then
        echo "saving ssl config in ${FILE_CONF}"
        echo 'listen 443 ssl http2;' >> ${FILE_CONF};
        echo 'listen [::]:443 ssl http2;' >> ${FILE_CONF};
        echo 'include "include.d/ssl.conf";' >> ${FILE_CONF};
        echo "ssl_certificate ${SSL_CERTIFICATE};" >> ${FILE_CONF};
        echo "ssl_certificate_key ${SSL_CERTIFICATE_KEY};" >> ${FILE_CONF};
        
        # Criar arquivo de redirect SSL se não existir
        if [ ! -f ${FILE_SSL_CONF} ]; then
            echo 'include include.d/ssl-redirect.conf;' > ${FILE_SSL_CONF};
        fi
    else
        echo 'listen 80;' >> ${FILE_CONF};
        echo "ssl ${1} not found >> ${SSL_CERTIFICATE} -> ${SSL_CERTIFICATE_KEY}"
    fi;
}

_writeFrontendEnvVars;
_writeNginxEnvVars;

_addSslConfig 'backend'
_addSslConfig 'frontend'