#!/bin/bash
#
# Script de Recopilación de Información del Sistema Proxmox
# 
# Recopila información detallada de hardware y configuración
# para documentar las especificaciones del servidor
# Uso: ./collect-system-info.sh
#

set -e

# Configuración
OUTPUT_DIR="/tmp/proxmox-system-info"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$OUTPUT_DIR/system-report-$TIMESTAMP.txt"

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

# Función de escritura
write_section() {
    echo "" | tee -a "$REPORT_FILE"
    echo "========================================" | tee -a "$REPORT_FILE"
    echo "$1" | tee -a "$REPORT_FILE"
    echo "========================================" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
}

# Iniciar reporte
echo "Generando reporte del sistema..." | tee "$REPORT_FILE"
echo "Fecha: $(date)" | tee -a "$REPORT_FILE"
echo "Hostname: $(hostname)" | tee -a "$REPORT_FILE"

# ============================================
# INFORMACIÓN GENERAL DEL SISTEMA
# ============================================
write_section "INFORMACIÓN GENERAL DEL SISTEMA"

echo "=== Hostname ===" | tee -a "$REPORT_FILE"
hostname | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Versión de Proxmox ===" | tee -a "$REPORT_FILE"
pveversion -v | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Sistema Operativo ===" | tee -a "$REPORT_FILE"
cat /etc/os-release | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Kernel ===" | tee -a "$REPORT_FILE"
uname -a | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Uptime ===" | tee -a "$REPORT_FILE"
uptime | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ============================================
# INFORMACIÓN DE HARDWARE
# ============================================
write_section "INFORMACIÓN DE HARDWARE"

echo "=== Información General del Hardware ===" | tee -a "$REPORT_FILE"
dmidecode -t system | grep -E "Manufacturer|Product Name|Serial Number|UUID" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== BIOS ===" | tee -a "$REPORT_FILE"
dmidecode -t bios | grep -E "Vendor|Version|Release Date" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ============================================
# PROCESADOR (CPU)
# ============================================
write_section "INFORMACIÓN DEL PROCESADOR"

echo "=== CPU Detallada ===" | tee -a "$REPORT_FILE"
lscpu | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Modelo y Cantidad ===" | tee -a "$REPORT_FILE"
grep "model name" /proc/cpuinfo | uniq | tee -a "$REPORT_FILE"
echo "Cores físicos: $(grep -c ^processor /proc/cpuinfo)" | tee -a "$REPORT_FILE"
echo "Sockets: $(lscpu | grep "Socket(s):" | awk '{print $2}')" | tee -a "$REPORT_FILE"
echo "Cores por socket: $(lscpu | grep "Core(s) per socket:" | awk '{print $4}')" | tee -a "$REPORT_FILE"
echo "Threads por core: $(lscpu | grep "Thread(s) per core:" | awk '{print $4}')" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Flags de CPU (Virtualización) ===" | tee -a "$REPORT_FILE"
grep -o 'vmx\|svm' /proc/cpuinfo | sort | uniq | tee -a "$REPORT_FILE"
if grep -q vmx /proc/cpuinfo; then
    echo "Virtualización Intel (VT-x): HABILITADA" | tee -a "$REPORT_FILE"
elif grep -q svm /proc/cpuinfo; then
    echo "Virtualización AMD (AMD-V): HABILITADA" | tee -a "$REPORT_FILE"
else
    echo "ADVERTENCIA: Virtualización NO detectada" | tee -a "$REPORT_FILE"
fi
echo "" | tee -a "$REPORT_FILE"

# ============================================
# MEMORIA RAM
# ============================================
write_section "INFORMACIÓN DE MEMORIA RAM"

echo "=== Resumen de Memoria ===" | tee -a "$REPORT_FILE"
free -h | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Memoria Total ===" | tee -a "$REPORT_FILE"
grep MemTotal /proc/meminfo | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Módulos de RAM Instalados ===" | tee -a "$REPORT_FILE"
dmidecode -t memory | grep -E "Size:|Speed:|Type:|Manufacturer|Part Number|Serial Number" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Slots de Memoria ===" | tee -a "$REPORT_FILE"
dmidecode -t memory | grep -E "Number Of Devices|Maximum Capacity" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ============================================
# DISCOS Y ALMACENAMIENTO
# ============================================
write_section "INFORMACIÓN DE DISCOS Y ALMACENAMIENTO"

