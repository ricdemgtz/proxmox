#!/bin/bash
#
# Script de Backup Pre-Eliminación de Cluster
# 
# Realiza backups completos antes de eliminar el cluster
# Uso: ./pre-cluster-removal-backup.sh
#

set -e

# Configuración
BACKUP_BASE="/root/cluster-removal-backup-$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$BACKUP_BASE/backup.log"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función de logging
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Crear directorio de backup
mkdir -p "$BACKUP_BASE"
log "Directorio de backup creado: $BACKUP_BASE"

# Verificar espacio disponible
AVAILABLE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
log "Espacio disponible: ${AVAILABLE_SPACE}GB"

if [ "$AVAILABLE_SPACE" -lt 10 ]; then
    error "Espacio insuficiente en disco. Se requieren al menos 10GB"
    exit 1
fi

echo ""
echo "========================================="
echo "  BACKUP PRE-ELIMINACIÓN DE CLUSTER"
echo "========================================="
echo ""
warning "Este script creará backups de:"
echo "  - Configuración del cluster"
echo "  - Configuraciones de VMs y Contenedores"
echo "  - Configuración de red"
echo "  - Configuración de storage"
echo "  - Usuarios y permisos"
echo "  - Lista de VMs y Contenedores"
echo ""
echo "Directorio de backup: $BACKUP_BASE"
echo ""
read -p "¿Continuar? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    echo "Operación cancelada"
    exit 1
fi

# ============================================
# INFORMACIÓN DEL CLUSTER
# ============================================
log "Recopilando información del cluster..."

if pvecm status &>/dev/null; then
    log "✓ Este nodo está en un cluster"
    pvecm status > "$BACKUP_BASE/cluster-status.txt" 2>&1
    pvecm nodes > "$BACKUP_BASE/cluster-nodes.txt" 2>&1
    
    if [ -f /etc/pve/corosync.conf ]; then
        cp /etc/pve/corosync.conf "$BACKUP_BASE/corosync.conf.backup"
        log "✓ Backup de corosync.conf guardado"
    fi
else
    warning "Este nodo NO está en un cluster (o el cluster no está disponible)"
    echo "NO EN CLUSTER" > "$BACKUP_BASE/cluster-status.txt"
fi

# Información del nodo
hostname > "$BACKUP_BASE/hostname.txt"
pveversion -v > "$BACKUP_BASE/pve-version.txt"

# ============================================
# BACKUP DE CONFIGURACIONES DE PROXMOX
# ============================================
log "Backup de configuraciones de Proxmox..."

# Backup completo de /etc/pve/
if [ -d /etc/pve ]; then
    log "Respaldando /etc/pve/..."
    tar czf "$BACKUP_BASE/pve-config-full.tar.gz" /etc/pve/ 2>/dev/null || warning "Algunos archivos de /etc/pve/ no se pudieron respaldar"
    log "✓ Backup de /etc/pve/ completado"
else
    error "/etc/pve/ no existe"
fi

# Backup de configuraciones específicas
log "Respaldando configuraciones específicas..."

# Storage
if [ -f /etc/pve/storage.cfg ]; then
    cp /etc/pve/storage.cfg "$BACKUP_BASE/storage.cfg.backup"
    log "✓ storage.cfg respaldado"
fi

# Datacenter config
if [ -f /etc/pve/datacenter.cfg ]; then
    cp /etc/pve/datacenter.cfg "$BACKUP_BASE/datacenter.cfg.backup"
    log "✓ datacenter.cfg respaldado"
fi

