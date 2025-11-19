# Configuración de Monitores - Uptime Kuma

Documentación completa de todos los monitores y notificaciones configurados en Uptime Kuma.

**Instancia Principal**: LXC 105 (192.168.1.70:3001 / 100.101.238.45:3001 Tailscale)  
**Instancia Backup**: LXC 205 (192.168.1.71:3001)

---

## 📊 Resumen de Monitoreo

### Estadísticas Generales

| Métrica | Cantidad |
|---------|----------|
| **Total de Monitores** | 24 |
| **Grupos** | 6 |
| **Monitores HTTP(s)** | 12 |
| **Monitores Ping** | 4 |
| **Monitores TCP Port** | 2 |
| **Monitores DNS** | 1 |
| **Notificaciones** | 2 (Telegram + Webhook n8n) |

### Distribución por Nodo

| Nodo | Servicios Monitoreados |
|------|------------------------|
| **Nodo 1 (proxmox)** | 13 servicios |
| **Nodo 2 (proxmedia)** | 7 servicios |
| **Externos (Cloudflare)** | 4 servicios |

---

## 🔍 Monitores por Grupo

### 1️⃣ Cloudflare Tunnel + Servicios Públicos

Monitores que validan acceso externo vía Cloudflare Tunnel.

#### 1.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: Cloudflare Tunnel + Servicios Públicos
- **Intervalo**: 60s
- **Tags**: `cloudflared`, `externo`

#### 1.2 Immich Tunnel - Cloudflare
- **Tipo**: HTTP(s)
- **URL**: `https://immich.disccheep.com`
- **Intervalo**: 60s (timeout: 48s)
- **Códigos aceptados**: 200-299
- **Redirects máximos**: 10
- **Tags**: `cloudflared`, `externo`, `media`, `Immich`
- **Estado**: ⚠️ **VERIFICAR** - NPM apunta a IP incorrecta (debe ser .102:2283)
- **Estado**: ⚠️ **VERIFICAR** - NPM apunta a IP incorrecta (debe ser .102:2283)

#### 1.3 Jellyfin Tunnel - Cloudflare
- **Tipo**: HTTP(s)
- **URL**: `https://fin.disccheep.com`
- **Intervalo**: 60s (timeout: 48s)
- **Códigos aceptados**: 200-299
- **Tags**: `cloudflared`, `externo`, `arr`, `media`
- **Destino Real**: 192.168.1.50:8096

#### 1.4 Vaultwarden Tunnel - Cloudflare
- **Tipo**: HTTP(s)
- **URL**: `https://vault.disccheep.com`
- **Intervalo**: 60s (timeout: 48s)
- **Códigos aceptados**: 200-299
- **Tags**: `cloudflared`, `externo`, `vaultwarden`
- **Destino Real**: 192.168.1.101:8080
- **Criticidad**: 🔴 **ALTA** (gestor de contraseñas)

---

### 2️⃣ DNS - Adguard Home

Monitoreo completo del servicio DNS en LXC 103.

#### 2.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: DNS - Adguard Home
- **Intervalo**: 60s

#### 2.2 AdGuard – Ping
- **Tipo**: Ping
- **Hostname**: `192.168.1.120`
- **Intervalo**: 60s
- **Paquetes**: 3
- **Timeout global**: 10s
- **Timeout por ping**: 2s
- **Tags**: `adguard`, `dns`, `infra`, `nodo1`

#### 2.3 AdGuard DNS Resolver
- **Tipo**: DNS
- **Query**: `google.com` (tipo MX)
- **Servidor DNS**: `192.168.1.120:53`
- **Intervalo**: 30s ⚡ (más frecuente - servicio crítico)
- **Tags**: `adguard`, `dns`, `nodo1`, `infra`

