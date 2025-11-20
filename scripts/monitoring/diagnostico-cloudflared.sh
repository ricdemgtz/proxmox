#!/bin/bash
# Script de diagnóstico para Cloudflared en LXC 100

set -e

LOG_FILE="/var/log/cloudflared-diagnostico.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "===== Diagnóstico de Cloudflared en LXC 100 ====="

# Verificar que el LXC está corriendo
log "Verificando estado del LXC 100..."
pct status 100

# Verificar contenedores Docker en LXC 100
log "Verificando contenedores Docker..."
pct exec 100 -- docker ps -a

# Buscar proceso cloudflared
log "Buscando procesos cloudflared..."
pct exec 100 -- ps aux | grep cloudflared || log "No se encontró proceso cloudflared"

# Verificar puertos en uso
log "Verificando puertos abiertos..."
pct exec 100 -- ss -tlnp | grep -E ':(2000|8080|7844)' || log "Puertos cloudflared no encontrados"

# Verificar logs de Docker si cloudflared está en contenedor
log "Intentando obtener logs de contenedor cloudflared..."
pct exec 100 -- docker logs cloudflared --tail 50 2>/dev/null || log "Contenedor cloudflared no encontrado o no accesible"

# Verificar configuración de cloudflared
log "Buscando configuración de cloudflared..."
pct exec 100 -- find /opt /etc /root -name "*cloudflare*" -o -name "*cloudflared*" 2>/dev/null || log "No se encontró configuración"

log "===== Fin del diagnóstico ====="
