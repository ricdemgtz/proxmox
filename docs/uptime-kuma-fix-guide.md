# Guía Paso a Paso - Corrección de Configuración Uptime Kuma

Esta guía te llevará a través de todos los cambios necesarios para corregir los problemas identificados en tu configuración actual de Uptime Kuma y añadir los monitores faltantes.

**Tiempo estimado**: 30-45 minutos  
**Instancia**: http://192.168.1.70:3001 (LXC 105)

---

## 📋 Tabla de Contenidos

1. [Correcciones en Nginx Proxy Manager](#1-correcciones-en-nginx-proxy-manager)
2. [Reorganización de Grupos de Proxmox](#2-reorganización-de-grupos-de-proxmox)
3. [Corrección de Tags Incorrectos](#3-corrección-de-tags-incorrectos)
4. [Añadir Monitores del Nodo Principal](#4-añadir-monitores-del-nodo-principal)
5. [Añadir Monitores de LXC Faltantes](#5-añadir-monitores-de-lxc-faltantes)
6. [Configurar Monitoreo Cruzado](#6-configurar-monitoreo-cruzado)
7. [Corrección del Monitor Cloudflared](#7-corrección-del-monitor-cloudflared)
8. [Verificación Final](#8-verificación-final)

---

## 1. Correcciones en Nginx Proxy Manager

### Problema
El proxy host `immich.disccheep.com` está apuntando a `http://192.168.1.100:80` en lugar del servicio real de Immich en `http://192.168.1.102:2283`.

### Solución

**Paso 1.1**: Acceder a Nginx Proxy Manager
```
URL: http://192.168.1.100:81
Credenciales: Tu usuario/contraseña de NPM
```

**Paso 1.2**: Editar el Proxy Host de Immich

1. Click en **"Hosts"** → **"Proxy Hosts"**
2. Buscar el host `immich.disccheep.com`
3. Click en los **3 puntos** → **"Edit"**
4. En la pestaña **"Details"**:
   - **Scheme**: `http://`
   - **Forward Hostname / IP**: Cambiar de `192.168.1.100` a `192.168.1.102`
   - **Forward Port**: Cambiar de `80` a `2283`
   - **Cache Assets**: ✅ Activado (recomendado)
   - **Block Common Exploits**: ✅ Activado
   - **Websockets Support**: ✅ Activado (importante para Immich)
5. Click en **"Save"**

**Paso 1.3**: Verificar el cambio

```powershell
# Desde tu Windows, probar el endpoint
curl https://immich.disccheep.com

# Deberías ver una respuesta HTML de Immich, no de NPM
```

**Resultado esperado**: El monitor `Immich Tunnel - Cloudflare` debería mantenerse en estado UP.

---

## 2. Reorganización de Grupos de Proxmox

### Problema
Los monitores del nodo `proxmedia` (192.168.1.82) están en el grupo "Nodo 1 - Proxmox", cuando deberían estar en su propio grupo.

### Solución

**Paso 2.1**: Crear el Grupo "Nodo 1 - proxmox"

1. Acceder a Uptime Kuma: http://192.168.1.70:3001
2. Click en **"+ Add New Monitor"**
3. **Monitor Type**: Seleccionar **"Group"**
4. **Friendly Name**: `Nodo 1 - proxmox`
5. **Heartbeat Interval**: `30` segundos
6. **Tags**: Agregar:
   - `proxmox` (color: #42d3a5)
   - `infra` (color: #3e5c8f)
   - `nodo1` (color: #ff9800)
7. Click en **"Save"**

**Paso 2.2**: Crear el Grupo "Nodo 2 - proxmedia"

1. Click en **"+ Add New Monitor"**
2. **Monitor Type**: **"Group"**
3. **Friendly Name**: `Nodo 2 - proxmedia`
4. **Heartbeat Interval**: `30` segundos
5. **Tags**: Agregar:
   - `proxmox` (color: #42d3a5)
   - `infra` (color: #3e5c8f)
   - `nodo2` (color: #e91e63) ← **Crear nuevo tag**
6. Click en **"Save"**

**Paso 2.3**: Reasignar Monitores Existentes

Estos monitores deben moverse del grupo "Nodo 1 - Proxmox" al nuevo "Nodo 2 - proxmedia":

1. **Proxmox - proxmedia (Ping)**:
   - Click en el monitor → **"Edit"**
   - **Parent**: Cambiar a `Nodo 2 - proxmedia`
   - **Tags**: Cambiar `nodo1` por `nodo2`
   - Click en **"Save"**

2. **Proxmox Web - proxmedia (8006)**:
   - Click en el monitor → **"Edit"**
   - **Parent**: Cambiar a `Nodo 2 - proxmedia`
   - **Tags**: Cambiar `nodo1` por `nodo2`
   - Click en **"Save"**

3. **SSH - proxmedia**:
   - Click en el monitor → **"Edit"**
   - **Parent**: Cambiar a `Nodo 2 - proxmedia`
   - **Tags**: Cambiar `nodo1` por `nodo2`
   - Click en **"Save"**

**Paso 2.4**: Renombrar Grupo Antiguo (Opcional)

Si el grupo "Nodo 1 - Proxmox" quedó vacío, puedes eliminarlo o mantenerlo para los nuevos monitores del nodo 1.

---

## 3. Corrección de Tags Incorrectos

### Problema
El monitor `VM 104 - haOS (PING)` tiene el tag `LXC` cuando debería ser `VM`.

### Solución

**Paso 3.1**: Crear el Tag "VM"

1. En cualquier monitor, click en **"Edit"**
2. En el campo **"Tags"**, escribir `VM` y presionar **Enter**
3. Seleccionar un color: `#9c27b0` (púrpura)
4. Click fuera del campo para guardar

**Paso 3.2**: Corregir el Monitor de haOS

1. Buscar el monitor **"VM 104 - haOS (PING)"**
2. Click en **"Edit"**
3. En **"Tags"**:
   - Eliminar el tag `LXC`
   - Agregar el tag `VM`
4. Verificar que tenga también: `haos`, `nodo1`, `infra`
5. Click en **"Save"**

---

## 4. Añadir Monitores del Nodo Principal

### Problema
No hay monitores para el nodo principal `proxmox` (192.168.1.78).

### Solución

**Paso 4.1**: Monitor de Ping - Nodo 1

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `Ping`
   - **Friendly Name**: `Proxmox - proxmox (Ping)`
   - **Hostname**: `192.168.1.78`
   - **Heartbeat Interval**: `30` segundos
   - **Retries**: `0`
   - **Heartbeat Retry Interval**: `30` segundos
   - **Timeout**: `10` segundos
   - **Max Packets**: `3`
   - **Timeout per Ping**: `2` segundos
   - **Parent**: `Nodo 1 - proxmox`
   - **Tags**: `proxmox`, `nodo1`, `infra`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

**Paso 4.2**: Monitor de Web UI - Nodo 1

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `TCP Port`
   - **Friendly Name**: `Proxmox Web - proxmox (8006)`
   - **Hostname**: `192.168.1.78`
   - **Port**: `8006`
   - **Heartbeat Interval**: `60` segundos
   - **Retries**: `0`
   - **Parent**: `Nodo 1 - proxmox`
   - **Tags**: `proxmox`, `infra`, `nodo1`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

**Paso 4.3**: Monitor de SSH - Nodo 1

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `TCP Port`
   - **Friendly Name**: `SSH - proxmox`
   - **Hostname**: `192.168.1.78`
   - **Port**: `22`
   - **Heartbeat Interval**: `60` segundos
   - **Retries**: `0`
   - **Parent**: `Nodo 1 - proxmox`
   - **Tags**: `proxmox`, `infra`, `nodo1`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

---

## 5. Añadir Monitores de LXC Faltantes

### 5.1 Grupo: LXC - Nodo 1 (Infraestructura)

**Paso 5.1.1**: Crear el Grupo

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `Group`
   - **Friendly Name**: `LXC - Nodo 1 (Infraestructura)`
   - **Heartbeat Interval**: `60` segundos
   - **Tags**: `LXC`, `nodo1`, `infra`
3. Click en **"Save"**

---

### 5.2 Monitores para LXC 100 - Proxy (192.168.1.100)

**Paso 5.2.1**: Ping del LXC 100

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `Ping`
   - **Friendly Name**: `LXC 100 - proxy (Ping)`
   - **Hostname**: `192.168.1.100`
   - **Heartbeat Interval**: `60` segundos
   - **Timeout**: `10` segundos
   - **Max Packets**: `3`
   - **Parent**: `LXC - Nodo 1 (Infraestructura)`
   - **Tags**: `LXC`, `proxy`, `nodo1`, `infra`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

**Paso 5.2.2**: Nginx Proxy Manager - Web UI

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `HTTP(s)`
   - **Friendly Name**: `Nginx Proxy Manager - Admin`
   - **URL**: `http://192.168.1.100:81`
   - **Heartbeat Interval**: `60` segundos
   - **Request Timeout**: `48` segundos
   - **Accepted Status Codes**: `200-299`
   - **Parent**: `LXC - Nodo 1 (Infraestructura)`
   - **Tags**: `LXC`, `proxy`, `nodo1`, `infra`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

**Paso 5.2.3**: Cloudflared Health Check

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `HTTP(s)`
   - **Friendly Name**: `Cloudflared - Health Check`
   - **URL**: `http://192.168.1.100:2000/ready`
   - **Heartbeat Interval**: `120` segundos
   - **Request Timeout**: `10` segundos
   - **Accepted Status Codes**: `200-299`
   - **Parent**: `LXC - Nodo 1 (Infraestructura)`
   - **Tags**: `cloudflared`, `proxy`, `nodo1`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

**Paso 5.2.4**: Portainer (Opcional)

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `HTTP(s)`
   - **Friendly Name**: `Portainer - LXC 100`
   - **URL**: `https://192.168.1.100:9443`
   - **Heartbeat Interval**: `120` segundos
   - **Ignore TLS/SSL error**: ✅ (si usa certificado autofirmado)
   - **Parent**: `LXC - Nodo 1 (Infraestructura)`
   - **Tags**: `portainer`, `proxy`, `nodo1`
   - **Notifications**: ✅ Telegram
3. Click en **"Save"**

---

### 5.3 Monitores para LXC 101 - Apps (192.168.1.101)

**Paso 5.3.1**: Ping del LXC 101

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `Ping`
   - **Friendly Name**: `LXC 101 - apps (Ping)`
   - **Hostname**: `192.168.1.101`
   - **Heartbeat Interval**: `60` segundos
   - **Parent**: `LXC - Nodo 1 (Infraestructura)`
   - **Tags**: `LXC`, `apps`, `nodo1`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

**Paso 5.3.2**: Vaultwarden Local

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `HTTP(s)`
   - **Friendly Name**: `Vaultwarden - Local`
   - **URL**: `http://192.168.1.101:8080`
   - **Heartbeat Interval**: `60` segundos
   - **Request Timeout**: `48` segundos
   - **Parent**: `LXC - Nodo 1 (Infraestructura)`
   - **Tags**: `vaultwarden`, `apps`, `nodo1`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

---

### 5.4 Monitores para LXC 105 - Uptime Kuma (192.168.1.70)

**Importante**: Este monitor se configurará en LXC 205 (backup) para monitoreo cruzado. Ver sección 6.

---

### 5.5 Monitores para LXC 200 - Mediaserver (192.168.1.50)

**Paso 5.5.1**: Ping del LXC 200

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `Ping`
   - **Friendly Name**: `LXC 200 - mediaserver (Ping)`
   - **Hostname**: `192.168.1.50`
   - **Heartbeat Interval**: `60` segundos
   - **Parent**: `servarr`
   - **Tags**: `LXC`, `media`, `nodo2`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

**Paso 5.5.2**: Bazarr (Faltante)

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `HTTP(s)`
   - **Friendly Name**: `Bazarr`
   - **URL**: `http://192.168.1.50:6767`
   - **Heartbeat Interval**: `120` segundos
   - **Parent**: `servarr`
   - **Tags**: `arr`, `media`, `nodo2`
   - **Notifications**: ✅ Telegram
3. Click en **"Save"**

---

### 5.6 Monitores para LXC 205 - Uptime Kuma Backup (192.168.1.71)

**Importante**: Este monitor se configurará en LXC 105 (principal) para monitoreo cruzado. Ver sección 6.

---

## 6. Configurar Monitoreo Cruzado

Esta es la parte **MÁS IMPORTANTE** para evitar puntos ciegos en tu monitoreo.

### 6.1 Monitor en LXC 105 (vigilando al backup)

**Paso 6.1.1**: Acceder a LXC 105

```
URL: http://192.168.1.70:3001
```

**Paso 6.1.2**: Crear Grupo de Monitoreo Cruzado

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `Group`
   - **Friendly Name**: `Monitoreo de Alta Disponibilidad`
   - **Heartbeat Interval**: `60` segundos
   - **Tags**: `monitoring`, `infra`, `ha`
3. Click en **"Save"**

**Paso 6.1.3**: Crear Monitor para LXC 205

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `HTTP(s)`
   - **Friendly Name**: `[Backup] Uptime Kuma LXC 205`
   - **URL**: `http://192.168.1.71:3001`
   - **Heartbeat Interval**: `120` segundos
   - **Request Timeout**: `10` segundos
   - **Retries**: `2`
   - **Heartbeat Retry Interval**: `60` segundos
   - **Resend Notification if Down X times**: `3` (evita falsos positivos)
   - **Parent**: `Monitoreo de Alta Disponibilidad`
   - **Tags**: `monitoring`, `backup`, `infra`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

---

### 6.2 Monitor en LXC 205 (vigilando al principal)

**Paso 6.2.1**: Acceder a LXC 205

```
URL: http://192.168.1.71:3001
```

**Paso 6.2.2**: Crear Grupo de Monitoreo Cruzado

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `Group`
   - **Friendly Name**: `Monitoreo de Alta Disponibilidad`
   - **Heartbeat Interval**: `60` segundos
   - **Tags**: `monitoring`, `infra`, `ha`
3. Click en **"Save"**

**Paso 6.2.3**: Crear Monitor para LXC 105

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `HTTP(s)`
   - **Friendly Name**: `[Principal] Uptime Kuma LXC 105`
   - **URL**: `http://192.168.1.70:3001`
   - **Heartbeat Interval**: `60` segundos ⚡ (más crítico)
   - **Request Timeout**: `10` segundos
   - **Retries**: `1`
   - **Heartbeat Retry Interval**: `30` segundos
   - **Resend Notification if Down X times**: `1` (alerta inmediata)
   - **Parent**: `Monitoreo de Alta Disponibilidad`
   - **Tags**: `monitoring`, `principal`, `infra`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

**Paso 6.2.4**: Ping del LXC 105

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `Ping`
   - **Friendly Name**: `LXC 105 - uptimekuma (Ping)`
   - **Hostname**: `192.168.1.70`
   - **Heartbeat Interval**: `60` segundos
   - **Parent**: `Monitoreo de Alta Disponibilidad`
   - **Tags**: `monitoring`, `LXC`, `nodo1`
   - **Notifications**: ✅ Telegram, ✅ Webhook
3. Click en **"Save"**

**Paso 6.2.5**: Ping del LXC 205

1. Click en **"+ Add New Monitor"**
2. Configurar:
   - **Monitor Type**: `Ping`
   - **Friendly Name**: `LXC 205 - uptimekuma-backup (Ping)`
   - **Hostname**: `192.168.1.71`
   - **Heartbeat Interval**: `60` segundos
   - **Parent**: `Monitoreo de Alta Disponibilidad`
   - **Tags**: `monitoring`, `LXC`, `nodo2`
   - **Notifications**: ✅ Telegram
3. Click en **"Save"**

---

## 7. Corrección del Monitor Cloudflared

### Problema
Si existe un monitor de Cloudflared con puerto `9090`, debe cambiarse a `2000` con el endpoint `/ready`.

### Solución

**Paso 7.1**: Buscar Monitor Existente

1. En la lista de monitores, buscar cualquier monitor relacionado con "Cloudflared" o "cloudflared"
2. Verificar si la URL contiene el puerto `9090`

**Paso 7.2**: Editar Monitor (si existe)

1. Click en **"Edit"**
2. Cambiar **URL** a: `http://192.168.1.100:2000/ready`
3. **Heartbeat Interval**: `120` segundos
4. Click en **"Save"**

**Paso 7.3**: Si No Existe, Crearlo

Seguir las instrucciones del **Paso 5.2.3** arriba.

---

## 8. Verificación Final

### 8.1 Checklist de Monitores

Verifica que tienes estos grupos y monitores:

**Grupos**:
- ✅ Cloudflare Tunnel + Servicios Públicos (4 monitores)
- ✅ DNS - Adguard Home (3 monitores)
- ✅ Home Assistant - Casa Inteligente (1 monitor)
- ✅ media (2 monitores)
- ✅ Nodo 1 - proxmox (3 monitores)
- ✅ Nodo 2 - proxmedia (3 monitores)
- ✅ servarr (7 monitores + Bazarr)
- ✅ LXC - Nodo 1 (Infraestructura) (6+ monitores)
- ✅ Monitoreo de Alta Disponibilidad (en ambos LXC 105 y 205)

**Total aproximado**: 35-40 monitores

### 8.2 Verificar Estado de Monitores

1. En el dashboard principal, verifica que todos los monitores estén en **verde (UP)**
2. Si hay algún monitor en rojo:
   - Verificar que el servicio esté corriendo
   - Verificar que la IP y puerto sean correctos
   - Revisar logs del monitor (click en el monitor → pestaña "Logs")

### 8.3 Test de Notificaciones

**Paso 8.3.1**: Probar Telegram

1. Seleccionar cualquier monitor crítico
2. Click en **"Edit"**
3. Click en **"Test"** junto a la notificación de Telegram
4. Verificar que recibes el mensaje en Telegram

**Paso 8.3.2**: Probar Webhook de n8n

1. Seleccionar cualquier monitor
2. Click en **"Edit"**
3. Click en **"Test"** junto a la notificación del Webhook
4. Verificar en n8n que se recibió el payload

### 8.4 Simular Caída de Servicio

Para verificar que las alertas funcionan:

1. Desde SSH en Proxmox, detén temporalmente un servicio no crítico:
   ```bash
   pct exec 105 -- docker stop uptime-kuma
   ```

2. Espera 60-120 segundos

3. Verifica que:
   - LXC 205 detecte la caída de LXC 105
   - Recibas una alerta de Telegram con prioridad CRÍTICA
   - El webhook de n8n reciba el evento

4. Reinicia el servicio:
   ```bash
   pct exec 105 -- docker start uptime-kuma
   ```

5. Verifica que recibas la notificación de recuperación

---

## 📊 Resumen de Cambios

| Categoría | Cambios Realizados |
|-----------|-------------------|
| **Correcciones** | 4 (NPM Immich, Grupos Proxmox, Tags VM, Puerto Cloudflared) |
| **Nuevos Grupos** | 3 (Nodo 1, Nodo 2, LXC Infraestructura) |
| **Nuevos Monitores** | ~15 (Nodo 1, LXC 100, 101, 200, 205, monitoreo cruzado) |
| **Reorganizaciones** | 3 monitores movidos al grupo correcto |
| **Estrategias** | Monitoreo cruzado implementado |

---

## 🚀 Próximos Pasos Opcionales

Una vez completada esta guía, considera:

1. **Configurar Status Page Pública**:
   - Settings → Status Pages → Add Status Page
   - Incluir servicios públicos (Cloudflare Tunnel)
   - Compartir URL con usuarios finales

2. **Configurar Monitores Push**:
   - Para scripts de backup
   - Para tareas cron
   - Para procesos automatizados

3. **Integrar Prometheus**:
   - Para métricas avanzadas de Proxmox
   - Usar el exportador de Uptime Kuma

4. **Configurar Mantenimientos Programados**:
   - Crear ventanas de mantenimiento
   - Evitar alertas durante actualizaciones planificadas

---

## ❓ Troubleshooting

### El monitor no se actualiza

- **Solución**: Click en el monitor → "Resume" o reinicia Uptime Kuma

### No recibo notificaciones de Telegram

- **Verificar**: Settings → Notifications → Telegram → Test
- **Revisar**: Token del bot y Chat ID

### Monitor marca DOWN pero el servicio funciona

- **Posibles causas**:
  - Firewall bloqueando
  - Timeout muy bajo
  - Servicio lento en responder
- **Solución**: Aumentar Request Timeout o Retries

### Uptime Kuma consume mucha RAM

- **Causa**: Demasiados monitores con intervalos muy bajos
- **Solución**: Aumentar intervalos de monitores no críticos a 120-300s

---

**¿Dudas?** Consulta la documentación oficial: https://github.com/louislam/uptime-kuma/wiki

**Última actualización**: 2025-11-19