#### 2.4 AdGuard WebUI
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.120`
- **Intervalo**: 30s (timeout: 24s)
- **Códigos aceptados**: 200-299
- **Tags**: `adguard`, `dns`, `infra`, `nodo1`

---

### 3️⃣ Home Assistant - Casa Inteligente

Monitoreo de la VM 104 con Home Assistant OS.

#### 3.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: Home Assistant - Casa Inteligente
- **Intervalo**: 60s

#### 3.2 VM 104 - haOS (PING)
- **Tipo**: Ping
- **Hostname**: `192.168.1.130`
- **Intervalo**: 60s
- **Paquetes**: 3
- **Timeout global**: 10s
- **Tags**: `haos`, `nodo1`, `infra`, `VM`
- **Nota**: Tag `LXC` es incorrecto, es una VM

---

### 4️⃣ media (Nodo 1)

Servicios de medios alojados en LXC 102.

#### 4.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: media
- **Intervalo**: 60s
- **Tags**: `media`, `nodo1`, `Immich`

#### 4.2 Immich Server
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.102:2283`
- **Intervalo**: 60s (timeout: 48s)
- **Códigos aceptados**: 200-299
- **Tags**: `Immich`, `nodo1`, `media`

#### 4.3 LXC 102 - media (Ping)
- **Tipo**: Ping
- **Hostname**: `192.168.1.102`
- **Intervalo**: 60s
- **Paquetes**: 3
- **Tags**: `LXC`, `media`, `nodo1`

---

### 5️⃣ Nodo 1 - proxmox (192.168.1.78)

Monitoreo del nodo principal del cluster.

#### 5.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: Nodo 1 - proxmox
- **Intervalo**: 30s ⚡ (infraestructura crítica)
- **Tags**: `proxmox`, `infra`, `nodo1`

#### 5.2 Proxmox - proxmox (Ping)
- **Tipo**: Ping
- **Hostname**: `192.168.1.78`
- **Intervalo**: 30s
- **Paquetes**: 3
- **Timeout global**: 10s
- **Tags**: `proxmox`, `nodo1`, `infra`

#### 5.3 Proxmox Web - proxmox (8006)
- **Tipo**: TCP Port
- **Hostname**: `192.168.1.78`
- **Puerto**: `8006`
- **Intervalo**: 60s
- **Tags**: `proxmox`, `infra`, `nodo1`

#### 5.4 SSH - proxmox
- **Tipo**: TCP Port
- **Hostname**: `192.168.1.78`
- **Puerto**: `22`
- **Intervalo**: 60s
- **Tags**: `proxmox`, `infra`, `nodo1`
- **Criticidad**: 🔴 **ALTA** (acceso administrativo)

---

### 6️⃣ Nodo 2 - proxmedia (192.168.1.82)

Monitoreo del nodo secundario del cluster.

#### 6.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: Nodo 2 - proxmedia
- **Intervalo**: 30s ⚡ (infraestructura crítica)
- **Tags**: `proxmox`, `infra`, `nodo2`

#### 6.2 Proxmox - proxmedia (Ping)
- **Tipo**: Ping
- **Hostname**: `192.168.1.82`
- **Intervalo**: 30s
- **Paquetes**: 3
- **Timeout global**: 10s
- **Tags**: `proxmox`, `nodo2`, `infra`

#### 6.3 Proxmox Web - proxmedia (8006)
- **Tipo**: TCP Port
- **Hostname**: `192.168.1.82`
- **Puerto**: `8006`
- **Intervalo**: 60s
- **Tags**: `proxmox`, `infra`, `nodo2`

#### 6.4 SSH - proxmedia
- **Tipo**: TCP Port
- **Hostname**: `192.168.1.82`
- **Puerto**: `22`
- **Intervalo**: 60s
- **Tags**: `proxmox`, `infra`, `nodo2`
- **Criticidad**: 🔴 **ALTA** (acceso administrativo)

---

### 7️⃣ servarr (Nodo 2)

Stack completo de gestión de medios en LXC 200.

#### 6.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: servarr
- **Intervalo**: 60s
- **Tags**: `arr`, `media`, `nodo2`

