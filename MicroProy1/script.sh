#!/bin/bash

# Configurando el archivo resolv.conf
echo "Configurando el resolv.conf..."
sudo bash -c 'cat <<EOF > /etc/resolv.conf
nameserver 8.8.8.8
EOF'

# Instalando el servidor vsftpd
echo "Instalando el servidor vsftpd..."
sudo apt-get update && sudo apt-get install -y vsftpd

# Modificando vsftpd.conf con sed
echo "Modificando vsftpd.conf..."
sudo sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf

# Configurando IP forwarding
echo "Configurando IP forwarding..."
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf > /dev/null

# Aplicando cambios en la configuración del sistema
sudo sysctl -p

echo "Configuración completada."
