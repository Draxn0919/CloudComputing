#!/bin/bash
# Actualizar e instalar las dependencias necesarias
sudo apt update && sudo apt install -y nodejs npm consul

# Crear la aplicación Node.js
cat <<EOF > app.js
const http = require('http');
const port = process.argv[2]; 
http.createServer((req, res) => {
    if (req.url === '/health') {
        res.writeHead(200, {'Content-Type': 'text/plain'});
        res.end('Healthy');
    } else {
        res.writeHead(200, {'Content-Type': 'text/plain'});
        res.end('Hello from Web1 (port ' + port + ')');
    }
}).listen(port, () => console.log('Server running on port ' + port));
EOF

# Iniciar las aplicaciones Node.js en puertos diferentes
node app.js 3000 &  # Instancia 1 en puerto 3000
node app.js 3001 &  # Instancia 2 en puerto 3001

# Configurar Consul como cliente y registrar ambas instancias como servicios
cat <<EOF | sudo tee /etc/consul.d/web1_service_1.hcl
service {
  name = "web1"
  id = "web1-1"  # ID único para la primera instancia
  tags = ["web1"]
  port = 3000
  check {
    http = "http://192.168.100.10:3000/health"
    interval = "10s"
    timeout = "5s"
    deregistercriticalserviceafter = "5m"
  }
}
EOF

cat <<EOF | sudo tee /etc/consul.d/web1_service_2.hcl
service {
  name = "web1"
  id = "web1-2"  # ID único para la segunda instancia
  tags = ["web1-2"]
  port = 3001
  check {
    http = "http://192.168.100.10:3001/health"
    interval = "10s"
    timeout = "5s"
    deregistercriticalserviceafter = "5m"
  }
}
EOF

# Configurar Consul como cliente
cat <<EOF | sudo tee /etc/consul.d/client.hcl
server = false
bind_addr = "192.168.100.10"
retry_join = ["192.168.100.3"]
data_dir = "/opt/consul"
EOF

# Iniciar Consul como servicio
sudo systemctl enable consul
sudo systemctl restart consul