#### 6.2 Jellyfin
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.50:8096`
- **Intervalo**: 60s (timeout: 48s)
- **Códigos aceptados**: 200-299
- **Tags**: `arr`, `media`, `nodo2`

#### 6.3 Jellyseerr
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.50:5055`
- **Intervalo**: 60s (timeout: 48s)
- **Tags**: `arr`, `media`, `nodo2`

#### 6.4 Prowlarr
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.50:9696`
- **Intervalo**: 60s (timeout: 48s)
- **Tags**: `arr`, `media`, `nodo2`

#### 6.5 qBittorrent
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.50:8080`
- **Intervalo**: 60s (timeout: 48s)
- **Tags**: `arr`, `media`, `nodo2`

#### 6.6 Radarr
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.50:7878`
- **Intervalo**: 60s (timeout: 48s)
- **Tags**: `nodo2`, `media`, `arr`

#### 6.7 Sonarr
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.50:8989`
- **Intervalo**: 60s (timeout: 48s)
- **Tags**: `arr`, `media`, `nodo2`

---

## 🔔 Notificaciones Configuradas

### 1. Telegram - Navi Racherd

**Configuración**:
- **Tipo**: Telegram
- **Nombre**: Telegram Navi - Racherd
- **Bot Token**: `••••••••••••••••••••••••••••••••••••••••••••••`
- **Chat ID**: `5527961393`
- **Formato**: HTML
- **Silencioso**: ❌ No
- **Proteger Forwarding**: ❌ No
- **Aplicado**: ✅ Todos los monitores

**Plantilla Personalizada**:
- **Motor**: Liquid Template
- **Características**:
  - 🚨 Alertas críticas para servicios con tags: `LXC`, `proxmox`, `vaultwarden`
  - Emojis según severidad (🔴 CAÍDO, ✅ RECUPERADO)
  - Formato HTML optimizado para Telegram
  - Información detallada: timestamp, ping, mensaje de error, tags
  - Incluye `pathName` (jerarquía de grupos)

**Lógica de Criticidad**:
```liquid
{% if tag_names contains "lxc" or tag_names contains "proxmox" or tag_names contains "vaultwarden" %}
  🚨🔴 ALERTA CRÍTICA – SERVICIO CAÍDO 🔴🚨
{% endif %}
```

**Ejemplo de Mensaje** (servicio crítico caído):
```
🚨🔴 ALERTA CRÍTICA – SERVICIO CAÍDO 🔴🚨
━━━━━━━━━━━━━━━━━━━━

📌 Servicio: SSH - proxmedia
📂 Ruta: Nodo 1 - Proxmox / SSH - proxmedia
🔧 Tipo: port
🌐 Destino: 192.168.1.82:22
⚠️ Estado: DOWN

━━━━━━━━━━━━━━━━━━━━
⏰ Timestamp: 2025-11-19 14:35:20
🌍 Zona horaria: America/Mexico_City
💬 Detalle: Connection refused

🏷 Tags: #proxmox, #infra, #nodo1

━━━━━━━━━━━━━━━━━━━━
⚡ PRIORIDAD: CRÍTICO ⚡
👉 Revisar inmediatamente
```

### 2. Webhook - n8n Alerta

**Configuración**:
- **Tipo**: Webhook
- **Nombre**: Mi Webhook Alerta (1)
- **URL**: `https://n8n.srv983273.hstgr.cloud/webhook-test/uptime-kuma-alert`
- **Método**: POST
- **Content-Type**: `application/json`
- **Aplicado**: ✅ Todos los monitores

