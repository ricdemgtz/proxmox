#!/bin/bash
# Script para abrir puerto 53 (DNS) en firewall de Proxmox para LXC 103

set -e

LOG_FILE="/var/log/adguard-firewall-fix.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "===== Fix Firewall AdGuard DNS - LXC 103 ====="

# Verificar estado actual del firewall
log "Estado actual del firewall de Proxmox..."
pve-firewall status

log "Reglas actuales para LXC 103..."
cat /etc/pve/firewall/103.fw 2>/dev/null || log "No existe archivo de firewall para LXC 103"

# Crear/actualizar reglas de firewall para LXC 103
log "Creando reglas de firewall para permitir DNS (puerto 53)..."

cat > /etc/pve/firewall/103.fw << 'EOF'
[OPTIONS]
enable: 1

[RULES]
# AdGuard Home - DNS (permitir desde toda la red local)
IN ACCEPT -p udp -dport 53 -source 192.168.1.0/24
IN ACCEPT -p tcp -dport 53 -source 192.168.1.0/24

# AdGuard Home - Web Interface
IN ACCEPT -p tcp -dport 80 -source 192.168.1.0/24

# ICMP (ping)
IN ACCEPT -p icmp

# Permitir todo el tráfico desde el nodo host
IN ACCEPT -source 192.168.1.78
IN ACCEPT -source 192.168.1.82
EOF

log "Archivo de firewall creado en /etc/pve/firewall/103.fw"

# Mostrar el contenido
log "Contenido del archivo de firewall:"
cat /etc/pve/firewall/103.fw

# Habilitar firewall de Proxmox si está deshabilitado
FIREWALL_STATUS=$(pve-firewall status | grep "Status:" | awk '{print $2}')
if [[ "$FIREWALL_STATUS" == "disabled/running" ]]; then
    log "ADVERTENCIA: Firewall de Proxmox está deshabilitado globalmente"
    log "Las reglas del LXC 103 están creadas pero NO se aplicarán hasta que habilites el firewall"
    log "Para habilitar: edita /etc/pve/firewall/cluster.fw y pon 'enable: 1'"
    log "O ejecuta desde la UI: Datacenter → Firewall → Options → Enable"
fi

# Reiniciar firewall para aplicar cambios
log "Reiniciando firewall de Proxmox..."
pve-firewall restart

# Esperar un momento
sleep 2

# Verificar que se aplicaron las reglas
log "Verificando reglas aplicadas..."
pve-firewall status

# Test DNS después del cambio
log "Probando consulta DNS después del cambio..."
sleep 2
dig @192.168.1.120 google.com +short +time=5 || log "DNS aún no responde - puede necesitar más tiempo"

log "===== Fix completado ====="
log ""
log "NOTA: Si el problema persiste, verifica:"
log "1. Firewall del datacenter: /etc/pve/firewall/cluster.fw"
log "2. Firewall del nodo proxmox"
log "3. Ejecutar manualmente: pve-firewall compile"
