# Configuraciones de Máquinas Virtuales / VM Configurations

Este directorio contiene las configuraciones y plantillas de máquinas virtuales.

## Estructura

Organiza las VMs por propósito o proyecto:
- `production/`: VMs de producción
- `development/`: VMs de desarrollo
- `templates/`: Plantillas de VMs reutilizables

## Archivos de Configuración de VM

Las configuraciones de VM se almacenan en `/etc/pve/qemu-server/` en el servidor Proxmox.

### Formato de Configuración

```
# VM 100 - Ejemplo
bootdisk: scsi0
cores: 2
cpu: host
memory: 4096
name: vm-ejemplo
net0: virtio=XX:XX:XX:XX:XX:XX,bridge=vmbr0
numa: 0
ostype: l26
scsi0: local-lvm:vm-100-disk-0,size=32G
scsihw: virtio-scsi-pci
smbios1: uuid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
sockets: 1
```

## Plantillas

Crear plantillas de VMs ayuda a estandarizar y acelerar el despliegue.

### Proceso para Crear Plantilla:

1. Crea una VM base con el OS instalado y configurado
2. Instala cloud-init (opcional pero recomendado)
3. Limpia la VM (logs, SSH keys, etc.)
4. Convierte a plantilla: `qm template <vmid>`

## Mejores Prácticas

1. **Nomenclatura**: Usa nombres descriptivos (ej: web-server-01, db-master)
2. **Documentación**: Documenta el propósito de cada VM
3. **Recursos**: Asigna recursos según necesidad real
4. **Cloud-init**: Usa cloud-init para configuración automática
5. **Snapshots**: Haz snapshots antes de cambios importantes

## Comandos Útiles

```bash
# Listar VMs
qm list

# Ver configuración de VM
qm config <vmid>

# Crear snapshot
qm snapshot <vmid> <snapshot-name>

# Iniciar/Detener VM
qm start <vmid>
qm stop <vmid>

# Clonar VM
qm clone <vmid> <newid> --name <nuevo-nombre>
```

## Documentación de VMs

Mantén un inventario de tus VMs en `inventory.md` con:
- ID de VM
- Nombre
- Propósito
- Especificaciones
- IP asignada
- Notas adicionales
