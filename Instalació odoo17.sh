#!/bin/bash

#
## SCRIPT HECHO POR Oscar Montero
### Script de instalación de Odoo, postgresql, Nginx, firewall i Certbot.
#ODDO_VERSION="17.0"
#POSTGRESQL_VERSION="13"
#Python_version="3.12"
#

# Actualizar el sistema (Preferiblemente hacerlo a mano y reiniciar el servidor antes de ejecutar el script)
sudo dnf update -y
sudo dnf install epel-release dnf-plugins-core -y

# Instalar NGINX y Certbot
sudo dnf install -y certbot nginx

# Creación de las carpetas sites-available y sites-enabled
sudo mkdir -p /etc/nginx/sites-available && sudo mkdir -p /etc/nginx/sites-enabled

# Fichero nginx.conf

# Eliminar el archivo de configuración de nginx si existe
sudo rm -f /etc/nginx/nginx.conf

# Crear el nuevo archivo de configuración
sudo sh -c 'cat <<EOF | tee /etc/nginx/nginx.conf
# For more information on configuration, see:
# * Official English Documentation: http://nginx.org/en/docs/
# * Official Russian Documentation: http://nginx.org/ru/docs/
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
        '\$status \$body_bytes_sent "\$http_referer" '
        '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*.conf;
}
EOF'

# Crear el archivo dhparam.pem
sudo mkdir -p /etc/cert/certs
sudo sh -c 'cat <<EOF > /etc/cert/certs/dhparam.pem
-----BEGIN DH PARAMETERS-----
MIICCAKCAgEA3eINXN1xzhfnc7ku6Vuim65H0K+kjZD9yiKVLTBw41EYJVfRupOX
ze05bzJFQlLipBiI9OAOWuiwLLkFeGxu3fFkOVfaviR5VBpPz6sQYwNL152Fs37y
j74Y8orq01sgn+BB++S0CIQCh+AQWzSjyEnGuME93wH2NBMl52Ht9ZWmFSn6XvQM
Tvx5vpBNk/4+i5NPZ6Ptc6jH1lofXh/0F1Yvg0yUyhYJzzwJUNrRju5V0y4qS3Y1
HiU267HEd7T1zuc20Yl+/Rs8lULe6+kS77Y3+5u1hozen4WcM2rIxGEBCBCDjNf9
km5wP1HHhnq/KZtlv0u68wEW73AO5zWzLRI2KaclS0X2c4zMkvM3q1BlE1ZSctq6
lR08sR3zCENrpLqtRL4+0HWNxUEBAPjq/4jyacmbFsQ/59D9dCiJt/hLehG3O8P1
OYRWqCMuOQT4T78wQQcTZHxguxdaUdxmgfNBP0SXfjeebApgpg8YhtgD1biGYFqc
lCHvoHALCBwvQWgu5lCd+RuBqPXRTC27fy9xpo1js9+KzJpxIluqodDBGlX88VYJ
ZkGswo0RIqst5AbE8w9Dq3lEmPH3Y68ViFzvbFtePFx9NdxvTjLhMNzvZvQGgWJI
eeXdqk+M3lfk6Rmy+LrqUiru/fPbPNPLyAFBByTmYf8OMQA/cOiKrAMCAQI=
-----END DH PARAMETERS-----
EOF'

# Crear archivo de nginx 
sudo sh -c 'cat <<EOF > /etc/nginx/sites-available/odoo.conf
limit_req_zone $binary_remote_addr zone=ip:10m rate=3r/s;
upstream odoo {
   server 127.0.0.1:8069;
}
upstream odoo-chat {
   server 127.0.0.1:8072;
}
server {
    listen 80;
    server_name <nombre_dns_servidor>;
    
    # Si deseas aplicar la limitación de peticiones
    limit_req zone=ip burst=60;

    # Redirige todas las peticiones a HTTPS
    return 301 https://<nombre_dns_servidor>$request_uri;
}
server {
   listen 443 ssl http2;
   server_name <nombre_dns_servidor>;
   ssl_certificate /etc/letsencrypt/live/<nombre_dns_servidor>/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/<nombre_dns_servidor>/privkey.pem;
   ssl_session_timeout 1d;
   ssl_session_cache shared:SSL:50m;
   ssl_session_tickets off;
   ssl_dhparam /etc/cert/certs/dhparam.pem;
   ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
   ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA38
4:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES2
56-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-
RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
   ssl_prefer_server_ciphers on;
   add_header Strict-Transport-Security max-age=15768000;
   ssl_stapling on;
   ssl_stapling_verify on;
   ssl_trusted_certificate /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem;
   resolver 8.8.8.8 8.8.4.4;
   client_max_body_size 10M;
   access_log /var/log/nginx/odoo.access.log;
   error_log /var/log/nginx/odoo.error.log;
   proxy_read_timeout 720s;
   proxy_connect_timeout 720s;
   proxy_send_timeout 720s;
   proxy_set_header X-Forwarded-Host $host;
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header X-Forwarded-Proto $scheme;
   proxy_set_header X-Real-IP $remote_addr;
   location / {
      proxy_redirect off;
      proxy_pass http://odoo;
   }
   location /longpolling {
      proxy_pass http://odoo-chat;
   }
   location ~* /web/static/ {
      proxy_cache_valid 200 90m;
      proxy_buffering on;
      expires 864000;
      proxy_pass http://odoo;
   }
# gzip
   gzip_types text/css text/less text/plain text/xml application/xml application/json application/javascript;
   gzip on;
}
EOF'

