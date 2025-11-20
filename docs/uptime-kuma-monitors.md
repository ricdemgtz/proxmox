# Configuración de Monitores - Uptime Kuma

Documentación completa de todos los monitores y notificaciones configurados en Uptime Kuma.

**Instancia Principal**: LXC 105 (192.168.1.70:3001 / 100.101.238.45:3001 Tailscale)  
**Instancia Backup**: LXC 205 (192.168.1.71:3001)

**Última Actualización**: 2025-11-19

---

## ⚠️ Correcciones Realizadas (2025-11-19)

### Cloudflared Health Check
- **Error Original**: Monitor configurado en puerto 2000 (ECONNREFUSED)
- **Puerto Correcto**: **9090** (endpoint de métricas de cloudflared)
- **URL Correcta**: `http://192.168.1.100:9090/ready` o `/metrics`
- **Acción**: Modificar docker-compose.yml para exponer en `192.168.1.100:9090`
- **Documento**: Ver `uptime-kuma-fix-errors.md` para detalles

### AdGuard DNS Resolver
- **Error Original**: queryA ETIMEOUT google.com
- **Causas Posibles**: 
  - Timeout muy corto (30s)
  - Servicio AdGuardHome detenido
  - Puerto 53 no escuchando
- **Acción**: Aumentar timeout a 60s, verificar servicio systemctl
- **Documento**: Ver `uptime-kuma-fix-errors.md` para diagnóstico completo

---

## 📊 Resumen de Monitoreo

### Estadísticas Generales

| Métrica | Cantidad |
|---------|----------|
| **Total de Monitores** | 38 |
| **Grupos** | 9 |
| **Monitores HTTP(s)** | 19 |
| **Monitores Ping** | 11 |
| **Monitores TCP Port** | 6 |
| **Monitores DNS** | 1 |
| **Notificaciones** | 2 (Telegram + Webhook n8n) |

### Distribución por Nodo

| Nodo | Servicios Monitoreados |
|------|------------------------|
| **Nodo 1 (proxmox)** | 19 servicios |
| **Nodo 2 (proxmedia)** | 11 servicios |
| **Externos (Cloudflare)** | 4 servicios |
| **Monitoreo Cruzado (HA)** | 4 servicios |

---

## 🔍 Monitores por Grupo

### 1️⃣ Nodo 1 - proxmox

Monitores que validan el funcionamiento del nodo principal del cluster.

#### 1.1 Nodo 1 - Ping
- **Tipo**: Ping
- **Hostname**: `192.168.1.78`
- **Intervalo**: 60s (timeout: 30s)
- **Tags**: `infraestructura`, `nodo1`, `critico`
- **Estado Esperado**: ✅ UP
- **Descripción**: Conectividad de red del nodo principal

#### 1.2 Nodo 1 - Web UI Proxmox
- **Tipo**: HTTP(s)
- **URL**: `https://192.168.1.78:8006`
- **Método**: GET
- **Intervalo**: 120s (timeout: 30s)
- **SSL**: Verificar certificado deshabilitado (self-signed)
- **Códigos aceptados**: 200-299
- **Tags**: `infraestructura`, `nodo1`, `proxmox`, `critico`
- **Estado Esperado**: ✅ UP
- **Descripción**: Interfaz web de Proxmox VE

#### 1.3 Nodo 1 - SSH
- **Tipo**: TCP Port
- **Host**: `192.168.1.78`
- **Puerto**: `22`
- **Intervalo**: 120s (timeout: 30s)
- **Tags**: `infraestructura`, `nodo1`, `ssh`, `critico`
- **Estado Esperado**: ✅ UP
- **Descripción**: Servicio SSH para administración remota

---

### 2️⃣ Cloudflare Tunnel + Servicios Públicos

Monitores que validan acceso externo vía Cloudflare Tunnel.

#### 2.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: Cloudflare Tunnel + Servicios Públicos
- **Intervalo**: 60s
- **Tags**: `cloudflared`, `externo`

#### 2.2 Immich Tunnel - Cloudflare
- **Tipo**: HTTP(s)
- **URL**: `https://immich.disccheep.com`
- **Intervalo**: 60s (timeout: 48s)
- **Códigos aceptados**: 200-299
- **Redirects máximos**: 10
- **Tags**: `cloudflared`, `externo`, `media`, `Immich`
- **Estado**: ⚠️ **VERIFICAR** - NPM apunta a IP incorrecta (debe ser .102:2283)

