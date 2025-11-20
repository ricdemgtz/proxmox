#!/bin/bash
# Script de diagnóstico para AdGuard DNS en LXC 103

set -e

LOG_FILE="/var/log/adguard-diagnostico.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "===== Diagnóstico de AdGuard DNS en LXC 103 ====="

# Verificar que el LXC está corriendo
log "Verificando estado del LXC 103..."
pct status 103

# Verificar servicio AdGuard
log "Verificando servicio AdGuard..."
pct exec 103 -- systemctl status AdGuardHome --no-pager || log "Servicio no encontrado con ese nombre"

# Verificar puertos DNS (53)
log "Verificando puerto 53 (DNS)..."
pct exec 103 -- ss -ulnp | grep ':53' || log "Puerto 53 UDP no está escuchando"
pct exec 103 -- ss -tlnp | grep ':53' || log "Puerto 53 TCP no está escuchando"

# Test directo de DNS desde el nodo
log "Probando resolución DNS directa..."
dig @192.168.1.120 google.com +short || log "Resolución DNS falló"

# Verificar conectividad de red
log "Verificando conectividad de red al LXC 103..."
ping -c 3 192.168.1.120 || log "Ping falló"

# Verificar configuración de DNS en el LXC
log "Verificando configuración DNS del LXC..."
pct exec 103 -- cat /etc/resolv.conf

# Verificar logs de AdGuard
log "Obteniendo logs de AdGuard..."
pct exec 103 -- journalctl -u AdGuardHome -n 50 --no-pager || log "No se pudieron obtener logs del servicio"

# Verificar si hay firewall bloqueando
log "Verificando reglas de firewall..."
pct exec 103 -- iptables -L -n -v | head -20 || log "No se pudo verificar iptables"

log "===== Fin del diagnóstico ====="
