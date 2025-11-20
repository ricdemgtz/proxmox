#!/bin/bash
# Diagnóstico profundo de AdGuard DNS - LXC 103

set -e

LOG_FILE="/var/log/adguard-deep-diagnostico.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "===== Diagnóstico Profundo AdGuard DNS - LXC 103 ====="

# 1. Verificar binding de AdGuard
log "1. Verificando configuración de binding de AdGuard..."
pct exec 103 -- grep -A 5 "bind_host" /opt/AdGuardHome/AdGuardHome.yaml || log "No se encontró bind_host"

# 2. Test DNS desde DENTRO del LXC
log "2. Test DNS desde DENTRO del LXC 103..."
log "   Test localhost (127.0.0.1):"
pct exec 103 -- dig @127.0.0.1 google.com +short +time=2 || log "   Falló en localhost"

log "   Test IP del LXC (192.168.1.120):"
pct exec 103 -- dig @192.168.1.120 google.com +short +time=2 || log "   Falló en IP del LXC"

# 3. Verificar que AdGuard está escuchando en 0.0.0.0 (no solo 127.0.0.1)
log "3. Verificando interfaces donde escucha AdGuard..."
pct exec 103 -- ss -ulnp | grep ':53'
pct exec 103 -- ss -tlnp | grep ':53'

# 4. Verificar conectividad de red del LXC
log "4. Verificando conectividad de red del LXC..."
log "   IP del LXC:"
pct exec 103 -- ip addr show eth0

log "   Tabla de rutas:"
pct exec 103 -- ip route

log "   Ping al gateway:"
pct exec 103 -- ping -c 2 192.168.1.1 || log "   No puede hacer ping al gateway"

# 5. Test con tcpdump para ver si llegan paquetes
log "5. Capturando tráfico DNS (5 segundos)..."
log "   Iniciando tcpdump en LXC 103..."
pct exec 103 -- timeout 5 tcpdump -i eth0 port 53 -n &
TCPDUMP_PID=$!

sleep 1
log "   Enviando consulta DNS desde el nodo..."
dig @192.168.1.120 google.com +short +time=2 || log "   Consulta falló"

wait $TCPDUMP_PID 2>/dev/null || log "   Tcpdump completado"

# 6. Verificar logs de AdGuard en tiempo real
log "6. Últimas líneas de logs de AdGuard..."
pct exec 103 -- journalctl -u AdGuardHome -n 30 --no-pager

# 7. Verificar archivo de configuración completo
log "7. Configuración completa de AdGuard (primeras 100 líneas)..."
pct exec 103 -- head -100 /opt/AdGuardHome/AdGuardHome.yaml

# 8. Test con nslookup (alternativa a dig)
log "8. Test con nslookup..."
nslookup google.com 192.168.1.120 || log "   nslookup falló"

# 9. Verificar si hay otro servicio en puerto 53
log "9. Verificando procesos escuchando en puerto 53..."
pct exec 103 -- lsof -i :53 || pct exec 103 -- ss -ulnp | grep ':53'

log "===== Fin del diagnóstico profundo ====="