echo "=== Lista de Discos (lsblk) ===" | tee -a "$REPORT_FILE"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,SERIAL | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Detalles de Discos (fdisk) ===" | tee -a "$REPORT_FILE"
fdisk -l | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Información SMART de Discos ===" | tee -a "$REPORT_FILE"
if command -v smartctl &> /dev/null; then
    for disk in $(lsblk -d -o NAME | grep -E "sd|nvme" | grep -v "NAME"); do
        echo "--- Disco /dev/$disk ---" | tee -a "$REPORT_FILE"
        smartctl -i /dev/$disk 2>/dev/null | grep -E "Device Model|Serial Number|User Capacity|Rotation Rate" | tee -a "$REPORT_FILE"
        echo "" | tee -a "$REPORT_FILE"
    done
else
    echo "smartctl no está instalado. Instalar con: apt install smartmontools" | tee -a "$REPORT_FILE"
fi
echo "" | tee -a "$REPORT_FILE"

echo "=== Uso de Espacio en Disco ===" | tee -a "$REPORT_FILE"
df -h | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ============================================
# LVM / ZFS
# ============================================
write_section "INFORMACIÓN DE VOLÚMENES LÓGICOS"

echo "=== Physical Volumes (PV) ===" | tee -a "$REPORT_FILE"
pvs | tee -a "$REPORT_FILE"
pvdisplay | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Volume Groups (VG) ===" | tee -a "$REPORT_FILE"
vgs | tee -a "$REPORT_FILE"
vgdisplay | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Logical Volumes (LV) ===" | tee -a "$REPORT_FILE"
lvs | tee -a "$REPORT_FILE"
lvdisplay | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if command -v zpool &> /dev/null; then
    echo "=== ZFS Pools ===" | tee -a "$REPORT_FILE"
    zpool list | tee -a "$REPORT_FILE"
    zpool status | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    echo "=== ZFS Datasets ===" | tee -a "$REPORT_FILE"
    zfs list | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

# ============================================
# GPU / TARJETAS GRÁFICAS
# ============================================
write_section "INFORMACIÓN DE GPU / TARJETAS GRÁFICAS"

echo "=== Tarjetas PCI (lspci) ===" | tee -a "$REPORT_FILE"
lspci | grep -i vga | tee -a "$REPORT_FILE"
lspci | grep -i 3d | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Detalles de GPU ===" | tee -a "$REPORT_FILE"
lspci -v | grep -A 10 -i vga | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if command -v nvidia-smi &> /dev/null; then
    echo "=== NVIDIA GPU (nvidia-smi) ===" | tee -a "$REPORT_FILE"
    nvidia-smi | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

echo "=== Todos los dispositivos PCI ===" | tee -a "$REPORT_FILE"
lspci -nn | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ============================================
# RED / NETWORKING
# ============================================
write_section "INFORMACIÓN DE RED"

echo "=== Interfaces de Red ===" | tee -a "$REPORT_FILE"
ip addr show | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Configuración de Red (/etc/network/interfaces) ===" | tee -a "$REPORT_FILE"
cat /etc/network/interfaces | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Rutas de Red ===" | tee -a "$REPORT_FILE"
ip route show | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Tarjetas de Red (Hardware) ===" | tee -a "$REPORT_FILE"
lspci | grep -i ethernet | tee -a "$REPORT_FILE"
lspci | grep -i network | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Detalles de Interfaces de Red ===" | tee -a "$REPORT_FILE"
for iface in $(ls /sys/class/net/ | grep -v lo); do
    echo "--- Interfaz: $iface ---" | tee -a "$REPORT_FILE"
    ethtool "$iface" 2>/dev/null | grep -E "Speed|Duplex|Link detected" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
done