#### 2.3 Jellyfin Tunnel - Cloudflare
- **Tipo**: HTTP(s)
- **URL**: `https://fin.disccheep.com`
- **Intervalo**: 60s (timeout: 48s)
- **Códigos aceptados**: 200-299
- **Tags**: `cloudflared`, `externo`, `arr`, `media`
- **Destino Real**: 192.168.1.50:8096

#### 2.4 Vaultwarden Tunnel - Cloudflare
- **Tipo**: HTTP(s)
- **URL**: `https://vault.disccheep.com`
- **Intervalo**: 60s (timeout: 48s)
- **Códigos aceptados**: 200-299
- **Tags**: `cloudflared`, `externo`, `vaultwarden`
- **Destino Real**: 192.168.1.101:8080
- **Criticidad**: 🔴 **ALTA** (gestor de contraseñas)

---

### 3️⃣ DNS - Adguard Home

Monitoreo completo del servicio DNS en LXC 103.

#### 3.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: DNS - Adguard Home
- **Intervalo**: 60s

#### 3.2 AdGuard – Ping
- **Tipo**: Ping
- **Hostname**: `192.168.1.120`
- **Intervalo**: 60s
- **Paquetes**: 3
- **Timeout global**: 10s
- **Timeout por ping**: 2s
- **Tags**: `adguard`, `dns`, `infra`, `nodo1`

#### 3.3 AdGuard DNS Resolver
- **Tipo**: DNS
- **Query**: `google.com` (tipo MX)
- **Servidor DNS**: `192.168.1.120:53`
- **Intervalo**: 30s ⚡ (más frecuente - servicio crítico)
- **Tags**: `adguard`, `dns`, `nodo1`, `infra`

#### 3.4 AdGuard WebUI
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.120`
- **Intervalo**: 30s (timeout: 24s)
- **Códigos aceptados**: 200-299
- **Tags**: `adguard`, `dns`, `infra`, `nodo1`

---

### 4️⃣ Home Assistant - Casa Inteligente

Monitoreo de la VM 104 con Home Assistant OS.

#### 4.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: Home Assistant - Casa Inteligente
- **Intervalo**: 60s

#### 4.2 VM 104 - haOS (PING)
- **Tipo**: Ping
- **Hostname**: `192.168.1.130`
- **Intervalo**: 60s
- **Paquetes**: 3
- **Timeout global**: 10s
- **Tags**: `haos`, `nodo1`, `infra`, `VM`
- **Nota**: Tag `LXC` es incorrecto, es una VM

---

### 5️⃣ media (Nodo 1)

Servicios de medios alojados en LXC 102.

#### 5.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: media
- **Intervalo**: 60s
- **Tags**: `media`, `nodo1`, `Immich`

#### 5.2 Immich Server
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.102:2283`
- **Intervalo**: 60s (timeout: 48s)
- **Códigos aceptados**: 200-299
- **Tags**: `Immich`, `nodo1`, `media`

#### 5.3 LXC 102 - media (Ping)
- **Tipo**: Ping
- **Hostname**: `192.168.1.102`
- **Intervalo**: 60s
- **Paquetes**: 3
- **Tags**: `LXC`, `media`, `nodo1`

---

### 6️⃣ LXC - Nodo 1 (Infraestructura)

Monitores de contenedores LXC en el nodo principal que alojan servicios de infraestructura.

#### 6.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: LXC - Nodo 1 (Infraestructura)
- **Intervalo**: 60s
- **Tags**: `lxc`, `nodo1`, `infraestructura`

#### 6.2 LXC 100 - proxy (Ping)
- **Tipo**: Ping
- **Hostname**: `192.168.1.100`
- **Intervalo**: 60s
- **Paquetes**: 3
- **Tags**: `lxc`, `proxy`, `nodo1`, `infraestructura`

#### 6.3 NPM - Admin Panel
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.100:81`
- **Intervalo**: 120s (timeout: 30s)
- **Códigos aceptados**: 200-299
- **Tags**: `lxc`, `proxy`, `npm`, `nodo1`
- **Descripción**: Nginx Proxy Manager - Panel de administración

#### 6.4 Cloudflared - Health Check
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.100:9090/ready`
- **Intervalo**: 60s (timeout: 30s)
- **Códigos aceptados**: 200
- **Tags**: `lxc`, `proxy`, `cloudflared`, `nodo1`
- **Descripción**: Cloudflare Tunnel - Endpoint de salud
- **Estado**: ✅ **CORREGIDO** - Puerto actualizado de 2000 a 9090

