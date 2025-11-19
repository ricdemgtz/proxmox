# Migración de Uptime Kuma de SQLite a PostgreSQL

## 🎯 Objetivo

Migrar la base de datos de Uptime Kuma desde SQLite (archivo local) a PostgreSQL en contenedor Docker separado para:
- **Backups más fáciles**: `pg_dump` remoto sin acceso al LXC
- **Consultas desde fuera**: Acceso directo a la BD desde cualquier cliente SQL
- **Escalabilidad**: Mejor rendimiento con muchos monitores
- **Sincronización**: Más fácil replicar entre LXC 105 y 205

## 📋 Arquitectura Propuesta

```
LXC 105 (uptimekuma) - 192.168.1.70
├─── Docker: uptime-kuma:1 → PostgreSQL en puerto 5432 (interno)
├─── Docker: postgres:16-alpine → Puerto 5433 (expuesto)
└─── Docker: pgAdmin4 (opcional) → Puerto 5050
```

## 🔧 Paso 1: Crear LXC para Base de Datos (Opción A - Recomendada)

Si prefieres PostgreSQL en LXC dedicado:

```bash
# Crear LXC 106 en nodo proxmox
pct create 106 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
  --hostname postgres-db \
  --cores 2 \
  --memory 2048 \
  --swap 512 \
  --storage local-lvm \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp,firewall=1 \
  --unprivileged 1 \
  --features nesting=1 \
  --onboot 1 \
  --password

# Iniciar LXC
pct start 106

# Instalar Docker
pct exec 106 -- bash -c "curl -fsSL https://get.docker.com | sh"

# Crear stack PostgreSQL
pct exec 106 -- mkdir -p /opt/postgres
```

### docker-compose.yml para LXC 106

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: postgres-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: uptimekuma
      POSTGRES_PASSWORD: ChangeThisSecurePassword123!
      POSTGRES_DB: uptimekuma
    ports:
      - "5432:5432"
    volumes:
      - ./data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U uptimekuma"]
      interval: 10s
      timeout: 5s
      retries: 5

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: pgadmin
    restart: unless-stopped
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@uptimekuma.local
      PGADMIN_DEFAULT_PASSWORD: ChangeThisPassword123!
    ports:
      - "5050:80"
    depends_on:
      - postgres
```

**Obtener IP del LXC 106**:
```bash
pct exec 106 -- ip addr show eth0 | grep "inet "
# Anotar IP (ej: 192.168.1.106)
```

## 🔧 Paso 2: Crear PostgreSQL en Docker (Opción B - Más Simple)

Agregar PostgreSQL al mismo LXC 105:

```bash
# SSH a proxmox
ssh root@192.168.1.78

# Crear carpeta para PostgreSQL
pct exec 105 -- mkdir -p /opt/postgres

# Crear docker-compose.yml
pct exec 105 -- tee /opt/postgres/docker-compose.yml > /dev/null << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: uptime-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: uptimekuma
      POSTGRES_PASSWORD: kuma_secure_2024
      POSTGRES_DB: kuma_db
    ports:
      - "5433:5432"  # Puerto 5433 para evitar conflicto
    volumes:
      - ./data:/var/lib/postgresql/data
    networks:
      - uptime-net

networks:
  uptime-net:
    external: true
EOF

# Crear red Docker compartida
pct exec 105 -- docker network create uptime-net

# Iniciar PostgreSQL
pct exec 105 -- bash -c "cd /opt/postgres && docker compose up -d"

# Verificar
pct exec 105 -- docker ps | grep postgres
```

## 📊 Paso 3: Exportar Datos de SQLite

**Desde dentro del LXC 105** (única forma de acceder a SQLite):

```bash
# Entrar al LXC
pct enter 105

# Navegar a la carpeta de Uptime Kuma
cd /opt/uptime-kuma/data

# Instalar sqlite3 si no existe
apt update && apt install -y sqlite3

# Exportar monitores a SQL
sqlite3 kuma.db << 'EOF' > /tmp/monitors-export.sql
.mode insert monitor
SELECT * FROM monitor;
EOF

# Exportar notificaciones
sqlite3 kuma.db << 'EOF' > /tmp/notifications-export.sql
.mode insert notification
SELECT * FROM notification;
EOF

# Exportar relaciones monitor-notification
sqlite3 kuma.db << 'EOF' > /tmp/monitor-notification-export.sql
.mode insert monitor_notification
SELECT * FROM monitor_notification;
EOF

# Ver monitores actuales (formato legible)
sqlite3 kuma.db << 'EOF'
.mode column
.headers on
SELECT 
    id,
    name,
    type,
    url,
    interval,
    active
FROM monitor
ORDER BY id;
EOF