# Firewall
if [ -f /etc/pve/firewall/cluster.fw ]; then
    mkdir -p "$BACKUP_BASE/firewall"
    cp -r /etc/pve/firewall/* "$BACKUP_BASE/firewall/" 2>/dev/null || true
    log "✓ Configuración de firewall respaldada"
fi

# ============================================
# BACKUP DE CONFIGURACIÓN DE RED
# ============================================
log "Backup de configuración de red..."

cp /etc/network/interfaces "$BACKUP_BASE/interfaces.backup"
log "✓ /etc/network/interfaces respaldado"

if [ -d /etc/network/interfaces.d ]; then
    cp -r /etc/network/interfaces.d "$BACKUP_BASE/" 2>/dev/null || true
fi

# Información de red actual
ip addr show > "$BACKUP_BASE/ip-addresses.txt"
ip route show > "$BACKUP_BASE/routes.txt"
brctl show > "$BACKUP_BASE/bridges.txt" 2>/dev/null || ip link show type bridge > "$BACKUP_BASE/bridges.txt"

log "✓ Configuración de red respaldada"

# ============================================
# LISTA DE VMs Y CONTENEDORES
# ============================================
log "Listando VMs y Contenedores..."

qm list > "$BACKUP_BASE/vms-list.txt" 2>&1 || echo "No VMs found" > "$BACKUP_BASE/vms-list.txt"
pct list > "$BACKUP_BASE/containers-list.txt" 2>&1 || echo "No containers found" > "$BACKUP_BASE/containers-list.txt"

# Configuraciones individuales de VMs
log "Respaldando configuraciones de VMs..."
mkdir -p "$BACKUP_BASE/vm-configs"
if [ -d /etc/pve/qemu-server ]; then
    cp -r /etc/pve/qemu-server/* "$BACKUP_BASE/vm-configs/" 2>/dev/null || true
    VM_COUNT=$(ls "$BACKUP_BASE/vm-configs/" 2>/dev/null | wc -l)
    log "✓ $VM_COUNT configuraciones de VMs respaldadas"
fi

# Configuraciones individuales de Contenedores
log "Respaldando configuraciones de Contenedores..."
mkdir -p "$BACKUP_BASE/container-configs"
if [ -d /etc/pve/lxc ]; then
    cp -r /etc/pve/lxc/* "$BACKUP_BASE/container-configs/" 2>/dev/null || true
    CT_COUNT=$(ls "$BACKUP_BASE/container-configs/" 2>/dev/null | wc -l)
    log "✓ $CT_COUNT configuraciones de Contenedores respaldadas"
fi

# ============================================
# USUARIOS Y PERMISOS
# ============================================
log "Respaldando usuarios y permisos..."

pveum user list > "$BACKUP_BASE/users.txt" 2>&1
pveum acl list > "$BACKUP_BASE/acl.txt" 2>&1
pveum group list > "$BACKUP_BASE/groups.txt" 2>&1 || true
pveum pool list > "$BACKUP_BASE/pools.txt" 2>&1 || true

if [ -f /etc/pve/user.cfg ]; then
    cp /etc/pve/user.cfg "$BACKUP_BASE/user.cfg.backup"
fi

log "✓ Usuarios y permisos respaldados"

# ============================================
# STORAGE
# ============================================
log "Información de storage..."

pvesm status > "$BACKUP_BASE/storage-status.txt" 2>&1

# LVM
pvs > "$BACKUP_BASE/lvm-pvs.txt" 2>&1 || echo "No LVM PVs" > "$BACKUP_BASE/lvm-pvs.txt"
vgs > "$BACKUP_BASE/lvm-vgs.txt" 2>&1 || echo "No LVM VGs" > "$BACKUP_BASE/lvm-vgs.txt"
lvs > "$BACKUP_BASE/lvm-lvs.txt" 2>&1 || echo "No LVM LVs" > "$BACKUP_BASE/lvm-lvs.txt"

# ZFS (si aplica)
if command -v zpool &> /dev/null; then
    zpool list > "$BACKUP_BASE/zfs-pools.txt" 2>&1 || true
    zfs list > "$BACKUP_BASE/zfs-datasets.txt" 2>&1 || true
fi

log "✓ Información de storage guardada"

# ============================================
# CRONTAB Y SCRIPTS PERSONALIZADOS
# ============================================
log "Respaldando crontab..."

crontab -l > "$BACKUP_BASE/root-crontab.txt" 2>/dev/null || echo "No crontab" > "$BACKUP_BASE/root-crontab.txt"
[ -f /etc/crontab ] && cp /etc/crontab "$BACKUP_BASE/etc-crontab.backup"

log "✓ Crontab respaldado"

# ============================================
# CERTIFICADOS SSL
# ============================================
log "Respaldando certificados SSL..."

mkdir -p "$BACKUP_BASE/ssl"
if [ -f /etc/pve/local/pveproxy-ssl.pem ]; then
    cp /etc/pve/local/pveproxy-ssl.pem "$BACKUP_BASE/ssl/" 2>/dev/null || true
fi
if [ -f /etc/pve/local/pveproxy-ssl.key ]; then
    cp /etc/pve/local/pveproxy-ssl.key "$BACKUP_BASE/ssl/" 2>/dev/null || true
fi

log "✓ Certificados SSL respaldados"

# ============================================
# INFORMACIÓN DEL SISTEMA
# ============================================
log "Recopilando información del sistema..."

cat > "$BACKUP_BASE/system-info.txt" << EOF
Hostname: $(hostname)
Date: $(date)
Proxmox Version: $(pveversion | head -1)
Kernel: $(uname -r)
Uptime: $(uptime)
CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2)
RAM Total: $(free -h | grep Mem | awk '{print $2}')
Discos:
$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT)
EOF

log "✓ Información del sistema guardada"

# ============================================
# CREAR RESUMEN
# ============================================
cat > "$BACKUP_BASE/README.txt" << EOF
========================================
BACKUP PRE-ELIMINACIÓN DE CLUSTER
========================================

Fecha del backup: $(date)
Hostname: $(hostname)
Proxmox Version: $(pveversion | head -1)

ARCHIVOS INCLUIDOS:
===================

Cluster:
- cluster-status.txt - Estado del cluster antes de eliminar
- cluster-nodes.txt - Lista de nodos en el cluster
- corosync.conf.backup - Configuración de corosync

Configuraciones:
- pve-config-full.tar.gz - Backup completo de /etc/pve/
- storage.cfg.backup - Configuración de storage
- datacenter.cfg.backup - Configuración del datacenter
- firewall/ - Configuración del firewall

Red:
- interfaces.backup - /etc/network/interfaces
- ip-addresses.txt - Direcciones IP actuales
- routes.txt - Rutas de red
- bridges.txt - Bridges configurados

VMs y Contenedores:
- vms-list.txt - Lista de todas las VMs
- containers-list.txt - Lista de todos los contenedores
- vm-configs/ - Configuraciones individuales de VMs
- container-configs/ - Configuraciones individuales de contenedores

Usuarios:
- users.txt - Lista de usuarios
- acl.txt - Lista de ACLs
- groups.txt - Lista de grupos
- pools.txt - Lista de pools

Storage:
- storage-status.txt - Estado del storage
- lvm-*.txt - Información de LVM
- zfs-*.txt - Información de ZFS (si aplica)

Otros:
- root-crontab.txt - Crontab del usuario root
- ssl/ - Certificados SSL
- system-info.txt - Información general del sistema
- pve-version.txt - Versión completa de Proxmox

RESTAURACIÓN:
=============

Si necesitas restaurar algo:

1. Configuración de red:
   cp interfaces.backup /etc/network/interfaces
   systemctl restart networking

2. Storage:
   cat storage.cfg.backup > /etc/pve/storage.cfg

3. Usuarios:
   # Usar pveum para recrear usuarios según users.txt

4. Certificados:
   cp ssl/pveproxy-ssl.* /etc/pve/local/

NOTAS IMPORTANTES:
==================

- Este backup NO incluye los datos de las VMs/Contenedores
- Haz backups de VMs/Contenedores por separado con vzdump
- Guarda este directorio en un lugar seguro
- No elimines este backup hasta verificar que el nuevo cluster funciona

EOF

# ============================================
# COMPRIMIR TODO
# ============================================
log "Comprimiendo backup..."

cd "$(dirname "$BACKUP_BASE")"
BACKUP_NAME=$(basename "$BACKUP_BASE")
tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -sh "${BACKUP_NAME}.tar.gz" | awk '{print $1}')
    log "✓ Backup comprimido: ${BACKUP_NAME}.tar.gz ($BACKUP_SIZE)"
    
    # Preguntar si quiere eliminar el directorio sin comprimir
    echo ""
    read -p "¿Eliminar directorio sin comprimir para ahorrar espacio? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        rm -rf "$BACKUP_BASE"
        log "✓ Directorio sin comprimir eliminado"
    fi
fi

# ============================================
# RESUMEN FINAL
# ============================================
echo ""
echo "========================================="
echo "  BACKUP COMPLETADO"
echo "========================================="
echo ""
log "Backup guardado en:"
echo "  - Directorio: $BACKUP_BASE"
if [ -f "${BACKUP_NAME}.tar.gz" ]; then
    echo "  - Comprimido: ${BACKUP_NAME}.tar.gz"
fi
echo ""
log "Archivos importantes respaldados:"
echo "  ✓ Configuración del cluster"
echo "  ✓ Configuración de VMs ($VM_COUNT VMs)"
echo "  ✓ Configuración de Contenedores ($CT_COUNT CTs)"
echo "  ✓ Configuración de red"
echo "  ✓ Usuarios y permisos"
echo "  ✓ Storage configuration"
echo ""
warning "RECUERDA:"
echo "  1. Este backup NO incluye los datos de las VMs/CTs"
echo "  2. Haz backup de VMs/CTs con: vzdump --all"
echo "  3. Guarda este backup en un lugar seguro"
echo "  4. Copia a tu máquina local con:"
echo "     scp root@$(hostname -I | awk '{print $1}'):${BACKUP_NAME}.tar.gz ."
echo ""
log "Para continuar con la eliminación del cluster:"
echo "  Consulta: docs/cluster-recreation-guide.md"
echo ""

# Guardar ubicación del backup en archivo temporal
echo "$BACKUP_BASE" > /tmp/last-cluster-backup-location.txt
if [ -f "${BACKUP_NAME}.tar.gz" ]; then
    echo "${BACKUP_NAME}.tar.gz" >> /tmp/last-cluster-backup-location.txt
fi

log "Backup completado exitosamente"