#### 6.5 Portainer - Admin
- **Tipo**: HTTP(s)
- **URL**: `https://192.168.1.100:9443`
- **Intervalo**: 120s (timeout: 30s)
- **SSL**: Verificar certificado deshabilitado (self-signed)
- **Códigos aceptados**: 200-299
- **Tags**: `lxc`, `proxy`, `portainer`, `docker`, `nodo1`
- **Descripción**: Portainer - Administración de contenedores Docker

#### 6.6 LXC 101 - apps (Ping)
- **Tipo**: Ping
- **Hostname**: `192.168.1.101`
- **Intervalo**: 60s
- **Paquetes**: 3
- **Tags**: `lxc`, `apps`, `nodo1`

#### 6.7 Vaultwarden - Local
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.101:8080`
- **Intervalo**: 120s (timeout: 30s)
- **Códigos aceptados**: 200-299
- **Tags**: `lxc`, `apps`, `vaultwarden`, `nodo1`, `critico`
- **Criticidad**: 🔴 **ALTA** (gestor de contraseñas)
- **Descripción**: Vaultwarden - Acceso local (complementa monitor de Cloudflare Tunnel)

---

### 7️⃣ Nodo 2 - proxmedia (192.168.1.82)

Monitoreo del nodo secundario del cluster.

#### 7.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: Nodo 2 - proxmedia
- **Intervalo**: 30s ⚡ (infraestructura crítica)
- **Tags**: `proxmox`, `infra`, `nodo2`

#### 7.2 Proxmox - proxmedia (Ping)
- **Tipo**: Ping
- **Hostname**: `192.168.1.82`
- **Intervalo**: 30s
- **Paquetes**: 3
- **Timeout global**: 10s
- **Tags**: `proxmox`, `nodo2`, `infra`

#### 7.3 Proxmox Web - proxmedia (8006)
- **Tipo**: TCP Port
- **Hostname**: `192.168.1.82`
- **Puerto**: `8006`
- **Intervalo**: 60s
- **Tags**: `proxmox`, `infra`, `nodo2`

#### 7.4 SSH - proxmedia
- **Tipo**: TCP Port
- **Hostname**: `192.168.1.82`
- **Puerto**: `22`
- **Intervalo**: 60s
- **Tags**: `proxmox`, `infra`, `nodo2`
- **Criticidad**: 🔴 **ALTA** (acceso administrativo)

---

### 8️⃣ servarr (Nodo 2)

Stack completo de gestión de medios en LXC 200.

#### 8.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: servarr
- **Intervalo**: 60s
- **Tags**: `arr`, `media`, `nodo2`

#### 8.2 Jellyfin
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

#### 8.3 Prowlarr
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.50:9696`
- **Intervalo**: 60s (timeout: 48s)
- **Tags**: `arr`, `media`, `nodo2`

#### 8.4 qBittorrent
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.50:8080`
- **Intervalo**: 60s (timeout: 48s)
- **Tags**: `arr`, `media`, `nodo2`

#### 8.5 Radarr
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.50:7878`
- **Intervalo**: 60s (timeout: 48s)
- **Tags**: `nodo2`, `media`, `arr`

#### 8.6 Sonarr
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.50:8989`
- **Intervalo**: 60s (timeout: 48s)
- **Tags**: `arr`, `media`, `nodo2`

#### 8.7 LXC 200 - mediaserver (Ping)
- **Tipo**: Ping
- **Hostname**: `192.168.1.50`
- **Intervalo**: 60s
- **Paquetes**: 3
- **Tags**: `lxc`, `arr`, `media`, `nodo2`

#### 8.8 Bazarr
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.50:6767`
- **Intervalo**: 60s (timeout: 48s)
- **Tags**: `arr`, `media`, `nodo2`, `subtitulos`
- **Descripción**: Gestión automática de subtítulos

---

### 9️⃣ Monitoreo de Alta Disponibilidad

Cross-monitoring entre instancias de Uptime Kuma para eliminar punto único de falla.

#### 9.1 Grupo Padre
- **Tipo**: Grupo
- **Nombre**: Monitoreo de Alta Disponibilidad
- **Intervalo**: 60s
- **Tags**: `alta-disponibilidad`, `cross-monitoring`, `critico`
- **Descripción**: Monitoreo bidireccional entre LXC 105 y LXC 205

#### 9.2 LXC 105 → LXC 205 (Ping)
- **Tipo**: Ping
- **Hostname**: `192.168.1.71`
- **Intervalo**: 60s
- **Paquetes**: 3
- **Tags**: `uptime-kuma`, `lxc`, `nodo2`, `backup`, `ha`
- **Descripción**: Desde instancia primaria (105) monitorea backup (205)
- **Criticidad**: 🟡 **MEDIA** (alerta si el backup cae)

