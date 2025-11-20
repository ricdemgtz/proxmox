# Configuración Dual: Telegram (Solo Críticos) + n8n (Todas las Alertas)

**Fecha**: 2025-11-19  
**Estrategia**: Separación de responsabilidades

---

## 🎯 Estrategia de Notificaciones

### Telegram (Usuario Final)
- **Propósito**: Alertas críticas que requieren atención inmediata
- **Filtro**: Solo servicios con tags `LXC`, `proxmox`, `vaultwarden`
- **Eventos**: DOWN y UP de servicios críticos
- **Plantilla**: v4.0 (uptime-kuma-telegram-template-v3.1.liquid)

### n8n Webhook (Automatización)
- **Propósito**: Recibir TODAS las alertas para análisis y quickfixes
- **Filtro**: Ninguno (recibe todo)
- **Eventos**: Todos los cambios de estado
- **Procesamiento**: n8n decide qué hacer (notificar, ignorar, ejecutar acción)

---

## 📋 Configuración en Uptime Kuma

### Paso 1: Actualizar Notificación de Telegram

1. Ir a http://192.168.1.70:3001
2. **Settings** → **Notifications**
3. Editar **"Telegram Navi - Racherd"**
4. En **"Custom Message Template"**: Copiar contenido de `uptime-kuma-telegram-template-v3.1.liquid`
5. **Save**

**Resultado**: Solo recibirás en Telegram alertas de servicios críticos.

---

### Paso 2: Configurar Notificación n8n Webhook

#### 2.1 Crear Webhook en n8n (si no existe)

1. Abrir n8n: http://[IP-N8N]:5678
2. Crear nuevo workflow: **"Uptime Kuma - Quickfixes"**
3. Agregar nodo **Webhook**:
   - **Webhook Name**: uptime-kuma-alerts
   - **Method**: POST
   - **Path**: /webhook/uptime-kuma
   - **Response Mode**: Last Node
   - **Response Code**: 200

4. Copiar URL del webhook (ejemplo):
   ```
   http://192.168.1.XXX:5678/webhook/uptime-kuma
   ```

#### 2.2 Agregar Webhook en Uptime Kuma

1. En Uptime Kuma: **Settings** → **Notifications**
2. Click **"Add Notification"** o editar webhook existente
3. Configurar:
   - **Notification Type**: Webhook
   - **Friendly Name**: n8n Quickfixes
   - **URL**: `http://[IP-N8N]:5678/webhook/uptime-kuma`
   - **Method**: POST
   - **Content Type**: application/json
   - **Headers** (opcional): 
     ```
     Authorization: Bearer tu-token-secreto
     ```

4. **NO agregar Custom Template** (dejar vacío para enviar JSON completo)

5. Click **"Apply on all existing monitors"** ✅

6. **Test** para verificar conectividad

7. **Save**

---

## 🔧 Workflow n8n - Ejemplo Básico

### Estructura del Workflow

```
Webhook → IF (Filtro) → Switch (Tipo de Alerta) → Acciones
```

### Ejemplo de Configuración

#### Nodo 1: Webhook
- Recibe el payload completo de Uptime Kuma

#### Nodo 2: Set Variables
```javascript
{
  "service": "{{ $json.name }}",
  "status": "{{ $json.heartbeatJSON.status }}",
  "msg": "{{ $json.msg }}",
  "isDown": "{{ $json.heartbeatJSON.status === 0 }}",
  "tags": "{{ $json.monitorJSON.tags }}",
  "type": "{{ $json.monitorJSON.type }}",
  "url": "{{ $json.hostnameOrURL }}"
}
```

#### Nodo 3: IF - Filtrar Solo DOWN
```javascript
{{ $json.heartbeatJSON.status }} === 0
```

#### Nodo 4: Switch - Tipo de Servicio
Según tags o nombre:
- **Case 1**: Tag contiene "docker" → Reiniciar contenedor
- **Case 2**: Tag contiene "lxc" → Verificar recursos
- **Case 3**: Tag contiene "proxmox" → Alerta urgente
- **Default**: Log para análisis

#### Nodo 5A: HTTP Request - Restart Docker Container
```javascript
POST http://192.168.1.100/api/containers/{{ $json.containerName }}/restart
```

#### Nodo 5B: Telegram - Alerta Urgente Proxmox
Solo para servicios críticos que n8n no puede autoarreglar

#### Nodo 5C: Database - Log para Análisis
Guardar todas las alertas para análisis de patrones

---

## 📊 Ejemplo de Payload de Uptime Kuma

```json
{
  "name": "Jellyfin",
  "msg": "Down",
  "status": "🔴 Down",
  "hostnameOrURL": "http://192.168.1.50:8096",
  "heartbeatJSON": {
    "status": 0,
    "ping": null,
    "msg": "connect ECONNREFUSED 192.168.1.50:8096",
    "localDateTime": "2025-11-19 20:15:30",
    "timezone": "America/Mexico_City"
  },
  "monitorJSON": {
    "type": "http",
    "pathName": "servarr / Jellyfin",
    "tags": [
      { "name": "arr", "color": "#ff6b6b" },
      { "name": "media", "color": "#4ecdc4" },
      { "name": "nodo2", "color": "#45b7d1" }
    ]
  }
}
```

