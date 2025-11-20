# Plantillas de Notificación Uptime Kuma - Telegram

Documentación de plantillas optimizadas para reducir ruido en notificaciones.

---

## 📋 Versiones Disponibles

### v2.1 (Original)
- **Archivo**: Plantilla actual del usuario
- **Comportamiento**: Notifica TODO (cada heartbeat)
- **Problema**: Spam de notificaciones

### v3.0 (Filtro por mensaje)
- **Archivo**: `uptime-kuma-telegram-template-v3.liquid`
- **Comportamiento**: Solo notifica si `msg` contiene "down", "up", "offline" u "online"
- **Limitación**: Depende del contenido del mensaje

### v3.1 (Recomendada - Filtro por estado)
- **Archivo**: `uptime-kuma-telegram-template-v3.1.liquid`
- **Comportamiento**: Solo notifica cuando `heartbeatJSON.status` cambia
- **Ventaja**: Más confiable, usa el estado real del heartbeat

---

## 🎯 Plantilla Recomendada: v3.1

Esta versión es la más robusta porque verifica el estado directamente en el JSON del heartbeat.

### Lógica de Filtrado

```liquid
{%- assign should_notify = false -%}

{%- comment -%}
Verificar si es un cambio de estado real:
- status == 0: Servicio CAÍDO
- status == 1: Servicio ARRIBA
Solo notificar en estos casos específicos
{%- endcomment -%}

{%- if heartbeatJSON -%}
  {%- if heartbeatJSON.status == 0 -%}
    {%- comment -%}Servicio CAÍDO - siempre notificar{%- endcomment -%}
    {%- assign should_notify = true -%}
  {%- elsif heartbeatJSON.status == 1 -%}
    {%- comment -%}
    Servicio ARRIBA - solo notificar si el mensaje indica recuperación
    {%- endcomment -%}
    {%- assign msg_lower = msg | downcase -%}
    {%- if msg_lower contains "up" or msg_lower contains "recovered" or msg_lower contains "online" -%}
      {%- assign should_notify = true -%}
    {%- endif -%}
  {%- endif -%}
{%- endif -%}
```

### Comportamiento

| Evento | Estado | Notifica | Razón |
|--------|--------|----------|-------|
| Servicio cae | `status: 0` | ✅ SÍ | Siempre alerta cuando algo falla |
| Servicio se recupera | `status: 1` + msg "up" | ✅ SÍ | Confirma recuperación |
| Heartbeat normal | `status: 1` | ❌ NO | Servicio funcionando, no molestar |
| Heartbeat normal (crítico) | `status: 1` + tag LXC | ❌ NO | Aunque sea crítico, si está UP no notifica |

---

## 🔧 Implementación

### Paso 1: Copiar plantilla

Copia el contenido de `uptime-kuma-telegram-template-v3.1.liquid` (abajo)

### Paso 2: Actualizar en Uptime Kuma

1. Ir a http://192.168.1.70:3001
2. **Settings** → **Notifications**
3. Editar notificación **"Telegram Navi - Racherd"**
4. Scroll hasta **"Custom Message Template"**
5. Pegar la nueva plantilla
6. **Save**

### Paso 3: Probar

1. Pausar un monitor temporalmente
2. Verificar que recibes notificación de DOWN 🔴
3. Reanudar monitor
4. Verificar que recibes notificación de UP ✅
5. Dejar monitor corriendo
6. **NO** deberías recibir más notificaciones

---

## 📊 Comparación de Ruido

**Antes (v2.1)**:
- Monitor con intervalo 60s
- 24 monitores
- Notificaciones por hora: **~1,440** 😱
- Notificaciones por día: **~34,560** 💀

**Después (v3.1)**:
- Solo cambios de estado
- Promedio (asumiendo 99% uptime): **~24 eventos/día** 
- Reducción: **99.93%** 🎉

---

## 🎨 Personalización

### Solo Alertas Críticas

Si solo quieres notificaciones de servicios críticos:

```liquid
{%- assign should_notify = false -%}
{%- assign is_critical = false -%}

{%- capture tag_names -%}
  {%- if monitorJSON and monitorJSON.tags -%}
    {%- for t in monitorJSON.tags -%}
      {{ t.name | downcase }},
    {%- endfor -%}
  {%- endif -%}
{%- endcapture -%}

{%- if tag_names contains "lxc" or tag_names contains "proxmox" or tag_names contains "vaultwarden" -%}
  {%- assign is_critical = true -%}
{%- endif -%}

{%- if is_critical and heartbeatJSON.status == 0 -%}
  {%- assign should_notify = true -%}
{%- endif -%}

{%- unless should_notify -%}
  {%- comment -%}No notificar{%- endcomment -%}
{%- else -%}
  {%- comment -%}Resto de la plantilla...{%- endcomment -%}
{%- endunless -%}
```

