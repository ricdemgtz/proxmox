#!/bin/bash
# Fix AdGuard - Configurar para escuchar en todas las interfaces

set -e

LOG_FILE="/var/log/adguard-binding-fix.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "===== Fix AdGuard DNS Binding - LXC 103 ====="

# 1. Verificar configuración actual
log "1. Configuración actual de binding..."
pct exec 103 -- grep -A 3 "bind_host" /opt/AdGuardHome/AdGuardHome.yaml

# 2. Backup de la configuración
log "2. Creando backup de la configuración..."
pct exec 103 -- cp /opt/AdGuardHome/AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml.backup-$(date +%Y%m%d-%H%M%S)

# 3. Cambiar bind_host a 0.0.0.0
log "3. Modificando configuración para escuchar en todas las interfaces..."
pct exec 103 -- sed -i 's/bind_host: 127.0.0.1/bind_host: 0.0.0.0/g' /opt/AdGuardHome/AdGuardHome.yaml

# Verificar el cambio
log "4. Nueva configuración de binding..."
pct exec 103 -- grep -A 3 "bind_host" /opt/AdGuardHome/AdGuardHome.yaml

# 5. Reiniciar servicio AdGuard
log "5. Reiniciando servicio AdGuard Home..."
pct exec 103 -- systemctl restart AdGuardHome

# 6. Esperar a que inicie
sleep 3

# 7. Verificar que está corriendo
log "6. Verificando estado del servicio..."
pct exec 103 -- systemctl status AdGuardHome --no-pager | head -10

# 8. Verificar que está escuchando en 0.0.0.0
log "7. Verificando interfaces de escucha..."
pct exec 103 -- ss -ulnp | grep ':53'

# 9. Test DNS
log "8. Probando consulta DNS..."
sleep 2
dig @192.168.1.120 google.com +short +time=5 || log "DNS aún no responde"

log "===== Fix completado ====="
log ""
log "Si el DNS ahora funciona, el problema era que AdGuard estaba escuchando solo en 127.0.0.1"
log "Ahora está configurado para escuchar en 0.0.0.0 (todas las interfaces)"
