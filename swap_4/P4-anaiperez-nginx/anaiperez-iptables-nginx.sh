#!/bin/bash


#Limpiar reglas anteriores
iptables -F
iptables -X

#Denegación implícita (Política por defecto: DROP para INPUT y FORWARD, ACCEPT para OUTPUT)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT 

#Permitir tráfico local 
iptables -A INPUT -i lo -j ACCEPT



#Bloquear escaneo de puertos 
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

#Protección contra ataques de Fragmentación 
iptables -A INPUT -f -j DROP


#DDoS


# Control de conexiones simultáneas (connlimit) 
iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 10 -j DROP
iptables -A INPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 10 -j DROP

# Lista negra dinámica (recent) 
# Puerto 80
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 --name BLOQUEADOS_DDOS -j DROP
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --set --name BLOQUEADOS_DDOS
# Puerto 443
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 --name BLOQUEADOS_DDOS -j DROP
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --set --name BLOQUEADOS_DDOS

# Control de límites (limit),r alentiza las conexiones nuevas permitidas
iptables -A INPUT -p tcp --syn --dport 80 -m limit --limit 5/s --limit-burst 20 -j ACCEPT
iptables -A INPUT -p tcp --syn --dport 443 -m limit --limit 5/s --limit-burst 20 -j ACCEPT


# Inyección SQL 
iptables -A INPUT -p tcp -m multiport --dports 80,443 -m string --algo bm --string "SELECT" -j DROP
iptables -A INPUT -p tcp -m multiport --dports 80,443 -m string --algo bm --string "UNION" -j DROP
iptables -A INPUT -p tcp -m multiport --dports 80,443 -m string --algo bm --string "INSERT" -j DROP

# XSS 
iptables -A INPUT -p tcp -m multiport --dports 80,443 -m string --algo bm --string "<script>" -j DROP


# Control de tráfico 
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Apertura final para los paquetes limpios que inician conexión 
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT