#!/bin/bash
sudo apt update && sudo apt install -y consul haproxy
# Instalar dependencias necesarias
sudo apt install -y curl unzip gnupg2 lsb-release ca-certificates

# Instalar Node.js 18.20.7
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verifica la instalación de Node.js
node -v

# Instalar Artillery
sudo npm install -g artillery

# Verifica la instalación de Artillery
artillery -V

# Verificar instalación de Artillery
echo "Artillery version: $(artillery -V)"

# Configurar Consul como servidor
cat <<EOF | sudo tee /etc/consul.d/server.hcl
server = true
bootstrap_expect = 1
bind_addr = "192.168.100.3"
client_addr = "0.0.0.0"
data_dir = "/opt/consul"
ui = true
EOF

sudo systemctl restart consul

# Configurar HAProxy
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg


global
    stats socket /var/run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s


frontend http_front
    bind *:80
    default_backend web_servers


backend web_servers
    balance roundrobin
    server-template web1 1-10 _web1._tcp.service.consul check resolvers consul
    server-template web2 1-10 _web2._tcp.service.consul check resolvers consul
    option httpchk GET /health
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms




resolvers consul
    nameserver dns 192.168.100.3:8600
    resolve_retries 3
    timeout retry 1s

listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /haproxy?stats
    stats refresh 10s
    stats auth admin:admin
    timeout client 50000ms
    timeout connect 5000ms
    timeout server 50000ms
EOF

sudo systemctl restart haproxy