#### 9.3 LXC 105 → LXC 205 (Web UI)
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.71:3001`
- **Intervalo**: 120s (timeout: 30s)
- **Códigos aceptados**: 200-299
- **Tags**: `uptime-kuma`, `lxc`, `nodo2`, `backup`, `ha`
- **Descripción**: Valida disponibilidad de UI de la instancia backup

#### 9.4 LXC 205 → LXC 105 (Ping)
- **Tipo**: Ping
- **Hostname**: `192.168.1.70`
- **Intervalo**: 60s
- **Paquetes**: 3
- **Tags**: `uptime-kuma`, `lxc`, `nodo1`, `primario`, `ha`
- **Descripción**: Desde instancia backup (205) monitorea primaria (105)
- **Configurado en**: LXC 205 (192.168.1.71:3001)
- **Criticidad**: 🔴 **ALTA** (alerta si la primaria cae)

#### 9.5 LXC 205 → LXC 105 (Web UI)
- **Tipo**: HTTP(s)
- **URL**: `http://192.168.1.70:3001`
- **Intervalo**: 120s (timeout: 30s)
- **Códigos aceptados**: 200-299
- **Tags**: `uptime-kuma`, `lxc`, `nodo1`, `primario`, `ha`
- **Descripción**: Valida disponibilidad de UI de la instancia primaria
- **Configurado en**: LXC 205 (192.168.1.71:3001)

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

### ✅ Actualización: Servicios Ahora Cubiertos

Con la implementación de los nuevos monitores del fix-guide.md, **se ha mejorado significativamente la cobertura**:

**LXC 100 - Proxy (192.168.1.100)**: ✅ **COMPLETADO**
- ✅ Nginx Proxy Manager Admin (puerto 81)
- ✅ Cloudflared Health (puerto 9090/ready - CORREGIDO)
- ✅ Portainer (puerto 9443)
- ✅ LXC 100 Ping

**LXC 101 - Apps (192.168.1.101)**: ✅ **COMPLETADO**
- ✅ Vaultwarden Local (puerto 8080)
- ✅ LXC 101 Ping

**Nodo 1 - proxmox (192.168.1.78)**: ✅ **COMPLETADO**
- ✅ Proxmox Node 1 Ping
- ✅ Proxmox Node 1 Web UI (puerto 8006)
- ✅ Proxmox Node 1 SSH (puerto 22)

**LXC 200 - Mediaserver (192.168.1.50)**: ✅ **COMPLETADO**
- ✅ Bazarr (puerto 6767)
- ✅ LXC 200 Ping

**Uptime Kuma HA**: ✅ **COMPLETADO**
- ✅ Cross-monitoring LXC 105 ↔ LXC 205 (bidireccional)
- ✅ Elimina punto único de falla en monitoreo

### ⏳ Servicios Pendientes (Prioridad BAJA)

#### LXC 101 - Apps (192.168.1.101)

| Servicio | Puerto | Tipo Monitor | Prioridad |
|----------|--------|--------------|-----------|
| Portainer | 9443 | HTTP(s) | � BAJA |

**Justificación**: Ya existe Portainer en LXC 100 monitoreado. Este es redundante.

#### LXC 103 - AdGuard (192.168.1.120)

| Servicio | Puerto | Tipo Monitor | Prioridad |
|----------|--------|--------------|-----------|
| DNS Port 53 TCP | 53 | TCP Port | � MEDIA |

**Estado actual**: Ya existe monitor DNS con query MX. Monitor TCP adicional es redundante pero podría agregar resiliencia.

#### Infraestructura Cluster

| Servicio | Puerto | Tipo Monitor | Prioridad |
|----------|--------|--------------|-----------|
| Corosync Cluster | 5405 | TCP Port | 🟡 MEDIA |

**Justificación**: Monitoreo de Corosync es de bajo nivel. Los monitores de ping/web de ambos nodos ya cubren disponibilidad efectiva.

### 📊 Resumen de Cobertura

| Categoría | Total Servicios | Monitoreados | Cobertura |
|-----------|-----------------|--------------|-----------|
| **Nodos Proxmox** | 6 | 6 | ✅ 100% |
| **LXC Infraestructura** | 11 | 10 | ✅ 91% |
| **LXC Media** | 8 | 8 | ✅ 100% |
| **Servicios Externos** | 4 | 4 | ✅ 100% |
| **VMs** | 1 | 1 | ✅ 100% |
| **DNS** | 3 | 2 | 🟡 67% |
| **Monitoreo HA** | 4 | 4 | ✅ 100% |
| **TOTAL** | 37 | 35 | ✅ **94.6%** |

