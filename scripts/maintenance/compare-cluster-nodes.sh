#!/bin/bash
#
# Script de Comparación de Nodos en Cluster Proxmox
# 
# Compara las especificaciones de dos nodos del cluster
# Uso: ./compare-cluster-nodes.sh
#

# Configuración
OUTPUT_FILE="/tmp/cluster-comparison-$(date +%Y%m%d_%H%M%S).txt"

echo "=================================" | tee "$OUTPUT_FILE"
echo "COMPARACIÓN DE NODOS DEL CLUSTER" | tee -a "$OUTPUT_FILE"
echo "=================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Verificar que estamos en un cluster
if ! pvecm status &>/dev/null; then
    echo "ERROR: Este servidor no está en un cluster Proxmox" | tee -a "$OUTPUT_FILE"
    echo "Este script debe ejecutarse desde un nodo del cluster" | tee -a "$OUTPUT_FILE"
    exit 1
fi

echo "=== INFORMACIÓN DEL CLUSTER ===" | tee -a "$OUTPUT_FILE"
pvecm status | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo "=== NODOS DEL CLUSTER ===" | tee -a "$OUTPUT_FILE"
pvecm nodes | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Obtener lista de nodos
NODES=$(pvesh get /nodes --output-format=json | grep -oP '"node"\s*:\s*"\K[^"]+')

echo "=== COMPARACIÓN DE ESPECIFICACIONES ===" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Crear tabla de comparación
printf "%-20s | %-30s | %-30s\n" "Especificación" "Nodo 1" "Nodo 2" | tee -a "$OUTPUT_FILE"
printf "%-20s-+-%-30s-+-%-30s\n" "--------------------" "------------------------------" "------------------------------" | tee -a "$OUTPUT_FILE"

# Arrays para almacenar datos de cada nodo
NODE_NAMES=()
NODE_DATA=()

for node in $NODES; do
    NODE_NAMES+=("$node")
    
    # Obtener información del nodo vía API
    cpu_model=$(ssh "$node" "grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs")
    cpu_cores=$(ssh "$node" "grep -c ^processor /proc/cpuinfo")
    ram_total=$(ssh "$node" "grep MemTotal /proc/meminfo | awk '{print \$2/1024/1024 \" GB\"}'")
    kernel=$(ssh "$node" "uname -r")
    pve_version=$(ssh "$node" "pveversion | head -1 | awk '{print \$2}'")
    
    NODE_DATA+=("$cpu_model|$cpu_cores|$ram_total|$kernel|$pve_version")
done

# Mostrar comparación
if [ ${#NODE_NAMES[@]} -ge 2 ]; then
    # CPU Model
    IFS='|' read -ra DATA1 <<< "${NODE_DATA[0]}"
    IFS='|' read -ra DATA2 <<< "${NODE_DATA[1]}"
    
    printf "%-20s | %-30s | %-30s\n" "CPU Modelo" "${DATA1[0]:0:30}" "${DATA2[0]:0:30}" | tee -a "$OUTPUT_FILE"
    printf "%-20s | %-30s | %-30s\n" "CPU Cores" "${DATA1[1]}" "${DATA2[1]}" | tee -a "$OUTPUT_FILE"
    printf "%-20s | %-30s | %-30s\n" "RAM Total" "${DATA1[2]}" "${DATA2[2]}" | tee -a "$OUTPUT_FILE"
    printf "%-20s | %-30s | %-30s\n" "Kernel" "${DATA1[3]}" "${DATA2[3]}" | tee -a "$OUTPUT_FILE"
    printf "%-20s | %-30s | %-30s\n" "Proxmox VE" "${DATA1[4]}" "${DATA2[4]}" | tee -a "$OUTPUT_FILE"
fi

echo "" | tee -a "$OUTPUT_FILE"
echo "=== RECURSOS EN USO POR NODO ===" | tee -a "$OUTPUT_FILE"
for node in $NODES; do
    echo "" | tee -a "$OUTPUT_FILE"
    echo "--- Nodo: $node ---" | tee -a "$OUTPUT_FILE"
    pvesh get /nodes/$node/status | tee -a "$OUTPUT_FILE"
done

echo "" | tee -a "$OUTPUT_FILE"
echo "Comparación guardada en: $OUTPUT_FILE"
echo ""
echo "Para obtener un reporte detallado de cada nodo, ejecuta:"
echo "  ssh nodo1 'bash collect-system-info.sh'"
echo "  ssh nodo2 'bash collect-system-info.sh'"
