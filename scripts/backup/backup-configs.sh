#!/bin/bash
#
# Script de Backup de Configuraciones de Proxmox
# 
# Respalda archivos de configuración importantes del sistema
# Uso: ./backup-configs.sh
#

set -e

# Configuración
BACKUP_BASE_DIR="/var/backups/proxmox-configs"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE_DIR/$DATE"
LOG_FILE="/var/log/proxmox-config-backup.log"
RETENTION_DAYS=30

# Crear directorio de backup
mkdir -p "$BACKUP_DIR"

# Función de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "===== Iniciando backup de configuraciones ====="

# Backup de configuración de Proxmox
log "Respaldando /etc/pve/"
tar czf "$BACKUP_DIR/pve-config.tar.gz" -C /etc pve/ 2>/dev/null || log "Advertencia: Algunos archivos de /etc/pve/ no se pudieron respaldar"

# Backup de configuración de red
log "Respaldando configuración de red"
cp /etc/network/interfaces "$BACKUP_DIR/interfaces" 2>/dev/null || log "Advertencia: No se pudo respaldar /etc/network/interfaces"
cp -r /etc/network/interfaces.d "$BACKUP_DIR/" 2>/dev/null || true

# Backup de configuración de firewall del host
log "Respaldando configuración de firewall"
if [ -f /etc/pve/firewall/cluster.fw ]; then
    cp /etc/pve/firewall/cluster.fw "$BACKUP_DIR/cluster.fw"
fi

# Backup de storage.cfg
log "Respaldando configuración de almacenamiento"
cp /etc/pve/storage.cfg "$BACKUP_DIR/storage.cfg" 2>/dev/null || true

# Backup de lista de paquetes instalados
log "Generando lista de paquetes instalados"
dpkg --get-selections > "$BACKUP_DIR/installed-packages.txt"

# Backup de versión de Proxmox
log "Registrando versión de Proxmox"
pveversion > "$BACKUP_DIR/pve-version.txt"

# Backup de configuración de crontab
log "Respaldando crontab"
crontab -l > "$BACKUP_DIR/root-crontab.txt" 2>/dev/null || echo "No crontab configurado" > "$BACKUP_DIR/root-crontab.txt"

# Crear archivo de información del sistema
log "Generando información del sistema"
cat > "$BACKUP_DIR/system-info.txt" << EOF
Hostname: $(hostname)
Fecha: $(date)
Kernel: $(uname -r)
Uptime: $(uptime)
Memoria: $(free -h | grep Mem)
Disco: $(df -h / | grep /)
EOF

# Comprimir todo el backup
log "Comprimiendo backup"
cd "$BACKUP_BASE_DIR"
tar czf "proxmox-config-$DATE.tar.gz" "$DATE"
rm -rf "$DATE"

# Limpiar backups antiguos
log "Limpiando backups antiguos (más de $RETENTION_DAYS días)"
find "$BACKUP_BASE_DIR" -name "proxmox-config-*.tar.gz" -mtime +$RETENTION_DAYS -delete

log "===== Backup de configuraciones completado: $BACKUP_BASE_DIR/proxmox-config-$DATE.tar.gz ====="