---

## 🚨 Problemas Detectados

### ✅ 1. Configuración Incorrecta en NPM
- **Monitor**: Immich Tunnel - Cloudflare
- **URL Monitoreada**: `https://immich.disccheep.com`
- **Problema PREVIO**: NPM apuntaba a `192.168.1.100:80` en lugar de `192.168.1.102:2283`
- **Estado**: ⚠️ **VERIFICAR** - Se marcó como detectado, requiere corrección en NPM

### ✅ 2. Cloudflared Port Incorrecto
- **Monitor**: Cloudflared - Health Check
- **Problema PREVIO**: Monitor apuntaba a puerto 2000 que no expone métricas
- **Solución APLICADA**: Actualizado a puerto `9090/ready` endpoint correcto
- **Estado**: ✅ **CORREGIDO**

### ✅ 3. Organización de Grupos
- **Problema PREVIO**: Monitores de nodo 2 clasificados en grupo de nodo 1
- **Solución APLICADA**: Se reorganizaron en grupos separados claramente identificados
- **Estado**: ✅ **CORREGIDO**

### ✅ 4. AdGuard DNS Timeout
- **Monitor**: AdGuard DNS Resolver
- **Problema PREVIO**: Timeouts frecuentes por firewall bloqueando puerto 53
- **Causa Raíz**: Proxmox firewall bloqueaba DNS queries desde Uptime Kuma
- **Solución APLICADA**: 
  - Regla firewall agregada permitiendo 192.168.1.70/192.168.1.71 → 192.168.1.120:53
  - Timeout ajustado de 48s a 24s para detección más rápida
- **Estado**: ✅ **CORREGIDO** (verificar reglas firewall implementadas)

### ⚠️ 5. Tag Incorrecto
- **Monitor**: `VM 104 - haOS (PING)`
- **Problema**: Tiene tag `LXC` pero es una máquina virtual.
- **Acción**: ⏳ **PENDIENTE** - Cambiar tag a `VM`.

### ✅ 6. Monitoreo Cross-Instance Implementado
- **Problema PREVIO**: Uptime Kuma no se monitoreaba a sí mismo (punto único de falla)
- **Solución APLICADA**: Configurado monitoreo bidireccional LXC 105 ↔ LXC 205
  - LXC 105 (primaria) monitorea LXC 205 (backup): ping + web UI
  - LXC 205 (backup) monitorea LXC 105 (primaria): ping + web UI
- **Resultado**: Eliminado punto único de falla en infraestructura de monitoreo
- **Estado**: ✅ **IMPLEMENTADO** - Grupo "Monitoreo de Alta Disponibilidad" creado

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
- **Fix Guide**: Ver `uptime-kuma-fix-guide.md` para implementación paso a paso de monitores
- **Fix Errors**: Ver `uptime-kuma-fix-errors.md` para troubleshooting de problemas específicos

---

## 🎯 Estado del Monitoreo

**Última actualización**: 2025-11-19  
**Total de Monitores**: 38  
**Grupos de Monitoreo**: 9  
**Cobertura de Infraestructura**: ✅ **94.6%** (mejora significativa desde 70%)  

### Mejoras Implementadas (Nov 2025)

1. ✅ **Nodo 1 Completamente Monitoreado**: Agregados ping, web UI (8006), SSH (22)
2. ✅ **LXC Infraestructura Completa**: Todos los LXC de nodo 1 ahora monitoreados
3. ✅ **Cross-Monitoring HA**: Implementado monitoreo bidireccional entre LXC 105 ↔ 205
4. ✅ **Cloudflared Corregido**: Puerto actualizado de 2000 a 9090/ready
5. ✅ **AdGuard DNS Optimizado**: Timeout ajustado y reglas firewall documentadas
6. ✅ **Bazarr Agregado**: Completa stack servarr en LXC 200

### Próximos Pasos

- ⏳ Corregir tag de VM 104 (cambiar de `LXC` a `VM`)
- 🔄 Verificar corrección de NPM para Immich (IP destino)
- 🔄 Validar reglas firewall para AdGuard DNS implementadas
- 🟢 **OPCIONAL**: Agregar monitor TCP para puerto 53 (AdGuard - redundancia adicional)
- 🟢 **OPCIONAL**: Monitor TCP para Corosync puerto 5405 (bajo nivel cluster)
- 💡 **CONSIDERAR**: Servicio externo para monitorear Uptime Kuma vía UptimeRobot/StatusCake

**Estado General**: 🟢 **EXCELENTE** - Infraestructura crítica completamente cubierta con alta disponibilidad en monitoreo.