**Payload Enviado**:
```json
{
  "heartbeat": {
    "monitorID": 123,
    "status": 0,
    "time": "2025-11-19 14:35:20",
    "msg": "Connection refused",
    "ping": null,
    "important": true,
    "duration": 0,
    "timezone": "America/Mexico_City",
    "timezoneOffset": "-06:00",
    "localDateTime": "2025-11-19 14:35:20"
  },
  "monitor": {
    "id": 123,
    "name": "SSH - proxmedia",
    "description": "",
    "pathName": "Nodo 1 - Proxmox / SSH - proxmedia",
    "parent": null,
    "childrenIDs": [],
    "url": null,
    "method": null,
    "hostname": "192.168.1.82",
    "port": 22,
    "maxretries": 0,
    "weight": 2000,
    "active": true,
    "forceInactive": false,
    "type": "port",
    "interval": 60,
    "retryInterval": 60,
    "resendInterval": 0,
    "keyword": null,
    "invertKeyword": false,
    "expiryNotification": false,
    "ignoreTls": false,
    "upsideDown": false,
    "packetSize": 56,
    "maxredirects": 10,
    "accepted_statuscodes": ["200-299"],
    "dns_resolve_type": "A",
    "dns_resolve_server": "1.1.1.1",
    "dns_last_result": null,
    "docker_container": "",
    "docker_host": null,
    "proxyId": null,
    "notificationIDList": {
      "1": true,
      "2": true
    },
    "tags": [
      {
        "tag_id": 5,
        "monitor_id": 123,
        "value": "",
        "name": "proxmox",
        "color": "#42d3a5"
      },
      {
        "tag_id": 3,
        "monitor_id": 123,
        "value": "",
        "name": "infra",
        "color": "#3e5c8f"
      },
      {
        "tag_id": 1,
        "monitor_id": 123,
        "value": "",
        "name": "nodo1",
        "color": "#ff9800"
      }
    ],
    "maintenance": false,
    "mqttTopic": "",
    "mqttSuccessMessage": "",
    "mqttCheckType": "keyword",
    "databaseQuery": null,
    "authMethod": null,
    "grpcUrl": null,
    "grpcProtobuf": null,
    "grpcMethod": null,
    "grpcServiceName": null,
    "grpcEnableTls": false,
    "radiusCalledStationId": null,
    "radiusCallingStationId": null,
    "game": null,
    "gamedigGivenPortOnly": true,
    "httpBodyEncoding": "json",
    "jsonPath": null,
    "expectedValue": null,
    "kafkaProducerTopic": null,
    "kafkaProducerBrokers": [],
    "kafkaProducerAllowAutoTopicCreation": false,
    "kafkaProducerSaslOptions": null,
    "kafkaProducerMessage": null,
    "screenshot": null,
    "remote_browser": null,
    "includeSensitiveData": true
  },
  "msg": "DOWN"
}
```

**Uso con n8n**:
- Trigger: Webhook
- Flujo sugerido:
  1. Webhook recibe payload
  2. Filter: Solo procesar si `heartbeat.status == 0` (CAÍDO)
  3. Function: Parsear tags y determinar criticidad
  4. IF: Criticidad ALTA → Notificar inmediatamente
  5. IF: Criticidad MEDIA → Agregar a queue
  6. HTTP Request: Enviar a servicio externo (Discord, Slack, PagerDuty, etc)

---

## 📋 Servicios SIN Monitoreo

Los siguientes servicios deberían tener monitores pero **NO están configurados**:

### LXC 100 - Proxy (192.168.1.100)

| Servicio | Puerto | Tipo Monitor | Prioridad |
|----------|--------|--------------|-----------|
| Nginx Proxy Manager Admin | 81 | HTTP(s) | 🔴 ALTA |
| Cloudflared Health | 2000 | HTTP(s) | 🟡 MEDIA |
| Portainer | 9443 | HTTP(s) | 🟢 BAJA |
| LXC 100 Ping | - | Ping | 🔴 ALTA |

### LXC 101 - Apps (192.168.1.101)

| Servicio | Puerto | Tipo Monitor | Prioridad |
|----------|--------|--------------|-----------|
| Vaultwarden Local | 8080 | HTTP(s) | 🔴 ALTA |
| Portainer | 9443 | HTTP(s) | 🟢 BAJA |
| LXC 101 Ping | - | Ping | 🟡 MEDIA |

