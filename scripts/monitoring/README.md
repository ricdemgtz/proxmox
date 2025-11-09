# Scripts de Monitoreo / Monitoring Scripts

Este directorio contiene scripts para monitorear el estado y rendimiento del servidor Proxmox.

## Scripts Disponibles

### monitor-resources.sh
Script principal para monitorear recursos del sistema.

**Características:**
- Monitoreo de CPU, RAM y disco
- Estado de VMs y contenedores
- Estado de servicios críticos de Proxmox
- Sistema de alertas configurable
- Logging de todas las métricas

**Configuración:**
```bash
ALERT_CPU_THRESHOLD=80      # % CPU para alertar
ALERT_RAM_THRESHOLD=85      # % RAM para alertar
ALERT_DISK_THRESHOLD=90     # % Disco para alertar
```

**Uso:**
```bash
chmod +x monitor-resources.sh
./monitor-resources.sh
```

## Automatización

### Monitoreo Continuo con Cron

```bash
# Editar crontab
crontab -e

# Monitoreo cada 5 minutos
*/5 * * * * /root/scripts/monitoring/monitor-resources.sh

# Reporte diario a las 8:00 AM
0 8 * * * /root/scripts/monitoring/daily-report.sh
```

## Sistema de Alertas

### Configurar Alertas por Email

1. Instalar mailutils:
```bash
apt-get install mailutils
```

2. Configurar en el script:
```bash
send_alert() {
    local message=$1
    echo "$message" | mail -s "Alerta Proxmox $(hostname)" admin@example.com
}
```

### Integración con Telegram

```bash
send_telegram() {
    local message=$1
    local bot_token="TU_BOT_TOKEN"
    local chat_id="TU_CHAT_ID"
    
    curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
        -d chat_id="${chat_id}" \
        -d text="${message}"
}
```

### Integración con Discord

```bash
send_discord() {
    local message=$1
    local webhook_url="TU_WEBHOOK_URL"
    
    curl -H "Content-Type: application/json" \
        -d "{\"content\": \"${message}\"}" \
        "${webhook_url}"
}
```

## Métricas Importantes

### CPU
- Uso promedio
- Procesos con mayor consumo
- Load average

### RAM
- Uso de memoria física
- Swap usage
- Cache/Buffers

### Disco
- Uso por partición
- I/O stats
- Storage pools de Proxmox

### Red
- Tráfico de red
- Errores de interfaz
- Conexiones activas

### VMs/Contenedores
- Estado (running/stopped)
- Uso de recursos
- Uptime

## Herramientas Adicionales de Monitoreo

### Proxmox Nativo
- **pvesh**: CLI para API de Proxmox
- **pveperf**: Test de rendimiento
- **pveceph**: Monitoreo de Ceph (si aplica)

### Herramientas Externas
- **Grafana + InfluxDB**: Dashboards visuales
- **Prometheus**: Métricas y alertas
- **Zabbix**: Monitoreo empresarial
- **Netdata**: Monitoreo en tiempo real
- **Check_MK**: Monitoreo integral

## Ejemplo de Dashboard en Grafana

```bash
# Instalar InfluxDB
apt-get install influxdb influxdb-client

# Instalar Telegraf para recolectar métricas
apt-get install telegraf

# Configurar telegraf para Proxmox
# /etc/telegraf/telegraf.conf
```

## Logs a Monitorear

Ubicaciones importantes de logs:

```bash
/var/log/syslog           # Log del sistema
/var/log/pve/             # Logs de Proxmox
/var/log/pveproxy/        # Logs del proxy web
/var/log/pvedaemon.log    # Logs del daemon
```

## Mejores Prácticas

1. **No monitorear demasiado**: Enfócate en métricas relevantes
2. **Umbrales realistas**: Ajusta umbrales según tu carga normal
3. **Retención de logs**: Rota logs para no llenar el disco
4. **Alertas significativas**: Evita alert fatigue
5. **Documentación**: Documenta qué hacer cuando suena una alerta
