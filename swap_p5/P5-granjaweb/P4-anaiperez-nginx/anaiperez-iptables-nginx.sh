#!/bin/bash

# =====================================================================
# CONFIGURACIÓN ESTRUCTURAL Y BÁSICA
# =====================================================================

# 1. Limpiar reglas anteriores
iptables -F
iptables -X

# 2. Denegación implícita (Política restrictiva obligatoria)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT # Permitimos salida para que Nginx contacte con los Apache

# 3. Permitir tráfico local y conexiones establecidas
# Esencial para que el sistema no se bloquee y Nginx reciba las respuestas de los Apache
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT


# =====================================================================
# APARTADO A1: POLÍTICAS DE SEGURIDAD EN EL BALANCEADOR
# =====================================================================

# 4. Bloquear escaneo de puertos (Detectar paquetes sospechosos)
# Filtra combinaciones de flags TCP inválidas usadas por herramientas como Nmap
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# 6. Mitigar Inyección SQL (Módulo string)
# Inspección profunda de paquetes (DPI) buscando palabras clave de payloads SQL
iptables -A INPUT -p tcp --dport 80 -m string --algo bm --string "SELECT" -j DROP
iptables -A INPUT -p tcp --dport 80 -m string --algo bm --string "UNION" -j DROP
iptables -A INPUT -p tcp --dport 80 -m string --algo bm --string "INSERT" -j DROP

# 7. Mitigar XSS (Módulo string)
# Bloquea la inyección de etiquetas scripts maliciosas en peticiones HTTP
iptables -A INPUT -p tcp --dport 80 -m string --algo bm --string "<script>" -j DROP


# =====================================================================
# APARTADO A2: CONFIGURACIÓN AVANZADA PARA MITIGACIÓN DE DDOS
# =====================================================================

# A2-Punto 1: Protección contra ataques de Fragmentación (Fraggle/Teardrop)
# Descarta fragmentos de paquetes malformados destinados a colapsar el kernel
iptables -A INPUT -f -j DROP

# A2-Punto 2: Control de inundaciones SYN (SYN Flood) mediante módulo 'limit'
# Limita la tasa de intentos de conexión: ráfaga máxima de 20 y luego 5 por segundo
iptables -A INPUT -p tcp --syn --dport 80 -m limit --limit 5/s --limit-burst 20 -j ACCEPT
iptables -A INPUT -p tcp --syn --dport 443 -m limit --limit 5/s --limit-burst 20 -j ACCEPT

# A2-Punto 3: Mitigación de HTTP Flood mediante el módulo 'recent' (Lista Negra Dinámica)
# Registra conexiones y bloquea temporalmente a la IP si supera 10 conexiones nuevas en 10 segundos
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --set --name BLOQUEADOS_DDOS
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 --name BLOQUEADOS_DDOS -j DROP

iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --set --name BLOQUEADOS_DDOS
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 --name BLOQUEADOS_DDOS -j DROP

# A2-Punto 4: Limitación de conexiones simultáneas por IP (Tu antiguo Bloque 5)
# Umbral estricto para evitar el agotamiento de sockets de Nginx
iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 10 -j DROP
iptables -A INPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 10 -j DROP


# =====================================================================
# APERTURA FINAL DE PUERTOS
# =====================================================================

# 8. Abrir puertos HTTP y HTTPS al público legítimo
# Solo llegan aquí los paquetes limpios que superaron todos los filtros anteriores
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT