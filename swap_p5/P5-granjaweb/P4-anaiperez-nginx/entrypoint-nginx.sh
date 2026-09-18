#!/bin/bash
# Ejecuta el script de iptables
./anaiperez-iptables-nginx.sh

# Luego, ejecuta el comando principal del contenedor
exec "$@"