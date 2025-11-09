#!/bin/bash
#
# Script de Monitoreo de Recursos de Proxmox
# 
# Monitorea CPU, RAM, disco y estado de VMs/Contenedores
# Uso: ./monitor-resources.sh
#

# Configuración
ALERT_CPU_THRESHOLD=80      # Porcentaje de CPU
ALERT_RAM_THRESHOLD=85      # Porcentaje de RAM
ALERT_DISK_THRESHOLD=90     # Porcentaje de disco
LOG_FILE="/var/log/proxmox-monitoring.log"

# Función de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Función para enviar alertas (personalizar según necesidad)
send_alert() {
    local message=$1
    log "ALERTA: $message"
    # Aquí puedes agregar integración con email, Telegram, Discord, etc.
    # Ejemplo para email:
    # echo "$message" | mail -s "Alerta Proxmox" admin@example.com
}

# Monitoreo de CPU
check_cpu() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    cpu_usage=${cpu_usage%.*}  # Convertir a entero
    
    log "Uso de CPU: ${cpu_usage}%"
    
    if [ "$cpu_usage" -gt "$ALERT_CPU_THRESHOLD" ]; then
        send_alert "Uso de CPU alto: ${cpu_usage}%"
    fi
}

# Monitoreo de RAM
check_ram() {
    local ram_usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    
    log "Uso de RAM: ${ram_usage}%"
    
    if [ "$ram_usage" -gt "$ALERT_RAM_THRESHOLD" ]; then
        send_alert "Uso de RAM alto: ${ram_usage}%"
    fi
}

# Monitoreo de Disco
check_disk() {
    log "=== Estado de Discos ==="
    
    df -h | grep -E '^/dev/' | while read line; do
        local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local mount=$(echo "$line" | awk '{print $6}')
        local disk=$(echo "$line" | awk '{print $1}')
        
        log "Disco $disk montado en $mount: ${usage}%"
        
        if [ "$usage" -gt "$ALERT_DISK_THRESHOLD" ]; then
            send_alert "Uso de disco alto en $mount: ${usage}%"
        fi
    done
}

# Monitoreo de VMs
check_vms() {
    log "=== Estado de VMs ==="
    
    qm list | tail -n +2 | while read line; do
        local vmid=$(echo "$line" | awk '{print $1}')
        local status=$(echo "$line" | awk '{print $3}')
        local name=$(echo "$line" | awk '{print $2}')
        
        log "VM $vmid ($name): $status"
        
        # Aquí puedes agregar lógica adicional, por ejemplo:
        # - Alertar si una VM crítica está detenida
        # - Monitorear recursos específicos de la VM
    done
}

# Monitoreo de Contenedores
check_containers() {
    log "=== Estado de Contenedores ==="
    
    pct list | tail -n +2 | while read line; do
        local ctid=$(echo "$line" | awk '{print $1}')
        local status=$(echo "$line" | awk '{print $2}')
        local name=$(echo "$line" | awk '{print $3}')
        
        log "CT $ctid ($name): $status"
    done
}

# Verificar servicios de Proxmox
check_services() {
    log "=== Estado de Servicios Proxmox ==="
    
    local services=("pve-cluster" "pvedaemon" "pveproxy" "pvestatd")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log "Servicio $service: ACTIVO"
        else
            log "Servicio $service: INACTIVO"
            send_alert "Servicio crítico $service está inactivo"
        fi
    done
}

# Función principal
main() {
    log "===== Iniciando monitoreo de Proxmox ====="
    
    check_cpu
    check_ram
    check_disk
    check_vms
    check_containers
    check_services
    
    log "===== Monitoreo completado ====="
    echo ""  # Línea en blanco para separar ejecuciones
}

# Ejecutar
main
