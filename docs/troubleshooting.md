# Guía de Resolución de Problemas / Troubleshooting Guide

Esta guía cubre problemas comunes y sus soluciones en Proxmox.

## 🔴 Problemas Críticos

### El servidor no arranca

**Síntomas**: El servidor no arranca o se queda en pantalla de boot.

**Diagnóstico**:
1. Verificar conexión de monitor/teclado
2. Revisar mensajes de boot
3. Intentar arrancar en modo rescue

**Solución**:
```bash
# Desde modo rescue/recovery:
# 1. Montar sistema de archivos
mount /dev/pve/root /mnt
chroot /mnt

# 2. Verificar y reparar configuración de red
nano /etc/network/interfaces

# 3. Verificar fstab
nano /etc/fstab

# 4. Reconstruir initramfs si es necesario
update-initramfs -u -k all
```

### No puedo acceder a la Web UI

**Síntomas**: No se puede acceder a https://SERVER_IP:8006

**Diagnóstico**:
```bash
# 1. Verificar que el servicio está corriendo
systemctl status pveproxy

# 2. Verificar puertos abiertos
ss -tulpn | grep 8006

# 3. Verificar firewall
iptables -L -n
```

**Solución**:
```bash
# Reiniciar servicios de Proxmox
systemctl restart pveproxy
systemctl restart pvedaemon
systemctl restart pve-cluster

# Si persiste, verificar logs
tail -f /var/log/pveproxy/access.log
journalctl -u pveproxy -f
```

## ⚠️ Problemas Comunes

### VM no arranca

**Diagnóstico**:
```bash
# Ver estado de la VM
qm status <vmid>

# Ver configuración
qm config <vmid>

# Ver logs
tail -f /var/log/syslog | grep "qemu\[<vmid>\]"
```

**Soluciones**:

1. **Error de lock**:
```bash
# Eliminar lock de VM
qm unlock <vmid>
```

2. **Disco lleno**:
```bash
# Verificar espacio
df -h
pvesm status

# Limpiar espacio si es necesario
apt-get clean
find /var/lib/vz/dump -mtime +7 -delete
```

3. **Recursos insuficientes**:
```bash
# Verificar recursos del host
free -h
top
```

### Contenedor no arranca

**Diagnóstico**:
```bash
# Ver estado
pct status <ctid>

# Intentar iniciar con debug
pct start <ctid> --debug

# Ver logs
journalctl -u pve-container@<ctid> -f
```

**Soluciones**:

1. **Error de permisos**:
```bash
# Verificar y corregir permisos
pct fsck <ctid>
```

2. **AppArmor/Seccomp**:
```bash
# Desactivar temporalmente (solo para debug)
pct set <ctid> -features nesting=1
```

### Problemas de Red

**Síntoma**: VMs/Contenedores sin conectividad de red

**Diagnóstico**:
```bash
# En el host, verificar bridges
ip addr show
brctl show

# Verificar que el bridge está activo
ip link show vmbr0

# Verificar iptables
iptables -L -n -v
```

**Solución**:
```bash
# Reiniciar networking
systemctl restart networking

# O reiniciar bridge específico
ifdown vmbr0 && ifup vmbr0

# Verificar desde la VM
# (entrar a la VM y hacer ping a gateway)
```

### Alto uso de CPU/RAM

**Diagnóstico**:
```bash
# Ver procesos con mayor uso
top
htop

# Ver qué VMs/CTs usan más recursos
qm list
pct list

# Monitorear en tiempo real
watch -n 1 'qm list'
```

**Solución**:
```bash
# Detener VM/CT no necesarias
qm stop <vmid>
pct stop <ctid>

# Reducir recursos asignados
qm set <vmid> --cores 2 --memory 2048

# Identificar proceso problemático en VM
qm guest exec <vmid> -- top -b -n 1
```

### Storage lleno

**Diagnóstico**:
```bash
# Ver uso de almacenamiento
df -h
pvesm status

# Ver qué usa más espacio
du -sh /var/lib/vz/*
du -sh /var/lib/vz/images/*

# Ver snapshots de VMs
qm listsnapshot <vmid>
```

