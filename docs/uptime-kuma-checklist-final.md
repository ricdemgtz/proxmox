# Checklist Final - Configuración Uptime Kuma

**Fecha**: 2025-11-19  
**Estado**: Tareas pendientes de ejecución

---

## ✅ Completado

- [x] Crear script de sincronización de monitores
- [x] Agregar script al crontab
- [x] Documentar todos los monitores en `uptime-kuma-monitors.md`
- [x] Resolver issues del documento de fix
- [x] Identificar errores en monitores (Cloudflared, AdGuard)
- [x] Documentar soluciones en `uptime-kuma-fix-errors.md`
- [x] Crear scripts de diagnóstico
- [x] Actualizar documentación con correcciones

---

## 🔧 TAREAS PENDIENTES (Ejecutar en servidor)

### 1. Fix Cloudflared Health Check ⚠️ CRÍTICO

**Problema**: Monitor marca error `ECONNREFUSED 192.168.1.100:2000`  
**Causa**: Puerto incorrecto (debe ser 9090, no 2000)

**Pasos a ejecutar**:

```bash
# 1. SSH al nodo proxmox
ssh root@192.168.1.78

# 2. Entrar al LXC 100
pct enter 100

# 3. Ir al directorio del docker-compose del stack proxy
cd /opt/docker/proxy  # Ajustar según tu ubicación real

# 4. Editar docker-compose.yml
nano docker-compose.yml

# 5. Buscar la sección de cloudflared y CAMBIAR:
#    De:  - "127.0.0.1:9090:9090"
#    A:   - "192.168.1.100:9090:9090"

# 6. Guardar (Ctrl+O, Enter, Ctrl+X)

# 7. Recrear el contenedor
docker compose down cloudflared
docker compose up -d cloudflared

# 8. Verificar que está corriendo
docker ps | grep cloudflared

# 9. Verificar puerto
ss -tlnp | grep 9090
# Debe mostrar: 192.168.1.100:9090

# 10. Test del endpoint
curl http://192.168.1.100:9090/metrics
# Debe mostrar métricas de Prometheus

# 11. Salir del LXC
exit
```

**Luego, actualizar en Uptime Kuma**:
1. Ir a http://192.168.1.70:3001
2. Buscar monitor "Cloudflared - Health Check"
3. Editar:
   - URL: `http://192.168.1.100:9090/ready`
   - Tipo: HTTP(s)
   - Códigos aceptados: 200-299
4. Guardar
5. Verificar que marca OK

---

### 2. Fix AdGuard DNS Resolver ⚠️ CRÍTICO

**Problema**: Monitor marca error `queryA ETIMEOUT google.com`  
**Causa**: **Firewall de Proxmox bloqueando puerto 53**

**Diagnóstico confirmado**:
- ✅ Servicio AdGuard corriendo
- ✅ Puerto 53 escuchando
- ✅ Ping funciona
- ❌ DNS queries hacen TIMEOUT → **Firewall bloqueando**

**Solución - Opción A: Script Automatizado** (Recomendado):

```bash
# 1. SSH al nodo proxmox
ssh root@192.168.1.78

# 2. Ejecutar script de fix
bash /root/scripts/monitoring/fix-adguard-firewall.sh

# 3. Verificar log
tail -50 /var/log/adguard-firewall-fix.log

# 4. Probar DNS
dig @192.168.1.120 google.com +short
# Debe devolver IPs
```

**Solución - Opción B: Manual**:

```bash
# 1. SSH al nodo proxmox
ssh root@192.168.1.78

# 2. Crear reglas de firewall para LXC 103
nano /etc/pve/firewall/103.fw
```

Agregar este contenido:
```conf
[OPTIONS]
enable: 1

[RULES]
# AdGuard Home - DNS
IN ACCEPT -p udp -dport 53 -log nolog -source +datacenter
IN ACCEPT -p tcp -dport 53 -log nolog -source +datacenter

# AdGuard Home - Web Interface
IN ACCEPT -p tcp -dport 80 -log nolog -source +datacenter

# ICMP (ping)
IN ACCEPT -p icmp -log nolog
```

```bash
# 3. Aplicar cambios
pve-firewall restart

# 4. Esperar y probar
sleep 3
dig @192.168.1.120 google.com +short
```

**Ajustar monitor en Uptime Kuma** (si es necesario):
1. Ir a http://192.168.1.70:3001
2. Buscar monitor "AdGuard DNS Resolver"
3. Editar:
   - Intervalo: 60s (en vez de 30s)
   - Timeout: 10s
   - Reintentos: 2
4. Guardar

**Documentación completa**: Ver `docs/adguard-firewall-fix.md`

---

### 3. Sincronizar Monitores LXC 105 → 205 📋

**Objetivo**: Copiar todos los nuevos monitores al backup

```bash
# 1. SSH al nodo proxmox
ssh root@192.168.1.78

# 2. Ejecutar script de sincronización
/root/sync-uptimekuma.sh

# 3. Verificar log
tail -50 /var/log/uptimekuma-sync.log

# 4. Verificar que ambas instancias están corriendo
pct status 105
ssh root@192.168.1.82 "pct status 205"

# 5. Acceder a ambas vía web y verificar monitores
# Principal: http://192.168.1.70:3001
# Backup: http://192.168.1.71:3001
```