# Copiar exports fuera del contenedor
cp /tmp/*-export.sql /opt/uptime-kuma/data/
exit
```

**Desde el host Proxmox**, copiar los exports:

```bash
# Copiar SQL exports al host
pct pull 105 /opt/uptime-kuma/data/monitors-export.sql /root/monitors-export.sql
pct pull 105 /opt/uptime-kuma/data/notifications-export.sql /root/notifications-export.sql

# Ver contenido
cat /root/monitors-export.sql
```

## 🔄 Paso 4: Configurar Uptime Kuma para PostgreSQL

### Modificar docker-compose.yml de Uptime Kuma

```bash
# Editar configuración actual
pct exec 105 -- nano /opt/uptime-kuma/docker-compose.yml
```

**Agregar variables de entorno** (con PostgreSQL en LXC 106):

```yaml
version: '3.8'

services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - ./data:/app/data
    environment:
      # Configuración de PostgreSQL
      UPTIME_KUMA_DB_TYPE: postgres
      UPTIME_KUMA_DB_HOST: 192.168.1.106  # IP del LXC 106 con PostgreSQL
      UPTIME_KUMA_DB_PORT: 5432
      UPTIME_KUMA_DB_NAME: uptimekuma
      UPTIME_KUMA_DB_USERNAME: uptimekuma
      UPTIME_KUMA_DB_PASSWORD: ChangeThisSecurePassword123!
```

**O si PostgreSQL está en el mismo LXC 105**:

```yaml
    environment:
      UPTIME_KUMA_DB_TYPE: postgres
      UPTIME_KUMA_DB_HOST: uptime-postgres  # Nombre del contenedor
      UPTIME_KUMA_DB_PORT: 5432
      UPTIME_KUMA_DB_USERNAME: uptimekuma
      UPTIME_KUMA_DB_PASSWORD: kuma_secure_2024
      UPTIME_KUMA_DB_NAME: kuma_db
    networks:
      - uptime-net
```

## ⚠️ Paso 5: Migración de Datos

**Opción 1: Backup/Restore desde Web UI** (Más Fácil)

1. **Backup desde SQLite**:
   - Acceder a http://192.168.1.70:3001
   - Settings → Backup → Export Backup
   - Descargar archivo JSON con toda la configuración

2. **Reiniciar con PostgreSQL**:
```bash
# Detener Uptime Kuma actual
pct exec 105 -- bash -c "cd /opt/uptime-kuma && docker compose down"

# Renombrar carpeta data antigua
pct exec 105 -- mv /opt/uptime-kuma/data /opt/uptime-kuma/data-sqlite-backup

# Crear nueva carpeta vacía
pct exec 105 -- mkdir /opt/uptime-kuma/data

# Iniciar con PostgreSQL
pct exec 105 -- bash -c "cd /opt/uptime-kuma && docker compose up -d"

# Ver logs
pct exec 105 -- docker logs -f uptime-kuma
```

3. **Restore desde Web UI**:
   - Acceder a http://192.168.1.70:3001
   - Crear cuenta nueva
   - Settings → Backup → Import Backup
   - Subir archivo JSON descargado

**Opción 2: Script de Migración Manual** (Avanzado)

```bash
# Conectar a PostgreSQL y crear tablas manualmente
# Luego importar datos desde SQL exports
psql -h 192.168.1.106 -U uptimekuma -d uptimekuma < /root/monitors-export.sql
```

## 🔍 Paso 6: Verificar Migración

```bash
# Conectar a PostgreSQL desde cualquier lugar
psql -h 192.168.1.106 -p 5432 -U uptimekuma -d uptimekuma

# O si está en el mismo LXC
pct exec 105 -- docker exec -it uptime-postgres psql -U uptimekuma -d kuma_db

# Consultar monitores
SELECT id, name, type, url, active FROM monitor;

# Contar monitores
SELECT COUNT(*) FROM monitor;

# Ver notificaciones
SELECT id, name, type FROM notification;
```

## 💾 Paso 7: Backup de PostgreSQL (Mucho Más Fácil)

```bash
# Crear script de backup en Proxmox host
cat > /root/backup-uptimekuma-db.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/root/backups/uptimekuma-db"
DATE=$(date +%Y%m%d_%H%M%S)
DB_HOST="192.168.1.106"  # O IP del LXC con PostgreSQL

mkdir -p "$BACKUP_DIR"

# Backup completo
docker exec uptime-postgres pg_dump -U uptimekuma kuma_db | \
  gzip > "$BACKUP_DIR/kuma-db-$DATE.sql.gz"

# Retención de 14 días
find "$BACKUP_DIR" -name "kuma-db-*.sql.gz" -mtime +14 -delete

echo "[$(date)] Backup completado: kuma-db-$DATE.sql.gz"
EOF

chmod +x /root/backup-uptimekuma-db.sh

# Agregar a cron (diario a las 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /root/backup-uptimekuma-db.sh >> /var/log/uptimekuma-backup.log 2>&1") | crontab -
```

## 📊 Ventajas de PostgreSQL vs SQLite

| Característica | SQLite | PostgreSQL |
|----------------|--------|------------|
| Acceso remoto | ❌ Solo local | ✅ Desde cualquier IP |
| Backups | ❌ Copiar archivo (requiere detener servicio) | ✅ `pg_dump` en caliente |
| Consultas externas | ❌ Requiere acceso al LXC | ✅ Cualquier cliente SQL |
| Concurrencia | ⚠️ Limitada | ✅ Excelente |
| Replicación | ❌ Manual | ✅ Streaming replication |
| Monitoreo | ❌ Difícil | ✅ pgAdmin, herramientas SQL |
| Rendimiento (muchos monitores) | ⚠️ Degrada | ✅ Escalable |

## 🔧 Configuración Avanzada: Replicación entre Nodos

Con PostgreSQL, sincronizar entre LXC 105 y 205 es trivial:

```bash
# LXC 205 apunta a la MISMA base de datos que LXC 105
# No requiere sincronización de archivos

# docker-compose.yml en LXC 205
environment:
  UPTIME_KUMA_DB_HOST: 192.168.1.106  # Misma IP PostgreSQL
  UPTIME_KUMA_DB_PORT: 5432
  # ... mismas credenciales
```

Ambas instancias leen/escriben la misma BD → **sincronización automática**.

## 📝 Checklist de Migración

- [ ] **Fase 1: Preparación**
  - [ ] Crear LXC 106 para PostgreSQL (o usar LXC 105)
  - [ ] Instalar Docker en LXC 106
  - [ ] Desplegar PostgreSQL con docker-compose
  - [ ] Verificar conectividad: `telnet 192.168.1.106 5432`

- [ ] **Fase 2: Backup SQLite**
  - [ ] Acceder a Web UI de Uptime Kuma
  - [ ] Settings → Backup → Export Backup (descargar JSON)
  - [ ] Guardar backup en seguridad

- [ ] **Fase 3: Migración**
  - [ ] Detener Uptime Kuma: `docker compose down`
  - [ ] Renombrar carpeta data antigua
  - [ ] Modificar docker-compose.yml con variables PostgreSQL
  - [ ] Iniciar con PostgreSQL: `docker compose up -d`
  - [ ] Verificar logs: `docker logs uptime-kuma`

- [ ] **Fase 4: Restore**
  - [ ] Acceder a Web UI (nueva instalación)
  - [ ] Crear cuenta admin
  - [ ] Settings → Backup → Import Backup
  - [ ] Subir archivo JSON del paso 2
  - [ ] Verificar monitores y notificaciones

- [ ] **Fase 5: Validación**
  - [ ] Probar conectividad a PostgreSQL desde host
  - [ ] Ejecutar consultas SQL para verificar datos
  - [ ] Probar notificaciones (enviar test)
  - [ ] Verificar webhook de n8n

- [ ] **Fase 6: Replicación**
  - [ ] Modificar LXC 205 para usar misma BD
  - [ ] Reiniciar LXC 205
  - [ ] Verificar ambos nodos leen mismos datos

- [ ] **Fase 7: Backups Automáticos**
  - [ ] Crear script `/root/backup-uptimekuma-db.sh`
  - [ ] Configurar cron job
  - [ ] Probar backup manual
  - [ ] Verificar restauración: `gunzip < backup.sql.gz | psql ...`

## 🚨 Rollback (Si Algo Falla)

```bash
# Detener Uptime Kuma con PostgreSQL
pct exec 105 -- bash -c "cd /opt/uptime-kuma && docker compose down"

# Restaurar carpeta SQLite original
pct exec 105 -- rm -rf /opt/uptime-kuma/data
pct exec 105 -- mv /opt/uptime-kuma/data-sqlite-backup /opt/uptime-kuma/data

# Eliminar variables de PostgreSQL del docker-compose.yml
pct exec 105 -- nano /opt/uptime-kuma/docker-compose.yml
# (Borrar sección environment)

# Reiniciar con SQLite
pct exec 105 -- bash -c "cd /opt/uptime-kuma && docker compose up -d"
```

## 📚 Recursos

- [Uptime Kuma Database Configuration](https://github.com/louislam/uptime-kuma/wiki/Database)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)

---

**Ventaja Principal**: Con PostgreSQL puedes ejecutar este comando **desde tu Windows**:

```powershell
# Consultar monitores remotamente
psql -h 192.168.1.106 -U uptimekuma -d uptimekuma -c "SELECT name, url, active FROM monitor;"
```

Sin necesidad de entrar al LXC. 🎯