**Solución**:
```bash
# Limpiar backups antiguos
find /var/lib/vz/dump -type f -mtime +30 -delete

# Eliminar snapshots no necesarios
qm delsnapshot <vmid> <snapshot-name>

# Limpiar logs
journalctl --vacuum-time=7d

# Limpiar apt cache
apt-get clean
```

## 🔧 Problemas de Performance

### Bajo rendimiento de disco

**Diagnóstico**:
```bash
# Test de rendimiento
pveperf

# I/O stats
iostat -x 1 5

# Ver procesos con alto I/O
iotop
```

**Solución**:
- Usar discos SSD/NVMe para VMs críticas
- Habilitar writeback cache (con cuidado)
- Usar virtio drivers en VMs
- Considerar usar LVM-thin o ZFS

### Bajo rendimiento de red

**Diagnóstico**:
```bash
# Test de ancho de banda
iperf3 -s  # En el servidor
iperf3 -c SERVER_IP  # En cliente

# Ver estadísticas de interfaz
ethtool eth0
ip -s link show eth0
```

**Solución**:
- Usar virtio drivers en VMs
- Verificar que no hay errores en la interfaz
- Considerar bonding/agregación de enlaces
- Verificar MTU settings

## 🔄 Recuperación ante Desastres

### Cluster en estado degradado

```bash
# Ver estado del cluster
pvecm status

# Reiniciar servicios del cluster
systemctl restart pve-cluster
systemctl restart corosync
```

### Recuperar configuración de VM perdida

```bash
# Las configs están en /etc/pve/qemu-server/
ls -la /etc/pve/qemu-server/

# Si tienes backup de configs, restaurar
cp /backup/configs/100.conf /etc/pve/qemu-server/

# Verificar
qm config 100
```

### ZFS pool degradado

```bash
# Ver estado
zpool status

# Reemplazar disco fallido
zpool replace <pool> <old_disk> <new_disk>

# Scrub del pool
zpool scrub <pool>
```

## 📋 Comandos de Diagnóstico Útiles

### Sistema General
```bash
# Versión de Proxmox
pveversion

# Estado general
pveperf

# Logs del sistema
journalctl -f
tail -f /var/log/syslog

# Procesos
top
htop
```

### Red
```bash
# Interfaces
ip addr show
ip route show

# Conexiones activas
ss -tulpn

# Bridges
brctl show
```

### Almacenamiento
```bash
# Espacio en disco
df -h
pvesm status

# LVM
pvs
vgs
lvs

# ZFS (si aplica)
zpool list
zfs list
```

### VMs y Contenedores
```bash
# Listar todas
qm list
pct list

# Estado de servicios Proxmox
systemctl status pve*
```

## 🆘 Cuando Todo Falla

### Modo Rescue

1. Arrancar desde USB/ISO de Proxmox
2. Seleccionar "Debug Mode" o modo rescue
3. Montar sistema:
```bash
mount /dev/pve/root /mnt
mount /dev/sda2 /mnt/boot  # Ajustar según tu setup
chroot /mnt
```

### Restaurar desde Backup

```bash
# Listar backups disponibles
ls -lh /var/lib/vz/dump/

# Restaurar VM
qmrestore /var/lib/vz/dump/vzdump-qemu-*.tar.zst <vmid>

# Restaurar contenedor
pct restore <ctid> /var/lib/vz/dump/vzdump-lxc-*.tar.zst
```

## 📞 Obtener Ayuda

Si ninguna solución funciona:

1. **Foro de Proxmox**: https://forum.proxmox.com/
2. **Documentación oficial**: https://pve.proxmox.com/pve-docs/
3. **Bug Tracker**: https://bugzilla.proxmox.com/
4. **Wiki**: https://pve.proxmox.com/wiki/

### Información a Incluir al Pedir Ayuda

```bash
# Recopilar información del sistema
pveversion -v > /tmp/pve-info.txt
dmesg >> /tmp/pve-info.txt
journalctl -xe >> /tmp/pve-info.txt
```

## 📝 Registro de Problemas

Mantén un log de problemas encontrados y sus soluciones para referencia futura.

| Fecha | Problema | Solución | Tiempo de Resolución |
|-------|----------|----------|---------------------|
| - | - | - | - |
