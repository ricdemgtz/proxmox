# Fix de Errores - Uptime Kuma

Fecha: 2025-11-19

## 🔴 Errores Detectados

### 1. Cloudflared - Health Check
**Error**: `connect ECONNREFUSED 192.168.1.100:2000`

**Causa**: Puerto incorrecto en el monitor de Uptime Kuma.

**Solución**:

#### Paso 1: Modificar docker-compose.yml del proxy

```bash
# SSH al nodo proxmox
ssh root@192.168.1.78

# Entrar al LXC 100
pct enter 100

# Navegar al directorio del stack (ajustar según tu ubicación)
cd /opt/docker/proxy  # o donde tengas el compose

# Editar el docker-compose.yml
nano docker-compose.yml
```

Cambiar la sección del servicio `cloudflared`:

```yaml
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    environment:
      - TUNNEL_METRICS=0.0.0.0:9090
    dns:
      - 192.168.1.120
      - 1.1.1.1
    ports:
      - "192.168.1.100:9090:9090"  # ← CAMBIAR: antes era 127.0.0.1:9090:9090
    networks:
      - proxy_net
```

#### Paso 2: Recrear el contenedor

```bash
# Dentro del directorio del compose
docker compose down cloudflared
docker compose up -d cloudflared

# Verificar que está corriendo
docker ps | grep cloudflared

# Verificar que el puerto está abierto
ss -tlnp | grep 9090
```

Deberías ver: `192.168.1.100:9090`

#### Paso 3: Verificar endpoint de métricas

```bash
# Desde el nodo proxmox o LXC 100
curl http://192.168.1.100:9090/metrics

# Deberías ver métricas de Prometheus
```

#### Paso 4: Actualizar monitor en Uptime Kuma

1. Ir a Uptime Kuma: http://192.168.1.70:3001
2. Buscar monitor **"Cloudflared - Health Check"**
3. Editar y cambiar:
   - **URL**: `http://192.168.1.100:9090/ready` (o `/metrics`)
   - **Tipo**: HTTP(s)
   - **Códigos aceptados**: 200-299
4. Guardar y verificar

---

### 2. AdGuard DNS Resolver
**Error**: `queryA ETIMEOUT google.com`

**Causa**: Timeout en la consulta DNS o servicio no respondiendo.

**Diagnóstico**:

```bash
# SSH al nodo proxmox
ssh root@192.168.1.78

# Verificar que LXC 103 está corriendo
pct status 103

# Ping al LXC
ping -c 3 192.168.1.120

# Test DNS directo desde el nodo
dig @192.168.1.120 google.com +short

# Si falla, verificar servicio dentro del LXC
pct exec 103 -- systemctl status AdGuardHome

# Verificar puertos
pct exec 103 -- ss -ulnp | grep ':53'
```

**Soluciones posibles**:

#### A. Si el servicio no está corriendo:

```bash
pct exec 103 -- systemctl start AdGuardHome
pct exec 103 -- systemctl enable AdGuardHome
```

#### B. Si el puerto 53 no está escuchando:

```bash
# Revisar logs
pct exec 103 -- journalctl -u AdGuardHome -n 50

# Verificar configuración
pct exec 103 -- cat /opt/AdGuardHome/AdGuardHome.yaml | grep bind
```

#### C. Ajustar timeout en Uptime Kuma:

1. Ir al monitor **"AdGuard DNS Resolver"**
2. Editar:
   - **Intervalo**: Cambiar de 30s a 60s
   - **Timeout**: Aumentar si está muy bajo
   - **Reintentos**: Configurar 2-3 reintentos
3. Guardar

#### D. Verificar que no hay firewall bloqueando:

```bash
# Dentro del LXC 103
pct exec 103 -- iptables -L -n | grep 53

# Verificar firewall de Proxmox
pve-firewall status
```

#### E. Cambiar el tipo de monitor (alternativa):

Si el monitor DNS sigue fallando, puedes usar HTTP en su lugar:

1. Tipo: **HTTP(s)**
2. URL: `http://192.168.1.120` (interfaz web de AdGuard)
3. Códigos: 200-299

Esto verifica que AdGuard está vivo, aunque no prueba específicamente el DNS.

---

## 📋 Checklist Post-Fix

- [ ] Cloudflared Health Check resuelto (puerto 9090)
- [ ] AdGuard DNS Resolver resuelto
- [ ] Ejecutar sincronización de monitores LXC 105 → 205
- [ ] Desactivar notificaciones en LXC 205 (backup)
- [ ] Actualizar webhook n8n a producción

---

## 🔄 Sincronización de Monitores

Una vez resueltos los errores, sincroniza los cambios al backup:

```bash
# SSH al nodo proxmox
ssh root@192.168.1.78

# Ejecutar script de sincronización
/root/sync-uptimekuma.sh

# Verificar que se completó
tail -50 /var/log/uptimekuma-sync.log
```

---

## 🔕 Desactivar Alertas en LXC 205 (Backup)

Para evitar alertas duplicadas del backup:

### Opción A: Desactivar notificaciones a nivel global

1. Acceder a LXC 205: http://192.168.1.71:3001
2. Ir a **Settings** → **Notifications**
3. Seleccionar la notificación de Telegram
4. Click en **Disable** o eliminar de todos los monitores

### Opción B: Pausar todos los monitores

```bash
# Opción manual desde la UI:
# 1. Ir a cada grupo
# 2. Click en "Pause" para pausar todo el grupo

# Esto mantiene la configuración pero no envía alertas
```

### Opción C: Script para pausar monitores vía API (avanzado)

Si Uptime Kuma tiene API habilitada, puedes pausar programáticamente.

---

## 🔔 Cambiar Webhook n8n a Producción

1. Acceder a Uptime Kuma principal: http://192.168.1.70:3001
2. Ir a **Settings** → **Notifications**
3. Buscar notificación **"n8n webhook"**
4. Verificar/actualizar:
   - **Webhook URL**: Debe apuntar a tu instancia n8n de producción
   - **Método**: POST
   - **Headers**: Si requiere autenticación
5. Hacer test de la notificación
6. Guardar cambios

---

## 📊 Verificación Final

```bash
# Verificar estado de servicios clave
pct exec 100 -- docker ps  # Proxy + cloudflared
pct exec 103 -- systemctl status AdGuardHome
pct exec 105 -- systemctl status uptime-kuma
ssh root@192.168.1.82 "pct exec 205 -- systemctl status uptime-kuma"

# Verificar puertos clave
pct exec 100 -- ss -tlnp | grep -E ':(80|81|443|9090)'
pct exec 103 -- ss -ulnp | grep ':53'
pct exec 105 -- ss -tlnp | grep ':3001'
```

---

## 🎯 Notas Finales

**Puerto correcto de Cloudflared**: `9090` (métricas Prometheus)
- Endpoint `/metrics`: Métricas detalladas
- Endpoint `/ready`: Health check simple

**AdGuard DNS**: Si persisten problemas, considera:
1. Verificar upstream DNS en configuración AdGuard
2. Revisar logs para errores específicos
3. Reiniciar el contenedor si es necesario

**Sincronización**: Ejecutar después de cada cambio importante en monitores
**Backup**: Mantener LXC 205 sincronizado pero con alertas pausadas