### LXC 103 - AdGuard (192.168.1.120)

| Servicio | Puerto | Tipo Monitor | Prioridad |
|----------|--------|--------------|-----------|
| DNS Port 53 TCP | 53 | TCP Port | 🟡 MEDIA |
| LXC 103 Ping | - | Ping | ✅ CUBIERTO (indirecto) |

### LXC 105 - Uptime Kuma (192.168.1.70)

| Servicio | Puerto | Tipo Monitor | Prioridad |
|----------|--------|--------------|-----------|
| Uptime Kuma WebUI | 3001 | HTTP(s) | 🔴 ALTA |
| LXC 105 Ping | - | Ping | 🔴 ALTA |

**⚠️ Problema**: ¿Quién monitorea al monitor? Considerar:
- Usar servicio externo gratuito: [UptimeRobot](https://uptimerobot.com), [StatusCake](https://www.statuscake.com)
- Configurar healthcheck en LXC 205 que monitoree LXC 105

### LXC 200 - Mediaserver (192.168.1.50)

| Servicio | Puerto | Tipo Monitor | Prioridad |
|----------|--------|--------------|-----------|
| Bazarr | 6767 | HTTP(s) | 🟢 BAJA |
| LXC 200 Ping | - | Ping | 🟡 MEDIA |

### LXC 205 - Uptime Kuma Backup (192.168.1.71)

| Servicio | Puerto | Tipo Monitor | Prioridad |
|----------|--------|--------------|-----------|
| Uptime Kuma Backup WebUI | 3001 | HTTP(s) | 🟡 MEDIA |
| LXC 205 Ping | - | Ping | 🟡 MEDIA |

### Nodos Proxmox

| Servicio | Puerto | Tipo Monitor | Prioridad |
|----------|--------|--------------|-----------|
| Proxmox Node 1 (proxmox) Ping | - | Ping | 🔴 ALTA |
| Proxmox Node 1 Web UI | 8006 | TCP Port | 🔴 ALTA |
| Proxmox Node 1 SSH | 22 | TCP Port | 🔴 ALTA |
| Corosync Cluster | 5405 | TCP Port | 🟡 MEDIA |

**Nota**: Actualmente solo se monitorea el nodo 2 (proxmedia), falta nodo 1 (proxmox).

---

## 🚨 Problemas Detectados

### 1. Configuración Incorrecta en NPM
- **Monitor**: Immich Tunnel - Cloudflare
- **URL Monitoreada**: `https://immich.disccheep.com`
- **Problema**: Según `network-architecture.md`, NPM apunta a `192.168.1.100:80` en lugar de `192.168.1.102:2283`
- **Acción**: Corregir Proxy Host en NPM. El destino debe ser `http://192.168.1.102:2283`.

### 2. Organización de Grupos
- **Monitor**: `Proxmox - proxmedia (Ping)` y sus relacionados.
- **Problema**: Están en el grupo "Nodo 1 - Proxmox" pero monitorean el nodo 2 (`192.168.1.82`).
- **Acción**: Reorganizar en dos grupos separados: "Nodo 1 - proxmox (192.168.1.78)" y "Nodo 2 - proxmedia (192.168.1.82)".

### 3. Tag Incorrecto
- **Monitor**: `VM 104 - haOS (PING)`
- **Problema**: Tiene tag `LXC` pero es una máquina virtual.
- **Acción**: Cambiar tag a `VM`.

### 4. Falta Monitoreo del Nodo Principal
- **Problema**: No hay monitores para `192.168.1.78` (nodo proxmox).
- **Riesgo**: Si el nodo principal cae, no hay alerta.
- **Acción**: Agregar monitores de Ping, puerto 8006 (Web UI) y puerto 22 (SSH).

### 5. Uptime Kuma No Se Monitorea a Sí Mismo
- **Problema**: LXC 105 (principal) no tiene monitor.
- **Riesgo**: Si cae, no hay forma de saberlo hasta acceder manualmente.
- **Solución Propuesta**: Configurar monitoreo cruzado. LXC 205 monitorea a LXC 105 y viceversa. Adicionalmente, se puede usar un servicio externo como [UptimeRobot](https://uptimerobot.com) para monitorear la disponibilidad de la instancia principal a través de su URL de Tailscale.

### 6. Puerto Incorrecto para Cloudflared
- **Servicio**: Cloudflared Health Check.
- **Problema**: El puerto `9090` es para métricas de Prometheus, no un health check. El puerto correcto para health checks es el `2000` en la ruta `/ready`.
- **Acción**: Cambiar el puerto de monitoreo a `2000` y la URL a `http://192.168.1.100:2000/ready`.
---

## 📝 Plantilla para Nuevos Monitores

### Monitor HTTP(s) - Plantilla

```yaml
Tipo: HTTP(s)
Nombre: [Nombre del Servicio]
URL: http://[IP]:[Puerto]
Intervalo: 60 segundos
Timeout: 48 segundos
Reintentos: 0
Reintento Intervalo: 60 segundos
Códigos Aceptados: 200-299
Redirects Máximos: 10
Grupo: [Nombre del Grupo]
Tags: [tag1], [tag2], [nodo1/nodo2]
Notificaciones: Telegram, Webhook
```

### Monitor Ping - Plantilla

```yaml
Tipo: Ping
Nombre: [Nombre del Host] (Ping)
Hostname: [IP]
Intervalo: 60 segundos
Paquetes: 3
Timeout Global: 10 segundos
Timeout por Ping: 2 segundos
Grupo: [Nombre del Grupo]
Tags: [LXC/VM/proxmox], [nodo1/nodo2], [infra]
Notificaciones: Telegram, Webhook
```

### Monitor TCP Port - Plantilla

```yaml
Tipo: TCP Port
Nombre: [Servicio] - [Puerto]
Hostname: [IP]
Puerto: [Puerto]
Intervalo: 60 segundos
Grupo: [Nombre del Grupo]
Tags: [tag1], [nodo1/nodo2], [infra]
Notificaciones: Telegram, Webhook
```

---

## 🎯 Recomendaciones de Optimización

### 1. Crear Grupos Adicionales

```
📁 Infraestructura Crítica
  ├─ Proxmox Node 1 (Ping, Web, SSH)
  ├─ Proxmox Node 2 (Ping, Web, SSH)
  └─ Cluster Corosync (TCP 5405)

📁 LXC - Nodo 1
  ├─ LXC 100 (Proxy)
  ├─ LXC 101 (Apps)
  ├─ LXC 102 (Media)
  ├─ LXC 103 (AdGuard)
  └─ LXC 105 (Uptime Kuma)

📁 LXC - Nodo 2
  ├─ LXC 200 (Mediaserver)
  └─ LXC 205 (Uptime Kuma Backup)

📁 Acceso Externo
  ├─ Cloudflare Tunnel (Grupo actual)
  └─ Tailscale VPN (nuevo)
```

### 2. Ajustar Intervalos por Criticidad

| Criticidad | Intervalo Recomendado | Servicios |
|------------|----------------------|-----------|
| 🔴 CRÍTICA | 30s | Proxmox, SSH, Vaultwarden, DNS |
| 🟡 ALTA | 60s | HTTP services, VMs, LXC |
| 🟢 MEDIA | 120s | Servicios *arr, Portainer |
| ⚪ BAJA | 300s | Servicios de prueba |

### 3. Configurar Alertas Escalonadas

```yaml
# En Telegram Template
Notificación Inmediata (status == 0):
  - Servicios con tag: proxmox, vaultwarden, dns
  
Notificación Después de 3 Fallos:
  - Servicios con tag: LXC, media, arr
  
Notificación Solo Recuperación:
  - Servicios con tag: test, dev
```

### 4. Agregar Status Page Pública

**Uptime Kuma 2.0 incluye Status Pages**:
- Settings → Status Pages → Add Status Page
- URL: `http://192.168.1.70:3001/status/[slug]`
- Incluir:
  - Cloudflare Tunnel + Servicios Públicos (grupo completo)
  - Proxmox Cluster (solo ping de ambos nodos)
  - Servicios críticos (DNS, Vaultwarden)

---

## 🔧 Comandos Útiles

### Consultar Monitores vía API (Uptime Kuma 1.x)

```bash
# NO FUNCIONA en Uptime Kuma 2.0 - usa Socket.IO
curl -H "X-Api-Key: uk1_..." http://192.168.1.70:3001/api/monitor
```

### Backup Manual de Configuración

```bash
# Opción 1: Desde Web UI
# Settings → Backup → Export Backup
# Descarga: kuma-backup-YYYY-MM-DD.json

# Opción 2: Copiar base de datos
ssh root@192.168.1.78
pct exec 105 -- tar czf - -C /opt/uptime-kuma data/ > /root/uptimekuma-backup-$(date +%Y%m%d).tar.gz
```

### Ver Logs de Uptime Kuma

```bash
# Desde Proxmox host
pct exec 105 -- docker logs -f uptime-kuma

# Ver últimas 100 líneas
pct exec 105 -- docker logs --tail 100 uptime-kuma
```

### Reiniciar Uptime Kuma

```bash
# Reinicio limpio
pct exec 105 -- docker restart uptime-kuma

# Reinicio completo (si hay problemas)
pct exec 105 -- bash -c "cd /opt/uptime-kuma && docker compose restart"
```

---

## 📊 Métricas de Uptime

**Objetivo de SLA**: 99.9% uptime mensual

| Servicio Crítico | SLA Objetivo | Downtime Permitido/Mes |
|------------------|--------------|------------------------|
| Proxmox Cluster | 99.95% | 21.6 minutos |
| Vaultwarden | 99.9% | 43.2 minutos |
| DNS (AdGuard) | 99.9% | 43.2 minutos |
| Jellyfin | 99.5% | 3.6 horas |
| Otros Servicios | 99.0% | 7.2 horas |

**Cálculo**: 30 días × 24 horas × 60 minutos = 43,200 minutos/mes

---

## 🆘 Troubleshooting

### Monitor Reporta "Connection Refused"

```bash
# 1. Verificar que el servicio esté corriendo
pct exec [CTID] -- docker ps

# 2. Verificar puerto escuchando
pct exec [CTID] -- netstat -tulpn | grep [PUERTO]

# 3. Verificar firewall
pct exec [CTID] -- iptables -L -n | grep [PUERTO]

# 4. Test manual desde host
curl -v http://[IP]:[PUERTO]
```

### Telegram No Recibe Notificaciones

```bash
# Verificar token y chat ID
curl "https://api.telegram.org/bot[TOKEN]/getUpdates"

# Enviar mensaje de prueba
curl -X POST "https://api.telegram.org/bot[TOKEN]/sendMessage" \
  -d "chat_id=[CHAT_ID]&text=Test"
```

### Webhook n8n No Responde

```bash
# Test manual del webhook
curl -X POST https://n8n.srv983273.hstgr.cloud/webhook-test/uptime-kuma-alert \
  -H "Content-Type: application/json" \
  -d '{"msg":"TEST","monitor":{"name":"Test Monitor"}}'

# Verificar logs en n8n
# Executions → Ver último intento
```

---

## 📚 Recursos

- **Uptime Kuma GitHub**: https://github.com/louislam/uptime-kuma
- **Documentación Oficial**: https://github.com/louislam/uptime-kuma/wiki
- **Liquid Template Docs**: https://shopify.github.io/liquid/
- **Telegram Bot API**: https://core.telegram.org/bots/api

---

**Última actualización**: 2025-11-19  
**Total de Monitores**: 24  
**Cobertura de Infraestructura**: ~70% (faltan varios servicios críticos)  
**Próximos pasos**: Agregar monitores faltantes, configurar status page pública
