#!/bin/bash
#
# Script de Backup Automatizado para Proxmox
# 
# Este script realiza backups de VMs y Contenedores especificados
# Uso: ./backup-vms.sh
#

set -e

# Configuración
BACKUP_DIR="/var/lib/vz/dump"
RETENTION_DAYS=7
LOG_FILE="/var/log/proxmox-backup.log"

# Lista de VMs a respaldar (separadas por espacio)
# Ejemplo: VMS="100 101 102"
VMS=""

# Lista de Contenedores a respaldar (separadas por espacio)
# Ejemplo: CONTAINERS="100 101 102"
CONTAINERS=""

# Modo de backup: snapshot, suspend, stop
BACKUP_MODE="snapshot"

# Compresión: 0 (sin compresión), 1 (gzip), zstd (zstandard)
COMPRESSION="zstd"

# Función de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Función para verificar espacio en disco
check_disk_space() {
    local available=$(df -BG "$BACKUP_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    local required=50 # GB mínimos requeridos
    
    if [ "$available" -lt "$required" ]; then
        log "ERROR: Espacio insuficiente en $BACKUP_DIR. Disponible: ${available}GB, Requerido: ${required}GB"
        exit 1
    fi
    log "Espacio disponible: ${available}GB"
}

# Función para respaldar VMs
backup_vms() {
    if [ -z "$VMS" ]; then
        log "No hay VMs configuradas para backup"
        return
    fi
    
    for vmid in $VMS; do
        log "Iniciando backup de VM $vmid"
        if vzdump "$vmid" --mode "$BACKUP_MODE" --compress "$COMPRESSION" --dumpdir "$BACKUP_DIR" >> "$LOG_FILE" 2>&1; then
            log "Backup de VM $vmid completado exitosamente"
        else
            log "ERROR: Falló el backup de VM $vmid"
        fi
    done
}

# Función para respaldar contenedores
backup_containers() {
    if [ -z "$CONTAINERS" ]; then
        log "No hay contenedores configurados para backup"
        return
    fi
    
    for ctid in $CONTAINERS; do
        log "Iniciando backup de contenedor $ctid"
        if vzdump "$ctid" --mode "$BACKUP_MODE" --compress "$COMPRESSION" --dumpdir "$BACKUP_DIR" >> "$LOG_FILE" 2>&1; then
            log "Backup de contenedor $ctid completado exitosamente"
        else
            log "ERROR: Falló el backup de contenedor $ctid"
        fi
    done
}

# Función para limpiar backups antiguos
cleanup_old_backups() {
    log "Limpiando backups con más de $RETENTION_DAYS días"
    find "$BACKUP_DIR" -name "vzdump-*.tar.*" -mtime +$RETENTION_DAYS -delete
    log "Limpieza completada"
}

# Función principal
main() {
    log "===== Iniciando proceso de backup ====="
    
    check_disk_space
    backup_vms
    backup_containers
    cleanup_old_backups
    
    log "===== Proceso de backup completado ====="
}

# Ejecutar
main
