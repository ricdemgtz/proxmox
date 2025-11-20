#!/bin/bash
# Guía rápida de comandos para completar configuración de Uptime Kuma
# Fecha: 2025-11-19

# ============================================================================
# PASO 1: EJECUTAR SCRIPT DE SINCRONIZACIÓN
# ============================================================================

echo "=== Ejecutando sincronización de monitores LXC 105 → 205 ==="

# Opción 1: Si ya tienes el script en /root/sync-uptimekuma.sh
/root/sync-uptimekuma.sh

# Verificar log
tail -50 /var/log/uptimekuma-sync.log

# Opción 2: Si el script está en otra ubicación
# bash /ruta/al/script/sync-uptimekuma.sh

echo "✅ Sincronización completada"
echo ""

# ============================================================================
# PASO 2: DESACTIVAR ALERTAS EN LXC 205 (BACKUP)
# ============================================================================

echo "=== Para desactivar alertas en el backup (LXC 205) ==="
echo ""
echo "OPCIÓN A - Vía Web UI (recomendado):"
echo "1. Abrir http://192.168.1.71:3001"
echo "2. Ir a Settings → Notifications"
echo "3. Para cada notificación (Telegram, n8n):"
echo "   - Click en el nombre de la notificación"
echo "   - Click en 'Disable' o desactivar"
echo "   - Alternativamente: eliminar de 'Apply on all existing monitors'"
echo ""
echo "OPCIÓN B - Pausar todos los monitores:"
echo "1. Abrir http://192.168.1.71:3001"
echo "2. Para cada grupo de monitores:"
echo "   - Click en el grupo"
echo "   - Click en botón 'Pause' (icono de pausa)"
echo "   - Confirmar"
echo ""
echo "NOTA: Esto evita alertas duplicadas mientras LXC 105 esté activo"
echo ""

# ============================================================================
# PASO 3: VERIFICAR CONFIGURACIÓN DE n8n EN PRODUCCIÓN
# ============================================================================

echo "=== Configurar webhook n8n en producción ==="
echo ""
echo "1. Abrir Uptime Kuma principal: http://192.168.1.70:3001"
echo "2. Ir a Settings → Notifications"
echo "3. Buscar notificación 'n8n' o 'webhook'"
echo "4. Verificar que la URL del webhook apunte a tu instancia de producción"
echo "   Ejemplo: https://n8n.tudominio.com/webhook/uptime-kuma"
echo "5. Configurar headers si es necesario (Authorization, etc.)"
echo "6. Click en 'Test' para verificar que funciona"
echo "7. Guardar cambios"
echo ""

# ============================================================================
# PASO 4: VERIFICACIÓN FINAL DE SERVICIOS
# ============================================================================

echo "=== Verificación final de todos los servicios ==="
echo ""

# Verificar LXC 105 (principal)
echo "--- LXC 105 (Principal) ---"
pct status 105
pct exec 105 -- systemctl status uptime-kuma --no-pager | head -5
echo ""

# Verificar LXC 205 (backup)
echo "--- LXC 205 (Backup) ---"
ssh root@192.168.1.82 "pct status 205"
ssh root@192.168.1.82 "pct exec 205 -- systemctl status uptime-kuma --no-pager | head -5"
echo ""

# Verificar acceso web
echo "--- Verificando acceso web ---"
echo "Principal: curl -s -o /dev/null -w '%{http_code}' http://192.168.1.70:3001"
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.1.70:3001

echo "Backup: curl -s -o /dev/null -w '%{http_code}' http://192.168.1.71:3001"
ssh root@192.168.1.82 "curl -s -o /dev/null -w '%{http_code}\n' http://192.168.1.71:3001"
echo ""

echo "✅ Verificación completada"
echo ""

# ============================================================================
# RESUMEN DE URLS Y ACCESOS
# ============================================================================

cat << 'EOF'

📊 RESUMEN DE CONFIGURACIÓN UPTIME KUMA
========================================

Instancia Principal (LXC 105):
  - IP Local: http://192.168.1.70:3001
  - IP Tailscale: http://100.101.238.45:3001
  - Nodo: proxmox (192.168.1.78)
  - Alertas: ACTIVADAS (Telegram + n8n)
  - Sincronización: Cron diario

Instancia Backup (LXC 205):
  - IP Local: http://192.168.1.71:3001
  - Nodo: proxmedia (192.168.1.82)
  - Alertas: DESACTIVADAS (standby)
  - Sincronización: Recibe datos del principal

Monitores Totales: 24
  - HTTP(s): 12
  - Ping: 4
  - TCP Port: 2
  - DNS: 1
  - Grupos: 6

Servicios Críticos Monitoreados:
  ✓ Cloudflared (9090/metrics)
  ✓ AdGuard DNS (53)
  ✓ Proxmox Nodes (78, 82)
  ✓ Media Stack (Jellyfin, *arr)
  ✓ Vaultwarden
  ✓ Immich

PRÓXIMOS PASOS:
1. ✅ Ejecutar sincronización (completado arriba)
2. ⏳ Desactivar alertas en LXC 205 (manual vía web)
3. ⏳ Verificar webhook n8n apunta a producción
4. ✅ Verificación final de servicios (completado arriba)

EOF