---

### 4. Desactivar Alertas en LXC 205 (Backup) 🔕

**Objetivo**: Evitar alertas duplicadas del servidor de backup

**Método Recomendado - Vía Web UI**:

1. Abrir http://192.168.1.71:3001 (LXC 205 backup)
2. Login con las mismas credenciales de LXC 105
3. Ir a **Settings** → **Notifications**
4. Para la notificación de **Telegram**:
   - Click en el nombre
   - Click en botón **"Disable"** o switch para desactivar
   - O eliminar de "Apply on all existing monitors"
5. Para la notificación de **n8n webhook**:
   - Repetir el mismo proceso
6. Guardar cambios

**Verificación**:
- Provocar una alerta en un monitor del backup
- Confirmar que NO recibes notificación de Telegram
- Las alertas solo deben venir del LXC 105 (principal)

**Alternativa - Pausar monitores**:
- Ir a cada grupo de monitores
- Click en botón "Pause"
- Esto pausa temporalmente sin borrar configuración

---

### 5. Actualizar Webhook n8n a Producción 🔔

**Objetivo**: Configurar n8n webhook con URL de producción

**Pasos**:

1. Abrir http://192.168.1.70:3001 (LXC 105 principal)
2. Ir a **Settings** → **Notifications**
3. Buscar notificación **"n8n"** o **"webhook"**
4. Click en el nombre para editar
5. Actualizar configuración:
   - **Webhook URL**: Cambiar a tu URL de producción
     - Ejemplo: `https://n8n.tudominio.com/webhook/uptime-kuma`
     - O IP: `http://192.168.1.XXX:5678/webhook/uptime-kuma`
   - **Method**: POST
   - **Content Type**: application/json
   - **Headers** (si requiere auth):
     ```
     Authorization: Bearer tu-token-aqui
     ```
6. Click en **"Test"** para verificar que funciona
7. Deberías recibir confirmación en n8n
8. **Save** para guardar cambios

**Verificación en n8n**:
- Ir a tu workflow en n8n
- Verificar que el webhook node recibió el test
- Confirmar que el payload tiene el formato correcto

---

## 📊 Verificación Final

Una vez completadas todas las tareas, ejecutar:

```bash
# Verificar servicios
pct exec 100 -- docker ps | grep cloudflared
pct exec 103 -- systemctl status AdGuardHome --no-pager
pct exec 105 -- systemctl status uptime-kuma --no-pager
ssh root@192.168.1.82 "pct exec 205 -- systemctl status uptime-kuma --no-pager"

# Verificar puertos
pct exec 100 -- ss -tlnp | grep 9090
pct exec 103 -- ss -ulnp | grep ':53'

# Verificar acceso web
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.1.70:3001  # Debe devolver 200
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.1.71:3001  # Debe devolver 200
```

**Checklist visual en Uptime Kuma**:
- [ ] Todos los monitores en verde (UP)
- [ ] No hay errores de conexión
- [ ] Notificaciones de Telegram funcionando (en LXC 105)
- [ ] Notificaciones de n8n funcionando (en LXC 105)
- [ ] NO llegan notificaciones de LXC 205 (backup)
- [ ] Ambas instancias sincronizadas

---

## 🎯 Orden de Ejecución Recomendado

1. **Primero**: Fix Cloudflared (2 minutos)
2. **Segundo**: Fix AdGuard DNS (2 minutos)
3. **Tercero**: Sincronizar LXC 105 → 205 (1 minuto)
4. **Cuarto**: Desactivar alertas en LXC 205 (1 minuto)
5. **Quinto**: Configurar n8n webhook (2 minutos)
6. **Final**: Verificación completa (2 minutos)

**Tiempo total estimado**: ~10 minutos

---

## 📝 Notas Importantes

- **Cloudflared**: El puerto correcto es **9090** (métricas), no 2000
- **AdGuard**: Si persisten problemas DNS, cambiar a monitor HTTP en puerto 80
- **Sincronización**: El script debe ejecutarse después de cada cambio importante en monitores
- **Backup LXC 205**: Mantener monitores sincronizados pero **sin alertas activas**
- **n8n**: Asegurar que el workflow está activo y configurado para recibir webhooks

---

## 🔗 Documentos Relacionados

- `uptime-kuma-fix-errors.md` - Guía detallada de soluciones
- `uptime-kuma-monitors.md` - Documentación completa de monitores
- `uptime-kuma-backup-setup.md` - Configuración del LXC 205 backup
- `scripts/monitoring/completar-setup-uptimekuma.sh` - Script de verificación

---

## ✅ Criterios de Éxito

Al completar todas las tareas:

✅ Todos los monitores en estado UP  
✅ Cero errores de conexión  
✅ Alertas solo desde LXC 105 (principal)  
✅ LXC 205 sincronizado sin alertas  
✅ Webhook n8n recibiendo notificaciones  
✅ Logs sin errores en `/var/log/uptimekuma-sync.log`  

**¡Configuración de Uptime Kuma completada!** 🎉
