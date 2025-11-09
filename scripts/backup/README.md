# Scripts de Backup / Backup Scripts

Este directorio contiene scripts para realizar respaldos automáticos del servidor Proxmox.

## Scripts Disponibles

### backup-vms.sh
Script principal para realizar backups de VMs y contenedores.

**Características:**
- Backup de VMs y contenedores especificados
- Múltiples modos: snapshot, suspend, stop
- Compresión configurable (gzip, zstd)
- Limpieza automática de backups antiguos
- Logging detallado

**Configuración:**
Edita las variables en el script:
```bash
VMS="100 101 102"              # IDs de VMs a respaldar
CONTAINERS="100 101"           # IDs de contenedores a respaldar
BACKUP_MODE="snapshot"         # Modo de backup
RETENTION_DAYS=7               # Días de retención
```

**Uso:**
```bash
chmod +x backup-vms.sh
./backup-vms.sh
```

### backup-configs.sh
Script para respaldar archivos de configuración del sistema Proxmox.

**Respaldo de:**
- `/etc/pve/` - Configuraciones de Proxmox
- `/etc/network/interfaces` - Configuración de red
- Configuraciones personalizadas

### pre-cluster-removal-backup.sh
**Propósito**: Crear backup completo ANTES de eliminar y recrear un cluster Proxmox.

**Uso**:
```bash
chmod +x pre-cluster-removal-backup.sh
./pre-cluster-removal-backup.sh
```

**Qué respalda**:
- ✅ Configuración completa del cluster (corosync.conf, estado de nodos)
- ✅ Todas las configuraciones de VMs y Contenedores
- ✅ Configuración de red (/etc/network/interfaces y bridges)
- ✅ Configuración de storage (storage.cfg)
- ✅ Usuarios, grupos, ACLs y permisos
- ✅ Configuración del firewall
- ✅ Certificados SSL
- ✅ Crontab y tareas programadas
- ✅ Información de LVM/ZFS
- ✅ Información completa del sistema

**Salida**:
- Directorio: `/root/cluster-removal-backup-TIMESTAMP/`
- Comprimido: `/root/cluster-removal-backup-TIMESTAMP.tar.gz`

**⚠️ IMPORTANTE**: 
- Este script NO respalda los DATOS de las VMs/Contenedores, solo sus configuraciones
- Debes usar `vzdump` para respaldar los datos de VMs/Contenedores
- Ejecuta este script en CADA nodo del cluster antes de eliminarlo
- Consulta `docs/cluster-recreation-guide.md` para el proceso completo

## Automatización con Cron

Para ejecutar backups automáticamente, agrega a crontab:

```bash
# Editar crontab
crontab -e

# Backup diario a las 2:00 AM
0 2 * * * /root/scripts/backup/backup-vms.sh

# Backup de configuraciones semanalmente (domingo 3:00 AM)
0 3 * * 0 /root/scripts/backup/backup-configs.sh
```

## Almacenamiento de Backups

### Local
- Directorio predeterminado: `/var/lib/vz/dump`
- Ventaja: Rápido
- Desventaja: No protege contra fallo del servidor

### Remoto (Recomendado)
Opciones para almacenamiento remoto:
1. **NFS**: Monta un share NFS y configura como storage de backup
2. **PBS** (Proxmox Backup Server): Solución especializada
3. **Rsync**: Sincroniza backups a servidor remoto
4. **Cloud**: AWS S3, Backblaze B2, etc.

## Restauración

### Restaurar VM desde Backup
```bash
# Listar backups disponibles
ls -lh /var/lib/vz/dump/

# Restaurar
qmrestore /var/lib/vz/dump/vzdump-qemu-100-*.tar.zst 100

# O desde la interfaz web: Datacenter → Storage → Backups → Restore
```

### Restaurar Contenedor
```bash
pct restore 100 /var/lib/vz/dump/vzdump-lxc-100-*.tar.zst
```

## Verificación de Backups

**IMPORTANTE**: Verifica regularmente que los backups funcionan:

1. Prueba restaurar en un entorno de prueba
2. Verifica integridad de archivos
3. Documenta el procedimiento de restauración
4. Realiza simulacros de recuperación ante desastres

## Mejores Prácticas

1. **Regla 3-2-1**: 
   - 3 copias de datos
   - 2 medios diferentes
   - 1 copia offsite

2. **Encriptación**: Considera encriptar backups sensibles

3. **Monitoreo**: Configura alertas para fallos de backup

4. **Documentación**: Mantén documentado el proceso de restauración

5. **Pruebas**: Prueba restauraciones periódicamente
