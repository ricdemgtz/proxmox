#!/bin/bash
#
# Script de Mantenimiento para Proxmox
# 
# Realiza tareas de mantenimiento del sistema
# Uso: ./system-maintenance.sh
#

set -e

LOG_FILE="/var/log/proxmox-maintenance.log"

# Función de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "===== Iniciando mantenimiento del sistema ====="

# Actualizar lista de paquetes
log "Actualizando lista de paquetes..."
apt-get update >> "$LOG_FILE" 2>&1

# Mostrar paquetes actualizables
log "Paquetes disponibles para actualizar:"
apt list --upgradable 2>/dev/null | tee -a "$LOG_FILE"

# Limpiar paquetes antiguos
log "Limpiando paquetes antiguos..."
apt-get autoremove -y >> "$LOG_FILE" 2>&1
apt-get autoclean -y >> "$LOG_FILE" 2>&1

# Limpiar logs antiguos
log "Limpiando logs antiguos (más de 30 días)..."
find /var/log -type f -name "*.log.*" -mtime +30 -delete
journalctl --vacuum-time=30d >> "$LOG_FILE" 2>&1

# Limpiar caché de APT
log "Limpiando caché de APT..."
apt-get clean >> "$LOG_FILE" 2>&1

# Verificar integridad del sistema de archivos (solo reporta, no repara)
log "Verificando uso de disco..."
df -h | tee -a "$LOG_FILE"

# Limpiar dumps antiguos si existen
if [ -d /var/lib/vz/dump ]; then
    log "Verificando dumps antiguos..."
    find /var/lib/vz/dump -type f -mtime +7 -ls | tee -a "$LOG_FILE"
fi

# Verificar estado de ZFS (si está instalado)
if command -v zpool &> /dev/null; then
    log "Estado de ZFS pools:"
    zpool status | tee -a "$LOG_FILE"
fi

# Verificar estado de LVM
log "Estado de LVM:"
pvs | tee -a "$LOG_FILE"
vgs | tee -a "$LOG_FILE"
lvs | tee -a "$LOG_FILE"

# Verificar servicios críticos
log "Verificando servicios críticos de Proxmox..."
for service in pve-cluster pvedaemon pveproxy pvestatd; do
    if systemctl is-active --quiet $service; then
        log "✓ $service está activo"
    else
        log "✗ $service NO está activo - REQUIERE ATENCIÓN"
    fi
done

# Generar reporte de espacio usado por VMs/Contenedores
log "=== Espacio usado por VMs ==="
qm list | tee -a "$LOG_FILE"

log "=== Espacio usado por Contenedores ==="
pct list | tee -a "$LOG_FILE"

# Verificar actualizaciones de Proxmox
log "Versión actual de Proxmox:"
pveversion | tee -a "$LOG_FILE"

log "===== Mantenimiento completado ====="