echo "=== Bridges ===" | tee -a "$REPORT_FILE"
brctl show 2>/dev/null || ip link show type bridge | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ============================================
# USB Y OTROS DISPOSITIVOS
# ============================================
write_section "DISPOSITIVOS USB Y OTROS"

echo "=== Dispositivos USB ===" | tee -a "$REPORT_FILE"
lsusb | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Todos los dispositivos Hardware ===" | tee -a "$REPORT_FILE"
lshw -short | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ============================================
# CONFIGURACIÓN DE PROXMOX
# ============================================
write_section "CONFIGURACIÓN DE PROXMOX"

echo "=== Almacenamiento Configurado ===" | tee -a "$REPORT_FILE"
pvesm status | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Storage.cfg ===" | tee -a "$REPORT_FILE"
cat /etc/pve/storage.cfg | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== VMs Configuradas ===" | tee -a "$REPORT_FILE"
qm list | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Contenedores Configurados ===" | tee -a "$REPORT_FILE"
pct list | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "=== Usuarios de Proxmox ===" | tee -a "$REPORT_FILE"
pveum user list | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Si hay cluster
if [ -f /etc/pve/corosync.conf ]; then
    echo "=== Configuración de Cluster ===" | tee -a "$REPORT_FILE"
    pvecm status | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    echo "=== Nodos del Cluster ===" | tee -a "$REPORT_FILE"
    pvecm nodes | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

# ============================================
# RENDIMIENTO DEL SISTEMA
# ============================================
write_section "RENDIMIENTO DEL SISTEMA"

echo "=== Benchmark de Proxmox ===" | tee -a "$REPORT_FILE"
pveperf | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ============================================
# SENSORES Y TEMPERATURA
# ============================================
write_section "SENSORES Y TEMPERATURA"

if command -v sensors &> /dev/null; then
    echo "=== Temperaturas ===" | tee -a "$REPORT_FILE"
    sensors | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
else
    echo "lm-sensors no está instalado. Instalar con: apt install lm-sensors && sensors-detect" | tee -a "$REPORT_FILE"
fi

# ============================================
# SERVICIOS Y PROCESOS
# ============================================
write_section "SERVICIOS DE PROXMOX"

echo "=== Estado de Servicios Proxmox ===" | tee -a "$REPORT_FILE"
for service in pve-cluster pvedaemon pveproxy pvestatd pve-firewall; do
    echo "--- $service ---" | tee -a "$REPORT_FILE"
    systemctl status "$service" --no-pager | head -n 5 | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
done

# ============================================
# FINALIZAR
# ============================================
write_section "REPORTE COMPLETADO"

echo "Reporte guardado en: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "Para copiar el reporte a tu máquina local, usa:" | tee -a "$REPORT_FILE"
echo "scp root@$(hostname -I | awk '{print $1}'):$REPORT_FILE ." | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Crear también versión HTML (opcional)
echo "Generando versión HTML..."
{
    echo "<html><head><title>Reporte del Sistema - $(hostname)</title>"
    echo "<style>body{font-family:monospace;margin:20px;} h2{color:#007bff;border-bottom:2px solid #007bff;} pre{background:#f5f5f5;padding:10px;overflow:auto;}</style>"
    echo "</head><body>"
    echo "<h1>Reporte del Sistema Proxmox - $(hostname)</h1>"
    echo "<p>Generado: $(date)</p>"
    echo "<pre>"
    cat "$REPORT_FILE"
    echo "</pre>"
    echo "</body></html>"
} > "$OUTPUT_DIR/system-report-$TIMESTAMP.html"

echo ""
echo "============================================"
echo "Reporte completado exitosamente!"
echo "============================================"
echo ""
echo "Archivos generados:"
echo "  - Texto: $REPORT_FILE"
echo "  - HTML:  $OUTPUT_DIR/system-report-$TIMESTAMP.html"
echo ""
echo "Para visualizar:"
echo "  less $REPORT_FILE"
echo "  firefox $OUTPUT_DIR/system-report-$TIMESTAMP.html"
echo ""