---

## 🎨 Workflow n8n - Quickfixes Inteligentes

### Ejemplo 1: Reiniciar Contenedor Docker Automáticamente

**Trigger**: Servicio con tag "docker" marca DOWN  
**Acción**: 
1. Esperar 30 segundos (verificar si es temporal)
2. Si sigue DOWN: reiniciar contenedor via API
3. Esperar 1 minuto
4. Verificar si se recuperó
5. Si NO: enviar alerta a Telegram
6. Si SÍ: enviar confirmación silenciosa

### Ejemplo 2: Alertar Solo Después de Múltiples Fallas

**Trigger**: Cualquier servicio marca DOWN  
**Acción**:
1. Guardar en base de datos temporal
2. Contar fallas en últimos 5 minutos
3. Si fallas > 3: enviar alerta
4. Si fallas <= 3: solo log

### Ejemplo 3: Diagnóstico Automático

**Trigger**: LXC marca DOWN  
**Acción**:
1. SSH a Proxmox
2. Ejecutar `pct status <id>`
3. Ejecutar `pct exec <id> -- systemctl status`
4. Parsear salida
5. Enviar diagnóstico a Telegram con quickfix sugerido

---

## 🔒 Seguridad del Webhook

### Opción 1: Token en Header (Recomendado)

**En Uptime Kuma**:
```
Headers:
Authorization: Bearer tu-token-secreto-largo-y-aleatorio
```

**En n8n Webhook**:
```javascript
// Nodo Function después del Webhook
const authHeader = $input.first().json.headers.authorization;
if (authHeader !== 'Bearer tu-token-secreto-largo-y-aleatorio') {
  throw new Error('Unauthorized');
}
return $input.all();
```

### Opción 2: IP Whitelist

Solo permitir conexiones desde IP de Uptime Kuma:
- LXC 105: 192.168.1.70
- LXC 205: 192.168.1.71

Configurar en n8n o en firewall.

---

## 📋 Checklist de Implementación

### Telegram (Solo Críticos)
- [ ] Actualizar plantilla a v4.0
- [ ] Guardar y verificar sin error 400
- [ ] Probar con un servicio crítico (pausar/reanudar)
- [ ] Confirmar que recibe DOWN
- [ ] Confirmar que recibe UP
- [ ] Verificar que NO recibe heartbeats normales
- [ ] Verificar que NO recibe alertas de servicios no críticos

### n8n Webhook (Todas las Alertas)
- [ ] Crear workflow en n8n
- [ ] Configurar nodo Webhook
- [ ] Copiar URL del webhook
- [ ] Agregar notificación en Uptime Kuma
- [ ] Aplicar a todos los monitores
- [ ] Probar con Test
- [ ] Verificar que n8n recibe el payload
- [ ] Configurar lógica de quickfixes
- [ ] Probar con servicio DOWN real

---

## 🧪 Pruebas

### Test 1: Servicio Crítico Cae

1. Pausar monitor **"VM 104 - haOS (PING)"** (tiene tag LXC)
2. **Telegram**: Debe recibir alerta 🚨🔴
3. **n8n**: Debe recibir payload completo

### Test 2: Servicio No Crítico Cae

1. Pausar monitor **"Jellyfin"** (NO tiene tags críticos)
2. **Telegram**: NO debe recibir nada
3. **n8n**: Debe recibir payload completo

### Test 3: Servicio Crítico Se Recupera

1. Reanudar monitor **"VM 104 - haOS (PING)"**
2. **Telegram**: Debe recibir recuperación ✅💚
3. **n8n**: Debe recibir payload completo

### Test 4: Heartbeat Normal

1. Esperar 5 minutos sin tocar nada
2. **Telegram**: NO debe recibir nada
3. **n8n**: NO debe recibir nada (solo en cambios de estado)

---

## 📊 Monitoreo de n8n

### Verificar Ejecuciones

1. En n8n: **Executions** tab
2. Filtrar por workflow "Uptime Kuma - Quickfixes"
3. Ver payload recibido
4. Ver acciones ejecutadas
5. Ver errores si los hay

### Debug Mode

En el workflow de n8n, agregar nodo **"Send to Telegram"** temporal:
```
Webhook → Set → Telegram (debug)
```

Esto envía a Telegram el payload completo para verificar estructura.

---

## 🔗 Recursos

- Plantilla Telegram v4.0: `configs/containers/uptime-kuma-telegram-template-v3.1.liquid`
- Documentación plantillas: `docs/uptime-kuma-telegram-templates.md`
- n8n Documentation: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
- Uptime Kuma API: https://github.com/louislam/uptime-kuma/wiki/API

---

## ✅ Resultado Final

**Telegram (Usuario)**:
- Solo alertas críticas que requieren atención humana
- DOWN y UP de servicios importantes
- Reducción de ruido: ~99.9%

**n8n (Automatización)**:
- Todas las alertas para análisis
- Quickfixes automáticos
- Reintentos inteligentes
- Diagnóstico automatizado
- Log completo de eventos

**Ambos sistemas trabajando juntos** = Monitoreo inteligente y proactivo 🚀
