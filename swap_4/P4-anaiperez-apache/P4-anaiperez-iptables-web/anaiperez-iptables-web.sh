#!/bin/bash

#politicas de seguridaad
#limpiar reglas anteriores
iptables -F
iptables -X

#denegación implicitia
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

#permitir tráfico local
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#permitir tráfico entrante de cnexiones establecidas
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#permitir tráfico saliente de cnexiones establecidas
iptables -A OUTPUT -m state --state     NEW,ESTABLISHED,RELATED -j ACCEPT

#permitir tráfico entrante al puerto 80 (HTTP) y 443 (HTTPS) sólo desde el balanceador de carga
iptables -A INPUT -p tcp -s 192.168.10.50 --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.10.50 --dport 443 -j ACCEPT
