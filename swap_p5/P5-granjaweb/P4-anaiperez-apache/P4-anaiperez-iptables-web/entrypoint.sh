#!/bin/bash

# Ejecuta el script de iptables d
./anaiperez-iptables-web.sh 

# Luego, ejecuta el comando principal del contenedor (Apache)
# La instrucción exec "$@" permite que el contenedor reciba señales correctamente
exec "$@" 