# Crear enlace simbolico al fichero de Odoo.
sudo ln -s /etc/nginx/sites-available/odoo.conf /etc/nginx/sites-enabled/odoo.conf

# Iniciar el servicio de Nginx
sudo systemctl enable nginx

# Instalar Odoo
sudo dnf install -y git gcc wget nodejs libxslt-devel bzip2-devel openldap-devel libjpeg-devel freetype-devel postgresql-libs postgresql-devel gcc-c++ epel-release
sudo dnf install python3-devel -y
sudo yum install libsasl2-devel openldap-devel -y

# Instalar conversor html a pdf
sudo mkdir -p /opt/odoo/
sudo wget -P /opt/odoo https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox-0.12.6.1-2.almalinux9.x86_64.rpm
sudo dnf localinstall -y /opt/odoo/wkhtmltox-0.12.6.1-2.almalinux9.x86_64.rpm

# Instalar PostgreSQL

sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql13-server postgresql13 postgresql13-devel --nobest --skip-broken

# Encender el PostgreSQL
sudo /usr/pgsql-13/bin/postgresql-13-setup initdb
sudo systemctl start postgresql-13
sudo systemctl enable postgresql-13

# Crear usuario odoo en PostgreSQL
sudo su - postgres -c "createuser -s odoo"

# Crear usuario odoo y preparar el entorno
sudo useradd -m -U -r -d /opt/odoo -s /bin/bash odoo
sudo chown -R odoo /opt/odoo
sudo chgrp -R odoo /opt/odoo
sudo su - odoo -c "git clone https://www.github.com/odoo/odoo --depth 1 --branch 17.0 /opt/odoo/odoo17"
sudo su - odoo -c "python3.12 -m venv /opt/odoo/odoo17-venv"
sudo su - odoo -c "source /opt/odoo/odoo17-venv/bin/activate && pip install --upgrade pip && pip install -r /opt/odoo/odoo17/requirements.txt && pip install psycopg2-binary && deactivate"
sudo su - odoo -c "mkdir /opt/odoo/odoo17-custom-addons"
sudo su - odoo -c "exit"

# Crear directorio de registro de Odoo y Odoo-desa
sudo mkdir /var/log/odoo17

# Creación de los registros
sudo touch /var/log/odoo17/odoo-desa.log
sudo touch /var/log/odoo17/odoo.log

# Dar permisos al usuario de odoo a los logs
sudo chown -R odoo:odoo /var/log/odoo17/

# Crear archivo de configuración de Odoo
sudo sh -c 'cat <<EOF > /etc/odoo.conf
[options]
; This is the password that allows database operations:
admin_passwd = Iedoo8oo ohPii4ai
db_host = False
db_port = False
db_user = odoo
db_password = False
xmlrpc_port = 8069
longpolling_port = 8072
logfile = /var/log/odoo17/odoo.log
logrotate = True
addons_path = /opt/odoo/odoo17/addons,/opt/odoo/odoo17-custom-addons
proxy_mode = True
EOF'

# Crear archivo de servicio systemd de Odoo
sudo sh -c 'cat <<EOF > /etc/systemd/system/odoo17.service
[Unit]
Description=Odoo17
StartLimitIntervalSec=300
StartLimitBurst=5
[Service]
Type=simple
SyslogIdentifier=odoo17
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/opt/odoo/odoo17-venv/bin/python3.12 /opt/odoo/odoo17/odoo-bin -c /etc/odoo.conf
StandardOutput=journal+console
Restart=on-failure
RestartSec=1s
[Install]
WantedBy=multi-user.target
EOF'

# Recargar servicios systemd otra vez
sudo systemctl daemon-reload

# Iniciar y habilitar el servicio Odoo16
sudo systemctl start odoo17
sudo systemctl enable odoo17

# Instalar Firewalld
sudo dnf install -y firewalld

# Encender el servicio de Firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Añadir los puertos al Firewalld (Si instalas NGINX y lo configuras manualmente)
sudo firewall-cmd --add-port=80/tcp && sudo firewall-cmd --add-port=443/tcp && sudo firewall-cmd --add-port=8888/tcp

# Hacer un port forwarding para conectarse al odoo(Solo si el NGINX no está configurado porque falta SSL)

# sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8069

# Guardar la configuración del firewalld
sudo firewall-cmd --runtime-to-permanent
#Permisos
sudo chown -R odoo:odoo /opt/odoo
sudo chmod -R 755 /opt/odoo
