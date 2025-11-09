# Configuraciones de Almacenamiento / Storage Configurations

Este directorio contiene las configuraciones de almacenamiento del servidor Proxmox.

## Tipos de Almacenamiento Soportados

- **Local**: Almacenamiento local del servidor
- **LVM**: Logical Volume Manager
- **NFS**: Network File System
- **iSCSI**: Internet Small Computer Systems Interface
- **Ceph**: Almacenamiento distribuido
- **ZFS**: Sistema de archivos avanzado

## Archivos de Configuración

### storage.cfg
Archivo principal de configuración de almacenamiento de Proxmox.

### nfs-mounts.conf
Puntos de montaje NFS (si aplica).

### iscsi-targets.conf
Configuración de targets iSCSI (si aplica).

## Ejemplo de Configuración

```
# Almacenamiento local
dir: local
    path /var/lib/vz
    content iso,vztmpl,backup

# LVM
lvmthin: local-lvm
    thinpool data
    vgname pve
    content rootdir,images

# NFS (ejemplo)
nfs: nfs-backup
    server 192.168.1.100
    export /mnt/backup
    content backup
```

## Mejores Prácticas

1. **Backups**: Mantén al menos un storage dedicado para backups
2. **Separación**: Separa datos de sistema, VMs y backups cuando sea posible
3. **Monitoreo**: Configura alertas para espacio en disco
4. **Performance**: Usa almacenamiento rápido (SSD/NVMe) para VMs críticas

## Comandos Útiles

```bash
# Listar almacenamiento configurado
pvesm status

# Ver detalles de un storage
pvesm list <storage-name>

# Agregar almacenamiento NFS
pvesm add nfs <storage-id> --server <ip> --export <path>

# Eliminar almacenamiento
pvesm remove <storage-id>
```
