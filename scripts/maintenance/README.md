# Scripts de Mantenimiento / Maintenance Scripts

Este directorio contiene scripts para tareas de mantenimiento del servidor Proxmox.

## Scripts Disponibles

### system-maintenance.sh
Script principal de mantenimiento del sistema.

**Tareas que realiza:**
- Actualización de lista de paquetes
- Limpieza de paquetes antiguos
- Limpieza de logs antiguos
- Limpieza de caché
- Verificación de servicios críticos
- Reporte de uso de disco
- Verificación de ZFS/LVM
- Listado de VMs y contenedores

**Uso:**
```bash
chmod +x system-maintenance.sh
./system-maintenance.sh
```

## Tareas de Mantenimiento Recomendadas

### Diarias
- [ ] Verificar logs de errores
- [ ] Monitorear uso de recursos
- [ ] Verificar estado de backups

### Semanales
- [ ] Limpiar logs antiguos
- [ ] Verificar espacio en disco
- [ ] Revisar actualizaciones disponibles
- [ ] Verificar integridad de VMs críticas

### Mensuales
- [ ] Actualizar sistema (con ventana de mantenimiento)
- [ ] Revisar configuraciones
- [ ] Limpiar backups antiguos
- [ ] Auditoría de seguridad
- [ ] Verificar certificados SSL

### Trimestrales
- [ ] Prueba de restauración de backups
- [ ] Revisión de documentación
- [ ] Limpieza de VMs/contenedores no utilizados
- [ ] Revisión de políticas de seguridad

## Actualización de Proxmox

### Verificar Actualizaciones
```bash
# Ver versión actual
pveversion

# Ver actualizaciones disponibles
apt update
apt list --upgradable
```

### Actualizar Sistema
```bash
# IMPORTANTE: Siempre hacer backup antes de actualizar

# Actualizar paquetes
apt update
apt dist-upgrade

# Reiniciar si es necesario
reboot
```

### Actualizar a Nueva Versión Mayor
```bash
# Revisar documentación oficial antes de actualizar versión mayor
# https://pve.proxmox.com/wiki/Upgrade

# Ejemplo Proxmox 7 a 8:
# 1. Backup completo del sistema
# 2. Actualizar a la última versión de 7.x
# 3. Seguir guía oficial de upgrade
```

## Limpieza de Espacio

### Identificar Uso de Disco
```bash
# Ver uso general
df -h

# Ver directorios grandes
du -sh /* | sort -h

# Ver uso en almacenamiento de Proxmox
pvesm status
```

### Limpiar Espacio
```bash
# Limpiar snapshots antiguos de VMs
# (CUIDADO: Asegúrate de no necesitar los snapshots)
qm listsnapshot <vmid>
qm delsnapshot <vmid> <snapshot-name>

# Limpiar logs
journalctl --vacuum-time=7d

# Limpiar cache de apt
apt-get clean

# Limpiar backups antiguos (ajustar días según necesidad)
find /var/lib/vz/dump -type f -mtime +30 -delete
```

## Optimización de Performance

### Verificar Performance
```bash
# Test de CPU
pveperf

# Test de disco
dd if=/dev/zero of=/tmp/testfile bs=1M count=1024
rm /tmp/testfile

# I/O stats
iostat -x 1 5
```

### Ajustes Comunes
```bash
# Desactivar swap si hay suficiente RAM
swapoff -a

# Ajustar swappiness
echo "vm.swappiness=10" >> /etc/sysctl.conf
sysctl -p
```

## Seguridad

### Auditoría de Seguridad
```bash
# Revisar usuarios conectados
who

# Revisar intentos de login fallidos
lastb

# Revisar logs de autenticación
grep -i failed /var/log/auth.log

# Verificar puertos abiertos
ss -tulpn
```

### Actualizar Certificados SSL
```bash
# Generar nuevo certificado autofirmado
pvecm updatecerts

# O usar Let's Encrypt (si tienes dominio público)
pvenode acme account register default mail@example.com
pvenode acme cert order
```

## Automatización

### Crontab para Mantenimiento
```bash
# Editar crontab
crontab -e

# Mantenimiento semanal (domingo 4:00 AM)
0 4 * * 0 /root/scripts/maintenance/system-maintenance.sh

# Limpieza diaria de logs (todos los días 3:00 AM)
0 3 * * * journalctl --vacuum-time=30d
```

## Checklist de Mantenimiento

```markdown
### Pre-Mantenimiento
- [ ] Notificar a usuarios sobre ventana de mantenimiento
- [ ] Hacer backup completo
- [ ] Documentar estado actual del sistema
- [ ] Preparar plan de rollback

### Durante Mantenimiento
- [ ] Ejecutar scripts de mantenimiento
- [ ] Aplicar actualizaciones si es necesario
- [ ] Verificar logs en busca de errores
- [ ] Probar servicios críticos

### Post-Mantenimiento
- [ ] Verificar que todos los servicios están funcionando
- [ ] Revisar logs de errores
- [ ] Actualizar documentación
- [ ] Notificar finalización del mantenimiento
```

## Recursos Útiles

- [Proxmox Wiki - Maintenance](https://pve.proxmox.com/wiki/System_Software_Updates)
- [Proxmox Forum](https://forum.proxmox.com/)
- [Proxmox Bugtracker](https://bugzilla.proxmox.com/)