### Solo Servicios Caídos (Sin recuperación)

```liquid
{%- assign should_notify = heartbeatJSON.status == 0 -%}
```

### Horario de Silencio (Ej: 23:00 - 07:00)

```liquid
{%- assign current_hour = "now" | date: "%H" | times: 1 -%}
{%- assign is_quiet_hours = current_hour >= 23 or current_hour < 7 -%}

{%- if is_quiet_hours and heartbeatJSON.status == 1 -%}
  {%- comment -%}No notificar recuperaciones en horario silencioso{%- endcomment -%}
  {%- assign should_notify = false -%}
{%- endif -%}
```

---

## 🐛 Troubleshooting

### Sigo recibiendo muchas notificaciones

**Causa**: La plantilla puede no estar aplicada correctamente.

**Solución**:
1. Verificar que guardaste la plantilla
2. Verificar que está en la notificación correcta (Telegram)
3. Hacer un test de la notificación
4. Revisar logs de Uptime Kuma para ver qué se envía

### No recibo ninguna notificación

**Causa**: Filtro muy estricto o variable incorrecta.

**Debug**: Agregar al inicio de la plantilla:

```liquid
DEBUG - msg: {{ msg }}
DEBUG - status: {{ heartbeatJSON.status }}
DEBUG - should_notify: {{ should_notify }}
━━━━━━━━━━━━━━━━━━━━
```

Esto te mostrará en Telegram qué valores tiene cada variable.

### Quiero notificaciones SOLO de servicios críticos caídos

Usa esta versión simplificada al inicio:

```liquid
{%- assign tag_names = "" -%}
{%- if monitorJSON and monitorJSON.tags -%}
  {%- for t in monitorJSON.tags -%}
    {%- assign tag_names = tag_names | append: t.name | downcase | append: "," -%}
  {%- endfor -%}
{%- endif -%}

{%- assign is_critical = tag_names contains "lxc" or tag_names contains "proxmox" or tag_names contains "vaultwarden" -%}
{%- assign is_down = heartbeatJSON.status == 0 -%}

{%- unless is_critical and is_down -%}
  {%- comment -%}No notificar{%- endcomment -%}
{%- else -%}
  {%- comment -%}Plantilla normal...{%- endcomment -%}
{%- endunless -%}
```

---

## 📝 Variables Disponibles en Uptime Kuma

```liquid
{{ name }}                    # Nombre del monitor
{{ msg }}                     # Mensaje (ej: "Down", "Up")
{{ status }}                  # Texto del estado
{{ hostnameOrURL }}           # URL o hostname

{{ heartbeatJSON.status }}    # 0 = DOWN, 1 = UP
{{ heartbeatJSON.ping }}      # Ping en ms
{{ heartbeatJSON.msg }}       # Mensaje de error detallado
{{ heartbeatJSON.localDateTime }}  # Timestamp local
{{ heartbeatJSON.timezone }}  # Zona horaria

{{ monitorJSON.type }}        # Tipo de monitor (http, ping, etc)
{{ monitorJSON.pathName }}    # Ruta jerárquica (Grupo / Monitor)
{{ monitorJSON.tags }}        # Array de tags
```

---

## ✅ Checklist de Implementación

- [ ] Backup de plantilla actual (copiar a un .txt)
- [ ] Copiar nueva plantilla v3.1
- [ ] Pegar en Uptime Kuma (Settings → Notifications → Telegram)
- [ ] Guardar cambios
- [ ] Probar pausando un monitor no crítico
- [ ] Verificar que recibe DOWN
- [ ] Reanudar monitor
- [ ] Verificar que recibe UP
- [ ] Esperar 5 minutos sin hacer nada
- [ ] Confirmar que NO recibe notificaciones de heartbeats normales
- [ ] Aplicar la misma plantilla en LXC 205 (backup) si está activa

---

## 🔗 Archivos Relacionados

- Plantilla actual: (en configuración de Telegram en Uptime Kuma)
- Plantilla v3.0: `configs/containers/uptime-kuma-telegram-template-v3.liquid`
- Plantilla v3.1: `configs/containers/uptime-kuma-telegram-template-v3.1.liquid`
- Documentación: `docs/uptime-kuma-telegram-templates.md`
